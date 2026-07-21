# Message Queue Architecture

> Redis Streams Architecture

---

## Technology Selection: Redis Streams

### Comparison

| Criteria | Redis Streams ✅ | RabbitMQ | Apache Kafka |
|----------|----------------|----------|--------------|
| **Latency** | <1ms | <5ms | <10ms |
| **Throughput** | 1M+ msg/s | 50K msg/s | 2M+ msg/s |
| **Persistence** | RDB/AOF append-only | Disk (queue) | Disk (log) |
| **Memory Usage** | RAM (configurable) | Variable | Disk-heavy |
| **Operational Complexity** | Low (single binary) | Medium | High (ZooKeeper/KRaft) |
| **Consumer Groups** | ✅ (Native) | ✅ | ✅ |
| **Pub/Sub** | ✅ | ✅ | ✅ |
| **Exactly-Once** | ⚠️ (at-least-once) | ⚠️ | ✅ |
| **Message Retention** | Configurable (maxlen) | Configurable (TTL) | Configurable (retention.ms) |
| **Dead Letter Queue** | ⚠️ (manual) | ✅ (built-in) | ✅ 
| **Existing Infrastructure** | ✅ (Already in docker-compose) | ❌ (New service) | ❌ (New service + ZK) |

**Decision: Redis Streams** ✅

Rationale:
1. **Already in stack** — Redis is already specified in requirements (caching)
2. **Lowest latency** — Critical for real-time medical alerts
3. **Simple operations** — Single binary, no clustering needed initially
4. **Sufficient throughput** — 1M msg/s far exceeds our needs (~5K msg/s peak)
5. **Flexible** — Can use same instance for cache + streams + pub/sub

---

## Architecture

```
┌────────────────────────────────────────────────────────────────────────────┐
│                            REDIS STREAMS                                    │
│                                                                             │
│  Stream: telemetry:raw          (Sensor readings from devices)              │
│  Stream: telemetry:processed    (AI-processed assessments)                 │
│  Stream: alerts                 (Alert events)                              │
│  Stream: notifications          (Push notification events)                 │
│  Stream: ota_commands           (OTA firmware commands to devices)          │
│  Stream: audit_logs             (System audit events)                       │
│                                                                             │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │                         CONSUMER GROUPS                              │   │
│  │                                                                      │   │
│  │  telemetry:raw → Group: ingest                                       │   │
│  │    ├── Consumer: storage-writer-1   (writes to PostgreSQL)           │   │
│  │    ├── Consumer: storage-writer-2   (writes to PostgreSQL)           │   │
│  │    ├── Consumer: risk-engine-1      (AI risk assessment)             │   │
│  │    └── Consumer: risk-engine-2      (AI risk assessment)             │   │
│  │                                                                      │   │
│  │  telemetry:processed → Group: distribution                          │   │
│  │    ├── Consumer: websocket-pusher   (pushes to connected clients)    │   │
│  │    └── Consumer: trend-analyzer     (long-term trend analysis)       │   │
│  │                                                                      │   │
│  │  alerts → Group: notification                                       │   │
│  │    ├── Consumer: websocket-pusher   (WebSocket push notifications) │   │
│  │    ├── Consumer: twilio-sms         (Emergency SMS via Twilio)       │   │
│  │    └── Consumer: email-sender       (Email alerts)                   │   │
│  │                                                                      │   │
│  │  notifications → Group: delivery                                    │   │
│  │    └── Consumer: delivery-tracker   (Tracks delivery status)         │   │
│  │                                                                      │   │
│  │  ota_commands → Group: device_mgmt                                  │   │
│  │    └── Consumer: ota-dispatcher     (Dispatches OTA to devices)      │   │
│  │                                                                      │   │
│  │  audit_logs → Group: compliance                                     │   │
│  │    └── Consumer: audit-writer       (Writes to audit_logs table)    │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
└────────────────────────────────────────────────────────────────────────────┘
```

---

## Message Schemas

### Telemetry Reading

```json
{
  "stream": "telemetry:raw",
  "id": "1724188020000-0",
  "fields": {
    "device_id": "NB-001-ABCD",
    "patient_id": "550e8400-e29b-41d4-a716-446655440000",
    "recorded_at": "2026-07-14T16:30:00Z",
    "heart_rate": 72.5,
    "spo2": 98.2,
    "systolic_bp": 128,
    "diastolic_bp": 82,
    "rso2": 68.1,
    "ir_value": 45231.5,
    "red_value": 28123.7,
    "signal_quality": 0.92,
    "motion_artifact": 0.08,
    "edge_risk_score": 0.15,
    "edge_risk_level": "low",
    "battery_level": 87.0,
    "firmware_version": "0.1.0"
  }
}
```

### Alert Event

```json
{
  "stream": "alerts",
  "id": "1724188050000-0",
  "fields": {
    "alert_id": "660e8400-e29b-41d4-a716-446655440001",
    "patient_id": "550e8400-e29b-41d4-a716-446655440000",
    "device_id": "NB-001-ABCD",
    "alert_type": "ICH_SUSPECTED",
    "severity": "critical",
    "risk_score": 0.89,
    "message": "مشتبه بنزيف دماغي — انخفاض rSO2 بنسبة 18% في 5 دقائق",
    "triggered_at": "2026-07-14T16:31:00Z",
    "triggered_by": "cloud_ai",
    "patient_vitals": {
      "heart_rate": 112,
      "spo2": 88,
      "rso2": 52,
      "systolic_bp": 168
    },
    "ai_analysis": {
      "model_version": "NB-RISK-2.1.0",
      "confidence": 0.94,
      "contributing_factors": ["hypoxia", "tachycardia", "rso2_drop"]
    }
  }
}
```

### OTA Command

```json
{
  "stream": "ota_commands",
  "id": "1724188100000-0",
  "fields": {
    "command_id": "770e8400-e29b-41d4-a716-446655440002",
    "device_id": "NB-001-ABCD",
    "command_type": "firmware_update",
    "firmware_version": "0.2.0",
    "download_url": "https://storage.neurobleed.com/firmware/nb-01-v0.2.0.bin",
    "checksum_sha256": "a1b2c3d4e5f6...",
    "file_size": 1048576,
    "scheduled_at": "2026-07-14T17:00:00Z",
    "rollback_version": "0.1.0"
  }
}
```

---

## Implementation in FastAPI

```python
# app/core/streams.py

import json
from typing import Any
from redis.asyncio import Redis
from app.config import settings

redis = Redis.from_url(settings.REDIS_URL, decode_responses=True)

STREAMS = {
    "telemetry:raw": {"maxlen": 100000},
    "telemetry:processed": {"maxlen": 50000},
    "alerts": {"maxlen": 10000},
    "notifications": {"maxlen": 10000},
    "ota_commands": {"maxlen": 1000},
    "audit_logs": {"maxlen": 100000},
}

async def init_streams():
    for stream, config in STREAMS.items():
        await redis.xadd(stream, {"_init": "1"}, maxlen=config["maxlen"])
        await redis.delete(stream)  # Remove init marker
        # Create consumer groups
        for group in CONSUMER_GROUPS.get(stream, []):
            try:
                await redis.xgroup_create(stream, group, id="0", mkstream=True)
            except Exception:
                pass  # Group already exists

async def publish(stream: str, data: dict[str, Any]) -> str:
    return await redis.xadd(stream, data, maxlen=STREAMS[stream]["maxlen"])

async def consume(stream: str, group: str, consumer: str, count: int = 10):
    messages = await redis.xreadgroup(group, consumer, {stream: ">"}, count=count)
    return messages

async def acknowledge(stream: str, group: str, message_id: str):
    await redis.xack(stream, group, message_id)
```

```python
# app/services/alert_dispatcher.py

class AlertDispatcher:
    def __init__(self):
        self.redis = redis

    async def process_alerts(self):
        """Consumer: alert → notification dispatcher"""
        while True:
            messages = await consume("alerts", "notification", "alert-dispatcher-1")
            for stream_name, entries in messages:
                for msg_id, fields in entries:
                    try:
                        alert = AlertEvent(**fields)
                        
                        # Dispatch based on severity
                        if alert.severity == "critical":
                            await self._dispatch_critical(alert)
                        elif alert.severity == "high":
                            await self._dispatch_high(alert)
                        else:
                            await self._dispatch_normal(alert)
                        
                        await acknowledge("alerts", "notification", msg_id)
                    except Exception as e:
                        logger.error(f"Failed to process alert {msg_id}: {e}")

    async def _dispatch_critical(self, alert: AlertEvent):
        # Parallel dispatch
        await asyncio.gather(
            websocket_broadcast(alert),          # Push via WebSocket
            twilio_send_emergency_sms(alert),    # SMS emergency
            websocket_broadcast(alert),          # Dashboard real-time
            store_alert(alert),                  # Database
            publish("audit_logs", alert.dict()), # Audit trail
        )
```

---

## Message Flow for Critical Alert

```
Device sends reading (MQTT/TLS)
        │
    FastAPI /v1/readings endpoint
        │
    XADD telemetry:raw {reading_data}
        │
    ┌─── Consumer: risk-engine-1
    │   Reads from telemetry:raw
    │   AI Risk Assessment
    │   ├── Risk score: 0.89 (critical)
    │   └── XADD telemetry:processed {result}
    │       └── XADD alerts {alert_event}
    │
    ┌─── Consumer: storage-writer-1
    │   Reads from telemetry:raw
    │   Batch INSERT to PostgreSQL
    │
    ┌─── Consumer: alert-dispatcher
    │   Reads from alerts
    │   ├── WebSocket Push → Doctor's Phone (within 1s)
    │   ├── SMS Emergency → Emergency Contact (within 5s)
    │   ├── WebSocket → Dashboard Real-Time (within 500ms)
    │   └── Store → PostgreSQL (within 100ms)
    │
    ┌─── Consumer: audit-writer
    │   Reads from audit_logs
    │   Writes audit record (HIPAA compliance)
    │
    ┌─── Consumer: websocket-pusher
        Reads from telemetry:processed
        Pushes to subscribed WebSocket clients
```

---

## Failure Handling

| Failure Mode | Impact | Mitigation |
|-------------|--------|------------|
| Redis down | No real-time processing | Fallback to direct API calls |
| Consumer crash | Delayed processing | Auto-restart (Docker), pending messages persist in stream |
| Stream full (maxlen) | Oldest messages dropped | Configure maxlen for each stream based on importance |
| Network partition | Messages queued on device | Device buffers up to 10MB of data |
| Double processing | Duplicate alerts | Idempotency keys (alert_id, reading_id) |

**Recovery**: All consumers are stateless — on restart, they resume from last acknowledged message.
