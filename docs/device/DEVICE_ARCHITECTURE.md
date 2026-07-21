# Device Software Architecture

> Device Software Architecture — Complete
> No firmware code — architecture only

---

## Hardware Block Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                    NEUROBLEED WEARABLE DEVICE                    │
│                         "NB-01"                                 │
│                                                                  │
│  ┌─────────────────────┐          ┌─────────────────────────┐   │
│  │     Power Domain     │          │     Processing Domain    │   │
│  │  ┌───────────────┐   │          │  ┌───────────────────┐  │   │
│  │  │ Li-Po Battery │   │          │  │   ESP32-S3        │  │   │
│  │  │  1800mAh      │   │          │  │   Dual-core Xtensa│  │   │
│  │  └───────┬───────┘   │          │  │   240MHz          │  │   │
│  │          │           │          │  │   512KB SRAM      │  │   │
│  │  ┌───────┴───────┐   │          │  │   16MB Flash      │  │   │
│  │  │ TP4056 +      │   │          │  │   + 8MB PSRAM     │  │   │
│  │  │ DW01          │   │          │  └────────┬──────────┘  │   │
│  │  │ (Protection)  │   │          │           │              │   │
│  │  └───────┬───────┘   │          │  ┌────────┴──────────┐   │   │
│  │          │           │          │  │  TinyML Runtime    │   │   │
│  │  ┌───────┴───────┐   │          │  │  (TFLite Micro,    │   │   │
│  │  │ MCP73831      │   │          │  │   Xtensa Opt.)     │   │   │
│  │  │ (Charger IC)  │   │          │  └───────────────────┘  │   │
│  │  └───────┬───────┘   │          │                          │   │
│  │          │           │          │  ┌───────────────────┐   │   │
│  │  ┌───────┴───────┐   │          │  │    Scheduler      │   │   │
│  │  │ MAX17048      │   │          │  │  (FreeRTOS)       │   │   │
│  │  │ (Fuel Gauge)  │   │          │  └───────────────────┘   │   │
│  │  └───────────────┘   │          │                          │   │
│  └─────────────────────┘          │  ┌───────────────────┐   │   │
│                                    │  │   Watchdog        │   │   │
│  ┌─────────────────────┐          │  │   (Internal + Ext) │   │   │
│  │    Sensor Domain     │          │  └───────────────────┘   │   │
│  │  ┌───────────────┐   │          └─────────────────────────┘   │
│  │  │  MAX30102     │   │                                         │
│  │  │  (PPG: HR,    │   │  ┌─────────────────────────────────┐   │
│  │  │   SpO2)       │   │  │       Connectivity Domain        │   │
│  │  └───────┬───────┘   │  │  ┌──────────┐ ┌──────────────┐  │   │
│  │          │           │  │  │ BLE       │ │ SIM800L /    │  │   │
│  │  ┌───────┴───────┐   │  │  │ (ESP32    │ │ SIM7000G     │  │   │
│  │  │  NIRS Sensor  │   │  │  │ Internal) │ │ (4G LTE)     │  │   │
│  │  │  (rSO2,       │   │  │  └──────────┘ └──────┬───────┘  │   │
│  │  │   Tissue Sat) │   │  │                       │          │   │
│  │  └───────┬───────┘   │  │  ┌────────────────────┴───────┐  │   │
│  │          │           │  │  │    SIM Card Slot (Nano)     │  │   │
│  │  ┌───────┴───────┐   │  │  └────────────────────────────┘  │   │
│  │  │  Accelerometer │   │  └─────────────────────────────────┘   │
│  │  │  (MPU6050)     │   │                                         │
│  │  │  (Motion       │   │                                         │
│  │  │   Detection)   │   │                                         │
│  │  └───────────────┘   │                                         │
│  └─────────────────────┘                                         │
└─────────────────────────────────────────────────────────────────┘
```

---

## Firmware Architecture Layers

```
┌──────────────────────────────────────────────────────────────────┐
│                        APPLICATION LAYER                          │
│  ┌──────────┐ ┌──────────┐ ┌─────────┐ ┌──────────┐ ┌────────┐  │
│  │ Patient  │ │ Risk     │ │ Alert   │ │ Data     │ │ OTA    │  │
│  │ Monitor  │ │ Assess   │ │ Manager │ │ Logger   │ │ Client │  │
│  └──────────┘ └──────────┘ └─────────┘ └──────────┘ └────────┘  │
├──────────────────────────────────────────────────────────────────┤
│                       SERVICE LAYER                               │
│  ┌──────────┐ ┌──────────┐ ┌─────────┐ ┌──────────┐ ┌────────┐  │
│  │ BLE      │ │ Cellular │ │ Power   │ │ Signal   │ │ Time   │  │
│  │ Manager  │ │ Manager  │ │ Manager │ │ Process  │ │ Sync   │  │
│  └──────────┘ └──────────┘ └─────────┘ └──────────┘ └────────┘  │
├──────────────────────────────────────────────────────────────────┤
│                       MIDDLEWARE LAYER                            │
│  ┌──────────┐ ┌──────────┐ ┌─────────┐ ┌──────────┐ ┌────────┐  │
│  │ TinyML   │ │ File     │ │ Config  │ │ Protocol │ │ Crypto │  │
│  │ Runtime  │ │ System   │ │ Manager │ │ Handler  │ │ Engine │  │
│  └──────────┘ └──────────┘ └─────────┘ └──────────┘ └────────┘  │
├──────────────────────────────────────────────────────────────────┤
│                      HARDWARE ABSTRACTION LAYER (HAL)            │
│  ┌──────────┐ ┌──────────┐ ┌─────────┐ ┌──────────┐ ┌────────┐  │
│  │ MAX30102 │ │ NIRS     │ │ MPU6050 │ │ Flash    │ │ BLE    │  │
│  │ Driver   │ │ Driver   │ │ Driver  │ │ Driver   │ │ Driver │  │
│  └──────────┘ └──────────┘ └─────────┘ └──────────┘ └────────┘  │
├──────────────────────────────────────────────────────────────────┤
│                      RTOS LAYER (FreeRTOS)                        │
│  ┌──────────┐ ┌──────────┐ ┌─────────┐ ┌──────────┐ ┌────────┐  │
│  │ Scheduler│ │ Tasks    │ │ Queues  │ │ Semaphore│ │ Timers │  │
│  └──────────┘ └──────────┘ └─────────┘ └──────────┘ └────────┘  │
├──────────────────────────────────────────────────────────────────┤
│                    MCU LAYER (ESP32-S3)                           │
│  ┌──────────┐ ┌──────────┐ ┌─────────┐ ┌──────────┐ ┌────────┐  │
│  │ GPIO     │ │ I2C      │ │ SPI     │ │ UART     │ │ ADC    │  │
│  │ Manager  │ │ Manager  │ │ Manager │ │ Manager  │ │Manager │  │
│  └──────────┘ └──────────┘ └─────────┘ └──────────┘ └────────┘  │
└──────────────────────────────────────────────────────────────────┘
```

---

## Component Details

### 1. Hardware Abstraction Layer (HAL)

**MAX30102 Driver**
```
Function: Read PPG (photoplethysmogram) signals
Interface: I2C (address 0x57)
Sampling: 100Hz (100 samples/sec)
Registers: FIFO config, LED config, SpO2 config
Output: IR value, Red value, temperature
Data Rate: 100 samples → 100 bytes via I2C
```

**NIRS Driver** (custom or off-the-shelf NIRS sensor)
```
Function: Read cerebral oxygenation (rSO2)
Interface: I2C or SPI
Sampling: 10Hz
Output: rSO2 value (0-100%), tissue hemoglobin index
```

**MPU6050 Driver** (Accelerometer/Gyroscope)
```
Function: Motion artifact detection
Interface: I2C
Sampling: 50Hz
Output: Accel X/Y/Z, Gyro X/Y/Z
Use: Motion artifact flag → signal quality index
```

### 2. Signal Processing Layer

```
Raw PPG ─→ DC Removal ─→ Bandpass Filter ─→ Peak Detection ─→ HR
                (0.5Hz-5Hz)     (0.8Hz-3Hz)         ↓
Raw IR  ─→ Normalization ─→ SpO2 Calculation ─→ SpO2
                                                      ↓
Motion ─→ Artifact Detection ─→ Signal Quality Index
```

**Algorithms**:
- **DC Removal**: Moving average filter (window: 100 samples)
- **Bandpass Filter**: Butterworth 4th order (0.8-3 Hz for HR, 0.5-5 Hz for PPG)
- **Peak Detection**: Adaptive threshold with refractory period (200ms)
- **SpO2 Calculation**: Ratio R = (AC_red/DC_red) / (AC_ir/DC_ir), SpO2 = 110 - 25*R
- **Motion Artifact**: MPU6050 variance > threshold → mark sample as noisy

### 3. Power Manager

```
States:
┌─────────┐     ┌──────────┐     ┌──────────┐     ┌─────────┐
│ ACTIVE  │────→│ MONITOR  │────→│ SLEEP    │────→│ DEEPSLEEP│
│ 120mA   │     │ 50mA     │     │ 5mA      │     │ 0.1mA   │
└────┬────┘     └──────────┘     └──────────┘     └─────────┘
     │                                                   │
     └───────────────────────────────────────────────────┘
             (Wake: timer or BLE interrupt)
```

| State | Condition | Current | Duration |
|-------|-----------|---------|----------|
| ACTIVE | Reading + Processing | 120mA | 10s every 5min |
| MONITOR | Standby, periodic check | 50mA | 4min 50s |
| SLEEP | No alerts, low battery | 5mA | Until next interval |
| DEEPSLEEP | Battery < 10% | 0.1mA | Until charge |

**Battery Life Calculation**:
- Capacity: 1800mAh
- Daily consumption: ~100mAh
- **Estimated battery life: 18 days**

### 4. BLE Manager

**Services**:
```yaml
BLE Services:
  - Service: "NeuroBleed Data"
    UUID: "180D"
    Characteristics:
      - Name: "PPG Data"
        UUID: "2A37"
        Properties: Notify
        Format: 20-byte payload
      - Name: "Risk Score"
        UUID: "2A38"
        Properties: Read/Notify
      - Name: "Battery Level"
        UUID: "2A19"
        Properties: Read

  - Service: "Device Configuration"
    UUID: "180A"
    Characteristics:
      - Name: "Sampling Rate"
        Properties: Read/Write
      - Name: "Alert Thresholds"
        Properties: Read/Write
      - Name: "Firmware Version"
        Properties: Read
```

**Connection Parameters**:
- Interval: 15ms (high data rate mode)
- Latency: 0
- Supervision Timeout: 400ms
- MTU: 512 bytes

### 5. Cellular Manager (SIM7000G)

**Protocol**: MQTT over TCP/TLS

**Data Flow**:
```
Device → [UART] → SIM7000G → [LTE] → MQTT Broker → [WebSocket] → Backend
```

**Parameters**:
| Parameter | Value |
|-----------|-------|
| Network | LTE Cat M1 / NB-IoT |
| Data Rate | ~300 kbps (downlink) |
| Protocol | MQTT 3.1.1 (QoS 1) |
| TLS | TLS 1.2 with certificate pinning |
| Keep Alive | 60 seconds |
| Reconnect | Exponential backoff (1s → 5min max) |

### 6. OTA Manager

**Update Flow**:
```
Cloud Backend ─→ New firmware binary ─→ ESP32 HTTPS Download
                                                 ↓
                                         Verify Signature (ECDSA)
                                                 ↓
                                         Write to OTA Partition
                                                 ↓
                                         Set Boot Partition
                                                 ↓
                                         Reboot → New Firmware
```

**Partition Scheme**:
| Partition | Size | Content |
|-----------|------|---------|
| factory | 2MB | Factory firmware (fallback) |
| ota_0 | 2MB | Primary firmware slot |
| ota_1 | 2MB | Secondary firmware slot (for OTA) |
| nvs | 256KB | Configuration data |
| tiny_models | 1MB | TinyML model storage |
| data | 4MB | Sensor data buffer |
| spiffs | 2MB | Logs, cache |

**Rollback Strategy**:
- Mark new firmware as "pending" before reboot
- On successful boot → mark "confirmed"
- On crash → bootloader reverts to previous slot
- Max 3 rollback attempts before factory reset

### 7. TinyML Runtime

**Model Deployment**:
```
Model Format: TFLite FlatBuffer
Quantization: INT8 (post-training quantization)
Input: 8 features (HR, SpO2, rSO2, IR, Red, Motion, SignalQuality, Battery)
Output: Risk score (0-1), Risk level (0: low, 1: medium, 2: high)
Model Size: <500KB
Inference Time: <10ms on ESP32-S3 @240MHz
RAM Usage: ~50KB (arena buffer)
```

**Optimization**:
- Xtensa-specific TFLite delegate for matrix operations
- Pruning: remove weights < 0.01 threshold
- Operator fusion for common patterns
- Static memory allocation (no malloc in inference path)

### 8. Scheduler (FreeRTOS Tasks)

| Task | Priority | Stack | Period | Description |
|-----|----------|-------|--------|-------------|
| SensorTask | 5 | 4096 | 10ms | Read MAX30102 + MPU6050 |
| ProcessingTask | 4 | 8192 | 100ms | Signal processing + TinyML |
| BLECommTask | 3 | 4096 | On event | BLE stack handling |
| CellularTask | 2 | 8192 | 1s | MQTT publish/receive |
| PowerTask | 1 | 2048 | 5s | Battery monitoring, state machine |
| OTATask | 3 | 16384 | On demand | Firmware update |
| WatchdogTask | 0 | 1024 | 1s | Health monitoring |

### 9. Error Handler

**Error Categories**:
| Category | Examples | Action |
|----------|---------|--------|
| Sensor | I2C timeout, invalid reading | Retry 3x, then alert |
| Communication | BLE disconnect, LTE no signal | Queue data, reconnect |
| Memory | Heap allocation failure | Reboot, log error |
| Power | Battery critical | Save state, deep sleep |
| Firmware | Crash, watchdog reset | Save crash dump, rollback |

**Error Logging**:
```c
typedef struct {
    uint32_t timestamp;
    uint8_t error_code;
    uint8_t severity; // 0:info, 1:warning, 2:critical
    char message[64];
    uint8_t task_id;
    uint32_t pc;           // Program counter at error
    uint32_t ps;           // Processor state
} error_log_t;

// Stored in SPIFFS, uploaded to cloud on next connection
```

---

## Data Flow (End-to-End)

```
[1] Sensor Read (10ms interval)
       │
[2] Signal Processing (100ms buffer)
       │
[3] Feature Extraction
       │
[4] TinyML Inference (<10ms)
       │
[5] Decision: Edge or Cloud?
       ├── Edge: Local risk calculation → BLE notification
       │
       └── Cloud: Buffer data → Compress → MQTT publish → Backend
                                  │
                            [BLE or LTE]
                                  │
                      ┌───────────┴───────────┐
                      │                       │
                  BLE Range              LTE (Anywhere)
                      │                       │
                Mobile App              MQTT Broker → Backend
                      │                       │
                  Display Alert           AI Analysis
                                          Alert Generation
```

---

## Connectivity Strategy

```
BLE Only (In Hospital):
  Device ←→ Mobile App (within 10m)
  App ←→ Cloud (via hospital WiFi/4G)

LTE Only (Remote Monitoring):
  Device ←→ Cloud (via SIM7000G)
  Device ←→ Mobile App (BLE for local config only)

Hybrid:
  Default: BLE for real-time data + LTE for alerts
  Fallback: Full LTE if BLE disconnected
```
