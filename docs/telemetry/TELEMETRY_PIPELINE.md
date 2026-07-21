# Telemetry Pipeline

> Telemetry Pipeline — Complete

---

## End-to-End Data Flow

```
┌────────────────────────────────────────────────────────────────────────────────────┐
│                              TELEMETRY PIPELINE                                     │
│                                                                                    │
│  ╔══════════╗    ╔══════════╗    ╔══════════╗    ╔══════════╗    ╔══════════╗      │
│  ║  SENSORS ║    ║   ESP32  ║    ║ GATEWAY  ║    ║ MESSAGE  ║    ║   AI     ║      │
│  ║  (Body)  ║───→║  (Wear)  ║───→║  (Local) ║───→║   QUEUE  ║───→║ SERVICE  ║      │
│  ╚══════════╝    ╚══════════╝    ╚══════════╝    ╚══════════╝    ╚══════════╝      │
│       │               │               │               │               │            │
│  ┌────┴────┐     ┌────┴────┐     ┌────┴────┐     ┌────┴────┐     ┌────┴────┐       │
│  │PPG/SpO2 │     │ TFLite  │     │  HTTPS  │     │  Redis  │     │  Risk   │       │
│  │NIRS/rSO2│     │ Micro   │     │ MQTT/WS │     │ Streams │     │ Engine  │       │
│  │  IMU    │     │ Buffer  │     │  TLS 1.2│     │  Queue  │     │   LLM   │       │
│  │  Temp   │     │ Compress│     │  Auth   │     │ Pub/Sub │     │   RAG   │       │
│  └─────────┘     └─────────┘     └─────────┘     └─────────┘     └─────────┘       │
│                                                                                    │
│       ┌────────────────────────────────────────────────────────────────────┐       │
│       │                                                                     │       │
│       ▼                          ▼                          ▼               ▼       │
│  ╔══════════╗              ╔══════════╗              ╔══════════╗                    │
│  ║ DATABASE ║◄─────────────║ FASTAPI  ║◄─────────────║  REDIS   ║                    │
│  ║PostgreSQL║  AI Results  ║  Server  ║  Pub/Sub     ║  Cache   ║                    │
│  ║  + Redis ║─────────────►║  (8000)  ║─────────────►║  Pub/Sub ║                    │
│  ╚══════════║  Notify      ╚══════════║  WebSocket   ╚══════════║                    │
│       │                  │        │                  │           │                    │
│       ▼                  ▼        ▼                  ▼           ▼                    │
│  ╔══════════╗    ╔══════════╗    ╔══════════╗    ╔══════════╗                         │
│  ║  FLUTTER ║    ║  DASH-   ║    ║ MONITOR- ║    ║  ALERTS  ║                         │
│  ║   App    ║    ║  BOARD   ║    ║   ING    ║    ║  SYSTEM  ║                         │
│  ╚══════════╝    ╚══════════╝    ╚══════════╝    ╚══════════╝                         │
│                                                                                    │
└────────────────────────────────────────────────────────────────────────────────────┘
```

---

## Stage-by-Stage Breakdown

### Stage 1: Sensors (Body)

| Sensor | Signal | Sampling Rate | Interface | Raw Data Size |
|--------|--------|--------------|-----------|---------------|
| MAX30102 | PPG (IR + Red) | 100 Hz | I2C | 4 bytes × 2 = 8 bytes/sample |
| NIRS | rSO2 | 10 Hz | I2C | 2 bytes/sample |
| MPU6050 | Accelerometer + Gyro | 50 Hz | I2C | 6 bytes/sample (3-axis × 2) |
| MAX30205 | Temperature | 1 Hz | I2C | 2 bytes/sample |

**Total Raw Data Rate**: ~1.2 KB/s (idle), ~4 KB/s (active monitoring)

### Stage 2: ESP32-S3 (Edge Processing)

**Processing Pipeline**:
```
┌─────────┐    ┌──────────┐    ┌──────────┐    ┌──────────┐    ┌──────────┐
│ Raw     │───→│ DC       │───→│ Bandpass │───→│ Peak     │───→│ Feature  │
│ PPG     │    │ Removal  │    │ Filter   │    │ Detection│    │ Extract  │
└─────────┘    └──────────┘    └──────────┘    └──────────┘    └──────────┘
                                                                     │
┌─────────┐    ┌──────────┐    ┌──────────┐    ┌──────────┐         │
│ Motion  │───→│ Artifact │───→│ Quality  │───→│ TinyML   │◄────────┘
│ Data    │    │ Rejection│    │ Index    │    │ Inference│
└─────────┘    └──────────┘    └──────────┘    └─────┬────┘
                                                      │
                                              ┌───────┴───────┐
                                              │   Decision     │
                                              │  Edge vs Cloud │
                                              └───────┬───────┘
                                                      │
                              ┌───────────────────────┼───────────────────────┐
                              ▼                       ▼                       ▼
                    ┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
                    │  Edge Only      │    │  Cloud Only     │    │  Hybrid         │
                    │  Low Risk       │    │  Low Signal     │    │  Medium Risk    │
                    │  Good Quality   │    │  Bad Quality    │    │  Any Quality    │
                    │  Store & Batch  │    │  Send Immediate │    │  Edge + Cloud   │
                    └─────────────────┘    └─────────────────┘    └─────────────────┘
```

**Compression**: Before transmission, ESP32 compresses data:
- Run-length encoding for stable signals (~60% compression)
- Delta encoding for trends (~70% compression)
- Protocol Buffers (protobuf) for structured data (~40% smaller than JSON)

### Stage 3: Transport (BLE / LTE)

**BLE Path** (In-hospital, <10m range):
```
ESP32 ──[BLE 5.0]──→ Mobile App
                      │
                    Protocol: BLE GATT Notifications
                    MTU: 512 bytes
                    Interval: 15ms (high-speed mode)
                    Payload: Raw protobuf binary
                    Framing: 4-byte header + payload + 2-byte CRC
```

**LTE Path** (Remote, any range):
```
ESP32 ──[UART]──→ SIM7000G ──[LTE Cat M1]──→ MQTT Broker
                      │
                    Protocol: MQTT 3.1.1 over TLS 1.2
                    QoS: 1 (at-least-once delivery)
                    Topic: nb/{device_id}/telemetry
                    Payload: Base64-encoded protobuf
                    Keep Alive: 60s
                    Will Topic: nb/{device_id}/status (last will)
```

**Gateway Path** (Hospital WiFi):
```
ESP32 ──[WiFi]──→ MQTT Broker (local network)
                   │
                 OR
                   │
ESP32 ──[HTTPS]──→ FastAPI (direct, authenticated)
```

### Stage 4: MQTT/WebSocket Broker

**Broker**: EMQX (self-hosted) or Mosquitto

```
MQTT Topics:
  nb/{device_id}/telemetry     # Sensor readings (QoS 1)
  nb/{device_id}/alert         # Device-generated alerts (QoS 2)
  nb/{device_id}/status        # Battery, signal, uptime (QoS 1)
  nb/{device_id}/ota/command   # OTA commands from server (QoS 2)
  nb/{device_id}/ota/progress  # OTA progress from device (QoS 1)

WebSocket Path for Flutter:
  ws://server/nb/ws/{user_id}  # Real-time patient updates
```

### Stage 5: FastAPI (Backend)

```
MQTT Subscription:
  subscribe("nb/+/telemetry") → handle_telemetry()
  subscribe("nb/+/alert")     → handle_alert()
  subscribe("nb/+/status")    → handle_status()

WebSocket Handler:
  on_connect("/ws/{user_id}"):
    - Authenticate via JWT (query param)
    - Subscribe to user's patients' channels
    - Send initial state
    - Keep alive ping/pong every 30s

REST Endpoints (for historical/sync):
  POST /v1/readings/batch     # Batch upload from device or app
  GET  /v1/readings/latest    # Latest readings (with caching)
  GET  /v1/readings/          # Paginated historical data
```

### Stage 6: Redis Streams (Message Queue)

```
Telemetry Stream:
  XADD telemetry:readings * 
    device_id device_001
    patient_id pat_123
    heart_rate 72
    spo2 98
    risk_score 0.12
    timestamp 2026-07-14T16:30:00Z

Consumer Groups:
  Group: ai-consumers
    Consumer: risk-engine-1  (processes 50% of stream)
    Consumer: risk-engine-2  (processes 50% of stream)

  Group: alert-consumers
    Consumer: alert-engine-1 (processes all alerts)

  Group: storage-consumers
    Consumer: db-writer-1    (batch writes to PostgreSQL)
```

### Stage 7: AI Service

```
Read from Redis Stream (consumer group: ai-consumers)
       │
  ┌────┴────┐
  │ Extract │─── Features (HR, SpO2, trend, variability)
  │ Features│
  └────┬────┘
       │
  ┌────┴────┐
  │  Risk   │─── Risk Score (0-1), Risk Level, Confidence
  │ Engine  │
  └────┬────┘
       │
  ┌────┴────┐
  │ Medical │─── Apply clinical rules, override if needed
  │ Rules   │
  └────┬────┘
       │
  ┌────┴────┐
  │  Alert  │─── Generate alert if threshold exceeded
  │ Engine  │
  └────┬────┘
       │
  ┌────┴────┐
  │  Store  │─── Write to PostgreSQL + Redis Cache
  │  Result │
  └────┬────┘
       │
  ┌────┴────┐
  │ Publish │─── XADD telemetry:results * {risk_assessment}
  │ Result  │
  └─────────┘
```

### Stage 8: Database

```sql
-- Optimized for time-series queries
CREATE TABLE sensor_readings (
    id UUID DEFAULT gen_random_uuid(),
    patient_id UUID NOT NULL REFERENCES patients(id),
    device_id UUID REFERENCES devices(id),
    recorded_at TIMESTAMPTZ NOT NULL,
    heart_rate DOUBLE PRECISION,
    spo2 DOUBLE PRECISION,
    systolic_bp DOUBLE PRECISION,
    diastolic_bp DOUBLE PRECISION,
    rso2 DOUBLE PRECISION,
    signal_quality DOUBLE PRECISION,
    motion_artifact DOUBLE PRECISION,
    risk_score DOUBLE PRECISION,
    risk_level VARCHAR(20),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    
    PRIMARY KEY (patient_id, recorded_at)  -- Partition key
) PARTITION BY RANGE (recorded_at);

-- Daily partitions for performance
CREATE TABLE sensor_readings_20260714 
    PARTITION OF sensor_readings
    FOR VALUES FROM ('2026-07-14') TO ('2026-07-15');

-- Indexes
CREATE INDEX idx_readings_patient_ts 
    ON sensor_readings(patient_id, recorded_at DESC);
CREATE INDEX idx_readings_device_ts 
    ON sensor_readings(device_id, recorded_at DESC);
CREATE INDEX idx_readings_risk 
    ON sensor_readings(risk_score DESC) 
    WHERE risk_score > 0.7;
```

### Stage 9: Real-Time Delivery (Flutter + Dashboard)

```
Redis Pub/Sub:
  PUBLISH patient:{patient_id}:update {json}

WebSocket Bridge:
  Backend subscribes to Redis keyspace
  Forwards relevant updates to WebSocket connections

Flutter Client:
  WebSocket connects on app start
  Receives real-time vital sign updates
  Updates UI via Riverpod state (no polling)
  Falls back to REST polling if WebSocket fails
```

---

## Performance Budget

| Stage | Latency Budget | P99 Target | Throughput |
|-------|---------------|------------|------------|
| Sensors → ESP32 | <50ms | 100ms | 1,000 samples/s |
| ESP32 Processing | <100ms | 200ms | 100 assessments/s |
| BLE Transport | <20ms | 50ms | 50 KB/s |
| LTE Transport | <500ms | 2s | 10 KB/s |
| MQTT Broker | <10ms | 50ms | 10,000 msg/s |
| FastAPI Ingest | <50ms | 200ms | 5,000 msg/s |
| Redis Streams | <5ms | 20ms | 50,000 msg/s |
| AI Risk Engine | <100ms | 500ms | 1,000 assessments/s |
| Database Write | <50ms | 200ms | 5,000 writes/s |
| WebSocket Push | <50ms | 200ms | 5,000 pushes/s |
| **Total (BLE)** | **<435ms** | **<1.5s** | |
| **Total (LTE)** | **<915ms** | **<3s** | |
