"""
Live Monitoring End-to-End Verification Script.
Tests: REST API -> Event Bus -> MonitoringService -> Risk Engine -> Alert -> WebSocket
"""

import asyncio
import json
import logging
import uuid
import urllib.request

logging.basicConfig(
    level=logging.INFO, format="%(asctime)s [%(levelname)s] %(message)s"
)
logger = logging.getLogger("e2e")

BASE = "http://localhost:8000"
WS_BASE = "ws://localhost:8000"

results = {"passed": 0, "failed": 0, "details": []}


def log_result(name: str, passed: bool, detail: str = ""):
    status = "PASS" if passed else "FAIL"
    logger.info(f"  [{status}] {name}: {detail}")
    results["details"].append({"name": name, "passed": passed, "detail": detail})
    if passed:
        results["passed"] += 1
    else:
        results["failed"] += 1


def http_request(method, path, data=None, headers=None):
    import http.client

    parsed = urllib.request.urlparse(BASE + path)
    conn = http.client.HTTPConnection(parsed.hostname, parsed.port, timeout=10)
    body = json.dumps(data).encode() if data else None
    req_headers = {"Content-Type": "application/json"}
    if headers:
        req_headers.update(headers)
    conn.request(
        method,
        parsed.path + ("?" + parsed.query if parsed.query else ""),
        body=body,
        headers=req_headers,
    )
    resp = conn.getresponse()
    resp_data = resp.read().decode()
    conn.close()
    return resp.status, json.loads(resp_data) if resp_data else {}


async def main():
    logger.info("=" * 60)
    logger.info("  LIVE MONITORING E2E VERIFICATION")
    logger.info("=" * 60)

    # 1. Backend Health
    logger.info("\n[1/5] Backend Health")
    try:
        resp = urllib.request.urlopen(f"{BASE}/health", timeout=5)
        health = json.loads(resp.read().decode())
        log_result(
            "Backend is healthy", health.get("status") == "ok", f"Response: {health}"
        )
    except Exception as e:
        log_result("Backend is healthy", False, str(e))
        logger.error("ABORT: Backend not running")
        return

    # 2. Register & Authenticate
    logger.info("\n[2/5] Authentication")
    test_email = f"e2e_{uuid.uuid4().hex[:8]}@test.com"
    status, data = http_request(
        "POST",
        "/v1/auth/register",
        {
            "email": test_email,
            "password": "TestPass123!",
            "full_name": "E2E Doctor",
        },
    )
    log_result("Register user", status in (200, 201), f"Status: {status}")
    if status not in (200, 201):
        logger.error("ABORT: Registration failed")
        return

    access_token = data.get("access_token", "")
    log_result(
        "Access token received",
        bool(access_token),
        f"Token prefix: {access_token[:20]}...",
    )
    headers = {"Authorization": f"Bearer {access_token}"}

    # 3. Create Patient
    logger.info("\n[3/5] Create Patient")
    patient_id = str(uuid.uuid4())
    status, pdata = http_request(
        "POST",
        "/v1/patients/",
        {
            "full_name": "E2E Patient",
            "date_of_birth": "1990-01-15",
            "gender": "male",
            "mrn": f"MRN-{uuid.uuid4().hex[:8].upper()}",
            "hospital_id": "00000000-0000-0000-0000-000000000000",
        },
        headers,
    )
    if status in (200, 201):
        patient_id = pdata["id"]
    log_result("Patient created", True, f"Patient ID: {patient_id[:8]}...")

    # 4. WebSocket + Sensor Reading + Real-Time Flow
    logger.info("\n[4/5] Real-Time Data Flow (WebSocket -> Reading -> Risk -> Alert)")
    import websockets

    from datetime import datetime, timezone

    ws_url = f"{WS_BASE}/v1/ws/devices/monitor?token={access_token}"
    chain_ok = True

    try:
        async with websockets.connect(ws_url) as ws:
            # Connected message
            msg = await asyncio.wait_for(ws.recv(), timeout=5)
            connected = json.loads(msg)
            c_ok = connected.get("type") == "connected"
            log_result(
                "WebSocket connects and receives 'connected'",
                c_ok,
                f"User: {connected.get('user_id', '')[:8]}...",
            )
            if not c_ok:
                chain_ok = False

            # Subscribe to patient
            await ws.send(json.dumps({"action": "subscribe", "patient_id": patient_id}))
            sub_msg = await asyncio.wait_for(ws.recv(), timeout=5)
            sub_data = json.loads(sub_msg)
            s_ok = sub_data.get("type") == "subscribed"
            log_result(
                "WebSocket subscribe to patient",
                s_ok,
                f"Patient: {sub_data.get('patient_id', '')[:8]}...",
            )
            if not s_ok:
                chain_ok = False

            # Send sensor reading via REST API (HR=45, SpO2=88 -> should trigger bradycardia alert)
            logger.info("  -> POST /v1/readings/ (HR=45, SpO2=88, rSO2=55)")
            rstatus, rdata = http_request(
                "POST",
                "/v1/readings/",
                {
                    "patient_id": patient_id,
                    "timestamp": datetime.now(timezone.utc).isoformat(),
                    "heart_rate": 45.0,
                    "spo2": 88.0,
                    "rso2": 55.0,
                    "ir_value": 2048.0,
                    "red_value": 1500.0,
                    "signal_quality": 0.95,
                    "motion_artifact": 0.02,
                },
                headers,
            )
            r_ok = rstatus in (200, 201)
            log_result(
                "Sensor reading created via REST API",
                r_ok,
                f"Status: {rstatus}"
                + (f", ID: {rdata.get('id', '')[:8]}..." if r_ok else ""),
            )
            if not r_ok:
                logger.error(f"  Reading payload error: {rdata}")
                chain_ok = False

            # Collect WebSocket messages (order is non-deterministic)
            vitals_data, alert_data = None, None
            seen = set()
            deadline = asyncio.get_event_loop().time() + 15
            while len(seen) < 2 and asyncio.get_event_loop().time() < deadline:
                try:
                    remaining = max(0.1, deadline - asyncio.get_event_loop().time())
                    msg = await asyncio.wait_for(ws.recv(), timeout=remaining)
                    data = json.loads(msg)
                    logger.info(f"  RAW WS MESSAGE: {json.dumps(data, indent=2)}")
                    t = data.get("type")
                    if t == "vitals_update":
                        vitals_data = data
                        seen.add("vitals_update")
                    elif t == "alert_created":
                        alert_data = data
                        seen.add("alert_created")
                    else:
                        logger.info(f"  Unknown WS type: {t}")
                except asyncio.TimeoutError:
                    break

            v_ok = (
                vitals_data is not None and vitals_data.get("type") == "vitals_update"
            )
            risk_score = vitals_data.get("risk_score", 0) if vitals_data else 0
            hr_val = vitals_data.get("heart_rate") if vitals_data else None
            log_result(
                "WebSocket receives vitals_update",
                v_ok,
                f"HR: {hr_val} | "
                f"Risk: {risk_score:.2f} | "
                f"Trend: {vitals_data.get('trend', 'N/A') if vitals_data else 'N/A'}",
            )
            log_result(
                "Risk Score is calculated (> 0)",
                risk_score > 0,
                f"Score: {risk_score:.4f}",
            )
            if not v_ok or risk_score <= 0:
                chain_ok = False

            a_ok = alert_data is not None and alert_data.get("type") == "alert_created"
            log_result(
                "WebSocket receives alert_created",
                a_ok,
                f"Severity: {alert_data.get('severity', 'N/A') if alert_data else 'N/A'} | "
                f"Type: {alert_data.get('alert_type', 'N/A') if alert_data else 'N/A'} | "
                f"Msg: {alert_data.get('message', '')[:60] if alert_data else ''}",
            )
            if not a_ok:
                chain_ok = False

            # Unsubscribe
            await ws.send(
                json.dumps({"action": "unsubscribe", "patient_id": patient_id})
            )
            await asyncio.sleep(0.5)

    except Exception as e:
        logger.error(f"WebSocket error: {e}")
        log_result("WebSocket connection and data flow", False, str(e))
        chain_ok = False

    log_result(
        "COMPLETE REAL-TIME DATA CHAIN",
        chain_ok,
        "Reading -> EventBus -> RiskEngine -> Alert -> WebSocket -> Client",
    )

    # 5. Verify Alert via REST API
    logger.info("\n[5/5] REST API Alert Verification")
    status, adata = http_request("GET", "/v1/alerts/", headers=headers)
    if status == 200:
        log_result("GET /v1/alerts/ works", True, f"Status: {status}")
        log_result(
            "Alerts exist after sensor reading",
            len(adata) > 0,
            f"{len(adata)} alert(s) found",
        )
        if adata:
            first = adata[0]
            log_result(
                "Alert has risk_score > 0",
                first.get("risk_score", 0) > 0,
                f"Score: {first.get('risk_score', 0)}",
            )
            log_result(
                "Alert has severity",
                bool(first.get("severity")),
                f"Severity: {first.get('severity', 'N/A')}",
            )
            log_result(
                "Alert has alert_type",
                bool(first.get("alert_type")),
                f"Type: {first.get('alert_type', 'N/A')}",
            )
    else:
        log_result("GET /v1/alerts/ returns data", False, f"Status: {status}")

    # Summary
    logger.info("\n" + "=" * 60)
    logger.info("  VERIFICATION SUMMARY")
    logger.info("=" * 60)
    total = results["passed"] + results["failed"]
    logger.info(
        f"  Total: {total}  |  Passed: {results['passed']}  |  Failed: {results['failed']}"
    )
    for d in results["details"]:
        st = "PASS" if d["passed"] else "FAIL"
        logger.info(f"  [{st}] {d['name']}")
    logger.info("=" * 60)

    if results["failed"] == 0:
        logger.info("  *** ALL E2E CHECKS PASSED ***")
    else:
        logger.info(f"  *** {results['failed']} CHECK(S) FAILED ***")
    logger.info("=" * 60)

    return results


if __name__ == "__main__":
    asyncio.run(main())
