# Observability & Monitoring

> Observability & Monitoring — Complete

---

## Monitoring Architecture

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                          OBSERVABILITY STACK                                 │
│                                                                              │
│                        ┌──────────────────┐                                  │
│                        │    GRAFANA       │  Dashboards & Alerting          │
│                        │  (Port 3000)     │                                  │
│                        └────────┬─────────┘                                  │
│                                 │                                            │
│           ┌─────────────────────┼─────────────────────┐                      │
│           │                     │                     │                      │
│    ┌──────┴──────┐      ┌──────┴──────┐      ┌───────┴───────┐              │
│    │ PROMETHEUS  │      │   LOKI      │      │   TEMPO      │              │
│    │ (Metrics)   │      │  (Logs)     │      │  (Traces)    │              │
│    │ Port 9090   │      │  Port 3100  │      │  Port 4317   │              │
│    └──────┬──────┘      └──────┬──────┘      └───────┬───────┘              │
│           │                     │                     │                      │
│    ┌──────┴──────┐      ┌──────┴──────┐      ┌───────┴───────┐              │
│    │  EXPORTERS  │      │  LOG AGENTS │      │  TRACE SDKs   │              │
│    │             │      │             │      │               │              │
│    │ FastAPI     │      │ Filebeat    │      │ OpenTelemetry │              │
│    │ Redis       │      │ (container) │      │ (Python SDK)  │              │
│    │ PostgreSQL  │      │             │      │ (Dart SDK)    │              │
│    │ Node/System │      │             │      │ (ESP32 via    │              │
│    │ Device MQTT │      │             │      │  MQTT)        │              │
│    └─────────────┘      └─────────────┘      └───────────────┘              │
│                                                                              │
│  ┌──────────────────────────────────────────────────────────────────────┐   │
│  │                        SENTRY (Error Tracking)                       │   │
│  │  Mobile Crash Reporting + Backend Error Tracking + Performance       │   │
│  └──────────────────────────────────────────────────────────────────────┘   │
│                                                                              │
│  ┌──────────────────────────────────────────────────────────────────────┐   │
│  │                    HEALTH CHECKS & ALERTS                             │   │
│  │  Uptime Kuma / Better Uptime → PagerDuty / Slack / Telegram         │   │
│  └──────────────────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## 1. Metrics (Prometheus)

### Backend Metrics

```python
# app/core/metrics.py

from prometheus_client import Counter, Histogram, Gauge, generate_latest
from fastapi import Request, Response
import time

# HTTP Request Metrics
http_requests_total = Counter(
    'nb_http_requests_total',
    'Total HTTP requests',
    ['method', 'endpoint', 'status']
)

http_request_duration = Histogram(
    'nb_http_request_duration_seconds',
    'HTTP request duration',
    ['method', 'endpoint'],
    buckets=(.005, .01, .025, .05, .075, .1, .25, .5, .75, 1.0, 2.5, 5.0, 10.0)
)

# Business Metrics
active_patients = Gauge('nb_active_patients', 'Number of active patients')
active_devices = Gauge('nb_active_devices', 'Number of connected devices')
unacknowledged_alerts = Gauge('nb_unacknowledged_alerts', 'Unacknowledged alerts count')

risk_assessments_total = Counter(
    'nb_risk_assessments_total',
    'Total AI risk assessments',
    ['risk_level', 'source']  # source: edge or cloud
)

risk_assessment_duration = Histogram(
    'nb_risk_assessment_duration_seconds',
    'AI risk assessment latency',
    buckets=(.01, .025, .05, .1, .25, .5, 1.0)
)

# Device Metrics
device_signal_quality = Gauge(
    'nb_device_signal_quality',
    'Device signal quality',
    ['device_id']
)
device_battery_level = Gauge(
    'nb_device_battery_level',
    'Device battery level',
    ['device_id']
)

# Message Queue Metrics
mq_messages_published = Counter(
    'nb_mq_messages_published_total',
    'Messages published to Redis Streams',
    ['stream']
)
mq_consumer_lag = Gauge(
    'nb_mq_consumer_lag',
    'Redis Stream consumer lag',
    ['stream', 'consumer_group']
)

# Database Metrics
db_query_duration = Histogram(
    'nb_db_query_duration_seconds',
    'Database query duration',
    ['query_type'],
    buckets=(.001, .005, .01, .025, .05, .1, .25, .5, 1.0)
)
db_connection_pool_size = Gauge('nb_db_connection_pool_size', 'Active DB connections')
```

### Prometheus Configuration

```yaml
# prometheus/prometheus.yml
global:
  scrape_interval: 15s
  evaluation_interval: 15s

scrape_configs:
  - job_name: 'fastapi'
    static_configs:
      - targets: ['backend:8000']
    metrics_path: '/metrics'

  - job_name: 'redis'
    static_configs:
      - targets: ['redis-exporter:9121']

  - job_name: 'postgres'
    static_configs:
      - targets: ['postgres-exporter:9187']

  - job_name: 'node'
    static_configs:
      - targets: ['node-exporter:9100']

  - job_name: 'ai-service'
    static_configs:
      - targets: ['ai-gateway:8001']
```

---

## 2. Logging (Loki)

### Log Levels

```python
# app/core/logging.py
import structlog

structlog.configure(
    processors=[
        structlog.contextvars.merge_contextvars,
        structlog.stdlib.add_log_level,
        structlog.stdlib.PositionalArgumentsFormatter(),
        structlog.processors.TimeStamper(fmt="iso"),
        structlog.processors.StackInfoRenderer(),
        structlog.processors.format_exc_info,
        structlog.processors.UnicodeDecoder(),
        structlog.dev.ConsoleRenderer() if settings.ENVIRONMENT == "development"
        else structlog.processors.JSONRenderer(),
    ],
    context_class=dict,
    logger_factory=structlog.stdlib.LoggerFactory(),
    cache_logger_on_first_use=True,
)

logger = structlog.get_logger()
```

### Audit Logs (HIPAA Compliance)

```python
# All medical data access is logged
async def log_audit(
    user_id: UUID,
    action: str,
    resource: str,
    resource_id: str | None = None,
    details: dict | None = None,
    request: Request | None = None,
):
    audit_entry = {
        "user_id": str(user_id),
        "action": action,
        "resource": resource,
        "resource_id": resource_id,
        "details": json.dumps(details) if details else None,
        "ip_address": request.client.host if request else None,
        "user_agent": request.headers.get("user-agent") if request else None,
    }
    
    # Write to PostgreSQL audit_logs table
    await db.execute(insert(AuditLog).values(**audit_entry))
    
    # Also publish to Redis Stream for real-time monitoring
    await publish("audit_logs", audit_entry)
```

### Log Categories

| Category | Examples | Retention | Storage |
|----------|---------|-----------|---------|
| Medical Data | Patient access, reading queries | 7 years | PostgreSQL |
| Security Events | Login, logout, permission denied | 7 years | PostgreSQL |
| System Events | Startup, shutdown, errors | 30 days | Loki | 
| Device Telemetry | Connection, disconnection, errors | 90 days | Loki |
| AI Inferences | Risk scores, LLM queries | 1 year | PostgreSQL |
| Audit Trail | All data modifications | 7 years | PostgreSQL |

---

## 3. Tracing (OpenTelemetry)

```python
# app/core/tracing.py
from opentelemetry import trace
from opentelemetry.exporter.otlp.proto.grpc.trace_exporter import OTLPSpanExporter
from opentelemetry.instrumentation.fastapi import FastAPIInstrumentor
from opentelemetry.instrumentation.sqlalchemy import SQLAlchemyInstrumentor
from opentelemetry.sdk.trace import TracerProvider
from opentelemetry.sdk.trace.export import BatchSpanProcessor

def setup_tracing(app: FastAPI):
    provider = TracerProvider()
    processor = BatchSpanProcessor(OTLPSpanExporter(endpoint="http://tempo:4317"))
    provider.add_span_processor(processor)
    trace.set_tracer_provider(provider)

    FastAPIInstrumentor.instrument_app(app)
    SQLAlchemyInstrumentor().instrument()
```

**Trace Example: Risk Assessment Request**

```
┌──────────┐    ┌──────────┐    ┌──────────┐    ┌──────────┐    ┌──────────┐
│ HTTP Req │    │ Auth     │    │ AI Risk  │    │ Database │    │ Response │
│ (POST /  │───→│ Verify   │───→│ Engine   │───→│ Write    │───→│ Send     │
│ v1/risk) │    │ (5ms)    │    │ (45ms)   │    │ (15ms)   │    │ (2ms)    │
└──────────┘    └──────────┘    └──────────┘    └──────────┘    └──────────┘
                                    │
                                    ├── Feature Extraction (15ms)
                                    ├── Model Inference (20ms)
                                    └── Rules Engine (10ms)

Total: ~67ms   Span ID: abc123   Trace ID: def456
```

---

## 4. Error Tracking (Sentry)

```python
# app/core/errors.py
import sentry_sdk
from sentry_sdk.integrations.fastapi import FastApiIntegration
from sentry_sdk.integrations.sqlalchemy import SqlalchemyIntegration

def setup_sentry():
    sentry_sdk.init(
        dsn=settings.SENTRY_DSN,
        integrations=[
            FastApiIntegration(),
            SqlalchemyIntegration(),
        ],
        traces_sample_rate=0.1,  # 10% of requests for performance tracing
        environment=settings.ENVIRONMENT,
        release=f"neurobleed-backend@{__version__}",
    )
```

**Error Categorization**:
| Severity | Examples | Action |
|----------|---------|--------|
| Fatal | Database connection lost, Redis down | Sentry alert + Slack/PagerDuty |
| Error | API validation failure, AI timeout | Sentry issue |
| Warning | Rate limit approaching, high memory | Grafana alert |
| Info | User login, device pairing | Loki log |

---

## 5. Health Checks

```python
# app/api/v1/health.py

@router.get("/health/live")
async def liveness():
    return {"status": "alive", "timestamp": datetime.now(timezone.utc).isoformat()}

@router.get("/health/ready")
async def readiness(db: AsyncSession = Depends(get_db)):
    checks = {
        "database": await check_database(db),
        "redis": await check_redis(),
        "ai_service": await check_ai_service(),
        "mqtt_broker": await check_mqtt(),
    }
    all_healthy = all(check["status"] == "healthy" for check in checks.values())
    status_code = 200 if all_healthy else 503
    return JSONResponse(
        status_code=status_code,
        content={"status": "healthy" if all_healthy else "degraded", "checks": checks}
    )

@router.get("/health/metrics")
async def metrics():
    return Response(content=generate_latest(), media_type="text/plain")
```

---

## 6. Grafana Dashboards

### Dashboard 1: System Overview
```
Panel: CPU Usage              (Time series)
Panel: Memory Usage           (Time series)  
Panel: HTTP Request Rate      (Time series + Rate)
Panel: HTTP P99 Latency       (Heatmap)
Panel: Active Patients        (Stat)
Panel: Connected Devices      (Stat)
Panel: Alert Rate             (Time series)
Panel: AI Assessment Latency  (Time series)
```

### Dashboard 2: Medical Operations
```
Panel: Risk Score Distribution    (Histogram)
Panel: Alert Severity Breakdown   (Pie chart)
Panel: Alert Response Time        (Time series)
Panel: Active vs Acknowledged     (Stat)
Panel: Device Signal Quality      (Table + Gauge)
Panel: Device Battery Levels      (Table + Bar)
Panel: Real-Time Patient Vitals   (Table - auto-refresh)
```

### Dashboard 3: AI Performance
```
Panel: AI Inference Latency       (Time series - P50, P95, P99)
Panel: Risk Score Calibration     (Scatter plot)
Panel: Edge vs Cloud Assessments  (Stacked bar)
Panel: Model Version Distribution (Pie chart)
Panel: Feature Importance         (Bar chart)
```

### Dashboard 4: Device Health
```
Panel: Online/Offline Devices    (Stat)
Panel: Firmware Version Dist.    (Pie chart)
Panel: Last Seen Distribution    (Histogram)
Panel: Signal Quality Gauge      (Per-device)
Panel: Battery Level Trend       (Time series)
Panel: Data Rate (bytes/min)     (Time series)
```

---

## 7. Alerting Rules

```yaml
# prometheus/alerts.yml
groups:
  - name: neurobleed_alerts
    rules:
      - alert: HighErrorRate
        expr: rate(nb_http_requests_total{status=~"5.."}[5m]) > 0.05
        for: 5m
        labels: { severity: critical }
        annotations:
          summary: "HTTP 5xx error rate > 5%"

      - alert: HighAlertLatency
        expr: histogram_quantile(0.99, nb_alert_process_duration_seconds) > 10
        for: 2m
        labels: { severity: warning }
        annotations:
          summary: "Alert processing P99 latency > 10s"

      - alert: DeviceDisconnected
        expr: time() - nb_device_last_seen > 300
        for: 1m
        labels: { severity: warning }
        annotations:
          summary: "Device {{ $labels.device_id }} disconnected for 5+ minutes"

      - alert: DatabaseConnectionPoolExhausted
        expr: nb_db_connection_pool_size > 50
        for: 1m
        labels: { severity: critical }
```

---

## Technology Stack

| Tool | Purpose | Deployment |
|------|---------|------------|
| **Prometheus** | Metrics collection & alerting | Docker container |
| **Grafana** | Visualization dashboards | Docker container |
| **Loki** | Log aggregation | Docker container |
| **Tempo** | Distributed tracing | Docker container |
| **Sentry** | Error & crash reporting | SaaS + self-hosted fallback |
| **Uptime Kuma** | External health monitoring | Docker container |
| **Promtail** | Log shipping to Loki | Sidecar container |
| **OpenTelemetry** | Tracing instrumentation | SDK in all services |
