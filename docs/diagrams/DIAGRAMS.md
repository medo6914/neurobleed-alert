# Architecture Diagrams

> Text-based architecture diagrams for the NeuroBleed Alert system

---

## 1. System Context Diagram (C4 Level 1)

```
                           ┌─────────────────────────────────┐
                           │         NEUROBLEED SYSTEM        │
                           │   Intracranial Hemorrhage Risk   │
                           │     Assessment & Alert System    │
                           └──────────────┬──────────────────┘
                                          │
         ┌────────────────────────────────┼────────────────────────────┐
         │                    │                       │                │
         ▼                    ▼                       ▼                ▼
┌──────────────────┐ ┌──────────────────┐ ┌──────────────────┐ ┌──────────┐
│   Doctor/Nurse   │ │     Patient      │ │   Hospital IT    │ │Pharmacist│
│  (Mobile + Web)  │ │  (Wearable)      │ │   (Dashboard)    │ │  (Web)   │
└──────────────────┘ └──────────────────┘ └──────────────────┘ └──────────┘
```

---

## 2. Container Diagram (C4 Level 2)

```
┌─────────────────────────────────────────────────────────────────────────────────────────┐
│                          NEUROBLEED ALERT — CONTAINER DIAGRAM                           │
│                                                                                         │
│  ┌──────────────────┐   ┌──────────────────┐   ┌──────────────────┐   ┌──────────────┐ │
│  │  Flutter App     │   │  Flutter Web     │   │  Wearable Device │   │  3rd Party   │ │
│  │  (Android/iOS)   │   │  (Dashboard)     │   │  (ESP32-S3)      │   │  Twilio      │ │
│  └────────┬─────────┘   └────────┬─────────┘   └────────┬─────────┘   │  Twilio      │ │
│           │                      │                      │              │  OpenAI      │ │
│           │  HTTPS/WS            │  HTTPS/WS            │  MQTT/BLE    │  PubMed      │ │
│           ▼                      ▼                      ▼              └──────┬───────┘ │
│  ┌──────────────────────────────────────────────────────────────────────────────┐     │
│  │                        FASTAPI BACKEND (Port 8000)                           │     │
│  │  ┌────────┐ ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────┐            │     │
│  │  │ Auth   │ │ Patients │ │ Readings │ │ Alerts   │ │ Devices  │            │     │
│  │  │ API    │ │ API      │ │ API      │ │ API      │ │ API      │            │     │
│  │  └───┬────┘ └────┬─────┘ └────┬─────┘ └────┬─────┘ └────┬─────┘            │     │
│  │      │           │            │            │            │                  │     │
│  │      ▼           ▼            ▼            ▼            ▼                  │     │
│  │  ┌────────────────────────────────────────────────────────────────────┐    │     │
│  │  │                   SERVICE LAYER                                    │    │     │
│  │  │  AuthService │ PatientService │ AIService │ AlertService │ Sync    │    │     │
│  │  └────────────────────────────────────────────────────────────────────┘    │     │
│  │      │           │            │            │            │                  │     │
│  │      ▼           ▼            ▼            ▼            ▼                  │     │
│  │  ┌────────────────────────────────────────────────────────────────────┐    │     │
│  │  │                REPOSITORY LAYER                                    │    │     │
│  │  └────────────────────────────────────────────────────────────────────┘    │     │
│  └──────────────────────────────────────────────────────────────────────────────┘     │
│           │                      │                      │                             │
│           ▼                      ▼                      ▼                             │
│  ┌──────────────────┐   ┌──────────────────┐   ┌──────────────────┐                   │
│  │    PostgreSQL    │   │      Redis       │   │   AI Service     │                   │
│  │  (Primary Data)  │   │  (Cache + Queue) │   │  (Port 8001)     │                   │
│  └──────────────────┘   └──────────────────┘   └──────────────────┘                   │
│                                                                                         │
│  ┌──────────────────────────────────────────────────────────────────────────────┐     │
│  │                           AI SERVICE (Port 8001)                              │     │
│  │  ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────────────┐   │     │
│  │  │  Risk    │ │   LLM    │ │   RAG    │ │ Medical  │ │  Report          │   │     │
│  │  │  Engine  │ │  Engine  │ │  Engine  │ │Knowledge │ │  Generator       │   │     │
│  │  └──────────┘ └──────────┘ └──────────┘ └──────────┘ └──────────────────┘   │     │
│  └──────────────────────────────────────────────────────────────────────────────┘     │
└─────────────────────────────────────────────────────────────────────────────────────────┘
```

---

## 3. ERD (Entity Relationship Diagram)

```
┌──────────────────┐       ┌──────────────────┐
│    hospitals     │       │     users        │
├──────────────────┤       ├──────────────────┤
│ id (PK)          │──┐    │ id (PK)          │
│ name             │  │    │ email (UNIQUE)    │
│ address          │  ├───►│ hashed_password   │
│ phone            │  │    │ full_name         │
│ email (UNIQUE)   │  │    │ role              │
│ license_number   │  │    │ phone             │
│ created_at       │  │    │ uuid (IX)         │
│ updated_at       │  │    │ hospital_id (FK)──┘
└──────────────────┘  │    │ is_active
                      │    │ is_email_verified
┌──────────────────┐  │    │ is_phone_verified
│    patients      │  │    │ last_login_at
├──────────────────┤  │    │ created_at
│ id (PK)          │  │    │ updated_at
│ full_name        │  │    └──────────────────
│ date_of_birth    │  │
│ gender           │  │    ┌──────────────────┐
│ national_id (IX) │  │    │     devices      │
│ phone            │  │    ├──────────────────┤
│ emergency_contact │  │    │ id (PK)          │
│ medical_conditions│  │    │ serial_number(IX)│
│ medications      │  │    │ device_type      │
│ blood_type       │  │    │ firmware_version │
│ allergies        │  │    │ sim_iccid        │
│ hospital_id (FK)─┼──┘    │ battery_level    │
│ is_active        │       │ signal_strength  │
│ created_at       │       │ last_seen        │
│ updated_at       │       │ patient_id (FK)──┼──┐
└────────┬─────────┘       │ is_active        │  │
         │                 │ created_at       │  │
         │                 │ updated_at       │  │
         │                 └──────────────────┘  │
         ▼                                       │
┌──────────────────┐        ┌──────────────────┐ │
│  sensor_readings │        │     alerts       │ │
├──────────────────┤        ├──────────────────┤ │
│ id (PK)          │        │ id (PK)          │ │
│ patient_id (FK)──┼──┐     │ patient_id (FK)──┼─┘
│ device_id (FK)   │  │     │ device_id (FK)   │
│ recorded_at (IX) │  │     │ alert_type       │
│ heart_rate       │  │     │ severity         │
│ spo2             │  │     │ risk_score       │
│ systolic_bp      │  │     │ message          │
│ diastolic_bp     │  │     │ acknowledged     │
│ rso2             │  │     │ acknowledged_by  │
│ ir_value         │  │     │ acknowledged_at  │
│ red_value        │  │     │ created_at       │
│ signal_quality   │  │     └──────────────────┘
│ motion_artifact  │  │
│ risk_score       │  │     ┌──────────────────┐
│ risk_level       │  │     │   ai_reports     │
│ created_at       │  │     ├──────────────────┤
└──────────────────┘  │     │ id (PK)          │
                      │     │ patient_id (FK)──┼──┐
┌──────────────────┐  │     │ alert_id (FK)    │  │
│  audit_logs      │  │     │ report_type      │  │
├──────────────────┤  │     │ risk_score       │  │
│ id (PK)          │  │     │ summary          │  │
│ user_id (IX)     │  │     │ detailed_analysis│  │
│ action           │  │     │ recommendations  │  │
│ resource         │  │     │ confidence       │  │
│ resource_id      │  │     │ model_version    │  │
│ details (JSONB)  │  │     │ created_at       │  │
│ ip_address       │  │     └──────────────────┘  │
│ user_agent       │  │                           │
│ created_at       │  │     ┌──────────────────┐  │
└──────────────────┘  │     │ knowledge_base   │  │
                      │     ├──────────────────┤  │
                      │     │ id (PK)          │  │
                      │     │ title            │  │
                      │     │ content          │  │
                      │     │ source           │  │
                      │     │ category         │  │
                      │     │ tags (JSONB)     │  │
                      │     │ embedding (VEC)  │  │
                      │     │ is_active        │  │
                      │     │ created_at       │  │
                      │     │ updated_at       │  │
                      │     └──────────────────┘  │
                      │                           │
                      │     ┌──────────────────┐  │
                      │     │ knowledge_updates │  │
                      │     ├──────────────────┤  │
                      │     │ id (PK)          │  │
                      │     │ knowledge_id     │  │
                      │     │ action           │  │
                      │     │ source           │  │
                      │     │ notes            │  │
                      │     │ performed_by     │  │
                      │     │ created_at       │  │
                      └─────└──────────────────┘  │
                                                   │
                ┌──────────────────────────────────┘
                │
         ┌──────┴────────┐
         │   A single    │
         │   Patient has │
         │   One Device  │
         └───────────────┘
```

---

## 4. Authentication Sequence Diagram

```
┌──────────┐    ┌──────────┐    ┌──────────┐    ┌──────────┐
│  User    │    │  Flutter │    │  FastAPI │    │PostgreSQL│
│          │    │  App     │    │ Backend  │    │          │
└────┬─────┘    └────┬─────┘    └────┬─────┘    └────┬─────┘
     │               │               │               │
     │ 1. Email +    │               │               │
     │ Password      │               │               │
     │──────────────►│               │               │
     │               │ 2. POST /auth │               │
     │               │    /login     │               │
     │               │──────────────►│               │
     │               │               │               │
     │               │               │ 3. Verify     │
     │               │               │    credentials │
     │               │               │──────────────►│
     │               │               │               │
     │               │               │ 4. User OK    │
     │               │               │◄──────────────│
     │               │               │               │
     │               │               │ 5. Generate   │
     │               │               │    JWT        │
     │               │               │               │
     │               │ 6. JWT Token  │               │
     │               │◄──────────────│               │
     │               │               │               │
     │ 7. Navigate  │               │               │
     │ to Dashboard  │               │               │
     │◄──────────────│               │               │
```

---

## 5. Real-Time Data Flow (WebSocket)

```
┌──────────┐    ┌──────────┐    ┌──────────┐    ┌──────────┐    ┌──────────┐
│  Device  │    │  MQTT    │    │ FastAPI  │    │  Redis   │    │  Flutter │
│ (ESP32)  │    │  Broker  │    │ Backend  │    │ Streams  │    │   App    │
└────┬─────┘    └────┬─────┘    └────┬─────┘    └────┬─────┘    └────┬─────┘
     │               │               │               │               │
     │ 1. MQTT Publish               │               │               │
     │ telemetry      │               │               │               │
     │───────────────►│               │               │               │
     │               │ 2. HTTP Callback               │               │
     │               │───────────────►│               │               │
     │               │               │ 3. XADD       │               │
     │               │               │ telemetry:raw │               │
     │               │               │──────────────►│               │
     │               │               │               │               │
     │               │               │ 4. BG Task:   │               │
     │               │               │ Risk Engine   │               │
     │               │               │◄──────────────│               │
     │               │               │               │               │
     │               │               │ 5. Risk Result│               │
     │               │               │──────────────►│               │
     │               │               │               │               │
     │               │               │ 6. PUBLISH    │               │
     │               │               │ result channel│               │
     │               │               │──────────────►│               │
     │               │               │               │               │
     │               │               │ 7. WebSocket  │               │
     │               │               │ push          │               │
     │               │               │──────────────────────────────►│
     │               │               │               │               │
     │               │               │               │ 8. Update UI  │
     │               │               │               │ Riverpod      │
```

---

## 6. Deployment Architecture

```
                           ┌────────────────────────────────────┐
                           │        LOAD BALANCER (ALB/Nginx)    │
                           │   api.neurobleed.com:443            │
                           └────────────────┬───────────────────┘
                                            │
           ┌────────────────────────────────┼─────────────────────────┐
           │                │               │                │        │
           ▼                ▼               ▼                ▼        ▼
   ┌──────────────┐ ┌──────────────┐ ┌──────────────┐ ┌──────────────┐
   │  FastAPI     │ │  FastAPI     │ │  FastAPI     │ │  FastAPI     │
   │  Instance 1  │ │  Instance 2  │ │  Instance 3  │ │  Instance N  │
   │  (Container) │ │  (Container) │ │  (Container) │ │  (Container) │
   └──────┬───────┘ └──────┬───────┘ └──────┬───────┘ └──────┬───────┘
          │                │                │                │
          └────────────────┼────────────────┼────────────────┘
                           │                │
                           ▼                ▼
                  ┌────────────────┐ ┌────────────────┐
                  │  PostgreSQL    │ │     Redis       │
                  │  Primary + Repl│ │  (Cache + MQ)  │
                  └────────────────┘ └────────────────┘
                           │
                           ▼
                  ┌────────────────┐
                  │   S3 / GCS     │
                  │  (Backups +    │
                  │   Firmware)    │
                  └────────────────┘
```

---

## 7. AI Service Internal Flow

```
User Request (via API Gateway)
        │
   ┌────┴────┐
   │  Auth   │  JWT Verification
   │  Check  │
   └────┬────┘
        │
   ┌────┴────┐
   │  Router │  POST /v1/risk/assess
   └────┬────┘
        │
   ┌────┴────┐
   │  Rate   │  Check rate limit (Redis)
   │  Limiter│
   └────┬────┘
        │
   ┌────┴────┐
   │  Cache  │  Check if cached result exists
   │  Lookup │  (TTL: 30s for same features)
   └────┬────┘
        │ (cache miss)
   ┌────┴────┐
   │ Feature │  Extract 18 features from raw data
   │ Extract │
   └────┬────┘
        │
   ┌────┴────┐
   │ Model   │  XGBoost ensemble → Risk Score
   │ Predict │
   └────┬────┘
        │
   ┌────┴────┐
   │ Rules   │  Apply clinical rules (override if needed)
   │ Engine  │
   └────┬────┘
        │
   ┌────┴────┐
   │  LLM    │  Generate explanation (if requested)
   │  Explain│
   └────┬────┘
        │
   ┌────┴────┐
   │  Store  │  Save to PostgreSQL + Redis Cache
   └────┬────┘
        │
   ┌────┴────┐
   │  Check  │  Check severity thresholds
   │  Alert  │
   └────┬────┘
        │ (if critical)
   ┌────┴────┐
   │  Publish│  XADD alerts stream
   │  Alert  │  Send FCM/SMS/WS
   └────┬────┘
        │
   ┌────┴────┐
   │ Response│  Return RiskAssessment JSON
   │  Send   │
   └─────────┘
```

---

## 8. Power State Machine

```
                    ┌────────────────────────────────────────────────┐
                    │              POWER STATE MACHINE               │
                    └────────────────────────────────────────────────┘

                                     ┌──────────┐
                          ┌─────────►│  ACTIVE  │◄──────────────────┐
                          │          │ 120mA    │                    │
                          │          │ Read +   │                    │
                          │          │ Process  │    ┌──────────────┐│
                          │          └────┬─────┘    │ Wake: Timer  ││
                          │               │          │ (5 min) or  ││
                          │               │ 10s      │ BLE Interrupt││
                          │               ▼          └──────────────┘│
                          │          ┌──────────┐                     │
                          ├──────────│ MONITOR  │─────────────────────┘
                          │          │ 50mA     │
                          │          │ Standby  │
                          │          └────┬─────┘
                          │               │
                          │               │ 4min 50s (no activity)
                          │               ▼
                          │          ┌──────────┐
                          ├──────────│  SLEEP   │
                          │          │ 5mA      │
                          │          └────┬─────┘
                          │               │
                          │               │ Battery < 10%
                          │               ▼
                          │          ┌──────────┐
                          │          │ DEEP     │
                          └──────────│ SLEEP    │
                                     │ 0.1mA    │
                                     └──────────┘
                                        │
                                        │ Only wakes on charge
                                        ▼
                                     ┌──────────┐
                                     │ CHARGING │
                                     │ +100mA   │
                                     └──────────┘
```
