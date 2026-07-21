# AI Architecture

> AI System Architecture — Complete

---

## AI System Overview

```
┌─────────────────────────────────────────────────────────────┐
│                      AI GATEWAY                              │
│  (API Gateway — FastAPI Microservice on port 8001)           │
│  Routes: /v1/risk, /v1/llm, /v1/report, /v1/knowledge       │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  ┌──────────────┐  ┌──────────┐  ┌──────────────────────┐   │
│  │ Risk Engine   │  │ LLM      │  │ RAG Engine           │   │
│  │ (scikit-learn)│  │ (Mistral)│  │ (LangChain + FAISS)  │   │
│  └──────┬───────┘  └────┬─────┘  └─────────┬────────────┘   │
│         │               │                   │                │
│  ┌──────┴───────┐  ┌────┴─────┐  ┌─────────┴────────────┐   │
│  │ Medical Rules│  │ TinyML   │  │ PubMed Integration    │   │
│  │ Engine       │  │ Compiler │  │ (Biopython + Entrez)  │   │
│  └──────┬───────┘  └──────────┘  └─────────┬────────────┘   │
│         │                                   │                │
│  ┌──────┴───────────────────────────────────┴────────────┐   │
│  │           Medical Knowledge Base                       │   │
│  │           (PostgreSQL + Vector Embeddings)              │   │
│  └────────────────────────────────────────────────────────┘   │
│                                                              │
│  ┌────────────────────────────────────────────────────────┐   │
│  │           Report Generator (LLM + Templates)            │   │
│  └────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────┘
```

---

## 1. AI Gateway

**Role**: Single entry point for all AI-related requests.

**Technology**: FastAPI (standalone microservice, port 8001)

**Responsibilities**:
- Authentication & authorization verification (forwards JWT to Auth Service)
- Rate limiting (per user/minute)
- Request validation
- Response caching (Redis, TTL: 5 mins for reports)
- Load balancing between AI engines
- Circuit breaker pattern for LLM failures

**Endpoints**:
| Endpoint | Method | Description |
|----------|--------|-------------|
| `/v1/risk/assess` | POST | Real-time risk assessment from sensor data |
| `/v1/risk/batch` | POST | Batch risk assessment (historical data) |
| `/v1/llm/generate-report` | POST | Generate medical report using LLM |
| `/v1/llm/chat` | POST | Clinical decision support chat |
| `/v1/knowledge/search` | GET | Semantic search in medical knowledge base |
| `/v1/knowledge/sync-pubmed` | POST | Trigger PubMed synchronization |

---

## 2. Risk Assessment Engine

**Role**: Real-time risk scoring from physiological signals.

**Technology**: scikit-learn + ONNX Runtime

**Models**:
| Model | Input Features | Output | Training |
|-------|---------------|--------|----------|
| ICH Risk Classifier | HR, SpO2, rSO2, IR/Red ratio, trend features | Risk score (0-1) + Risk level | XGBoost trained on MIMIC-III |
| Hemorrhage Detector | Signal morphology features | Probability of active bleeding | CNN + LSTM ensemble |
| Trend Predictor | 30-min window of readings | Risk trajectory (improving/worsening/stable) | LSTM with attention |

**Architecture**:
```
Sensor Data → Feature Extraction → Model Ensemble → Risk Score
                ↓                                       ↓
          Window Features ← Historical Data      Rule Engine Override
                                                       ↓
                                              Final Risk Assessment
```

**Performance Targets**:
- Inference time: <50ms per assessment
- Throughput: 1000 assessments/sec
- Model size: <10MB for TinyML deployment

---

## 3. Medical Rules Engine

**Role**: Hard-coded clinical rules that override or augment AI predictions.

**Implementation**: Drools-inspired rules in Python (simple YAML-based rule engine)

**Rule Examples**:
```yaml
rules:
  - name: "critical_bradycardia"
    condition: "heart_rate < 40 AND spo2 < 90"
    action: "OVERRIDE_ALERT_CRITICAL"
    priority: 1000

  - name: "desaturation_cascade"
    condition: "spo2 < 85 AND systolic_bp < 90"
    action: "ESCALATE_TO_EMERGENCY"
    priority: 999

  - name: "ich_suspicion"
    condition: "rso2_drop > 15% IN 5min AND gcs < 13"
    action: "ALERT_ICH_SUSPECTED"
    priority: 950
```

**Why Rules Engine?**
- Catches edge cases AI might miss
- Provides explainability for clinical decisions
- Can be updated independently of ML models
- Regulatory requirement for medical decision support

---

## 4. TinyML Engine

**Role**: Compress and deploy models to ESP32-S3.

**Technology**: TensorFlow Lite Micro + Xtensa Optimization

**Pipeline**:
```
Trained Model (scikit-learn/XGBoost)
         ↓
  Convert to TF Lite
         ↓
  Quantize to INT8
         ↓
  Optimize for ESP32-S3 (Xtensa)
         ↓
  Deploy OTA to Device
         ↓
  On-device inference (<10ms)
```

**Edge vs Cloud Decision**:
| Criteria | Edge (ESP32) | Cloud |
|----------|--------------|-------|
| Latency | <10ms | ~100ms |
| Battery | Higher consumption | Lower consumption |
| Features | 8 core features only | Full feature set |
| Model | Lightweight (INT8, <500KB) | Full precision |
| Connectivity | Required only for alert | Required for all |

**Decision Logic**:
```
IF signal_quality > 0.8 AND motion_artifact < 0.2:
    RETURN edge_risk_score
ELSE:
    SEND to cloud for full assessment
```

---

## 5. LLM Engine

**Role**: Generate clinical reports, decision support, and natural language explanations.

**Technology**: 
- **Model**: Mistral 7B (open-weight, self-hosted) or GPT-4 (fallback)
- **Deployment**: vLLM with continuous batching
- **Format**: GGUF quantized (Q4_K_M) for single GPU inference

**Use Cases**:
| Use Case | Prompt Template | Latency Budget |
|----------|----------------|----------------|
| Risk Report | `Generate clinical report from: {data}` | <5s |
| Alert Explanation | `Explain why this patient is at risk: {context}` | <3s |
| Treatment Suggestion | `Based on {patient_data}, suggest next steps` | <10s |
| Knowledge Query | `Answer: {question} using {knowledge_base}` | <5s |

**Safety Measures**:
- Medical disclaimer on all outputs
- Temperature 0.2 for factual reporting
- Context window limited to 4K tokens
- All outputs reviewed by rules engine before delivery

---

## 6. RAG Engine (Retrieval-Augmented Generation)

**Role**: Augment LLM responses with verified medical knowledge.

**Technology**: LangChain + FAISS + Sentence-Transformers

**Architecture**:
```
User Query → Embedding (all-MiniLM-L6-v2) → Vector Search (FAISS)
                                                      ↓
                                            Retrieved Documents
                                                      ↓
                                        Context + Query → LLM
                                                      ↓
                                            Verified Response
```

**Knowledge Sources**:
| Source | Format | Update Frequency |
|--------|--------|-----------------|
| PubMed Articles | Abstracts + Full text | Weekly |
| Clinical Guidelines | PDF → Markdown | Monthly |
| Drug Database | Structured JSON | Quarterly |
| Internal Reports | Generated reports | Continuous |
| Textbook References | Medical textbooks | Semi-annual |

**Vector Store**:
- 384-dim embeddings (all-MiniLM-L6-v2)
- FAISS index with IVF + HNSW
- 100K+ document chunks
- Sub-50ms retrieval time

---

## 7. Medical Knowledge Base

**Role**: Central repository for structured medical knowledge.

**Technology**: PostgreSQL + pgvector

**Schema**:
```sql
CREATE TABLE knowledge_base (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    title VARCHAR(500) NOT NULL,
    content TEXT NOT NULL,
    source VARCHAR(255),
    category VARCHAR(100) NOT NULL,  -- diagnosis, treatment, drug, guideline
    tags JSONB DEFAULT '[]',
    embedding VECTOR(384),
    metadata JSONB,  -- PubMed ID, DOI, version
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_kb_embedding ON knowledge_base USING ivfflat (embedding vector_cosine_ops);
CREATE INDEX idx_kb_category ON knowledge_base(category);
```

**Knowledge Categories**:
| Category | Example Content | Volume |
|----------|----------------|--------|
| ICH Guidelines | AHA/ASA Guidelines for Spontaneous ICH | 50 docs |
| Risk Factors | Hypertension, Anticoagulation, Age | 200 docs |
| Treatment Protocols | Surgical vs Medical Management | 100 docs |
| Drug Interactions | Warfarin, DOACs, Antiplatelets | 500 docs |
| Monitoring Protocols | ICP Monitoring, Ventilation | 75 docs |

---

## 8. PubMed Integration

**Role**: Automatic synchronization with latest medical research.

**Technology**: Biopython + NCBI Entrez API

**Pipeline**:
```
PubMed API (E-utilities)
    ↓
Search: ("intracranial hemorrhage" OR "ICH") AND ("risk assessment" OR "prediction")
    ↓
Fetch abstracts
    ↓
Extract structured data (authors, journal, date, PMID)
    ↓
Chunk text → Generate embeddings
    ↓
Store in Knowledge Base
    ↓
Index in FAISS for RAG
```

**Sync Schedule**:
- Daily: New abstracts matching search criteria
- Weekly: Full text updates for high-impact journals
- Monthly: Review and prune outdated entries

---

## 9. Report Generator

**Role**: Generate professional medical reports using LLM + structured templates.

**Output Formats**: PDF, HTML, JSON, HL7 FHIR

**Template Structure**:
```json
{
  "report_type": "risk_assessment",
  "patient_info": { "name", "id", "age", "gender" },
  "vital_signs": { "heart_rate", "spo2", "bp", "rso2" },
  "risk_assessment": {
    "score": 0.72,
    "level": "high",
    "contributing_factors": ["hypoxia", "tachycardia"],
    "trend": "worsening"
  },
  "ai_analysis": "LLM-generated clinical narrative",
  "recommendations": ["CT scan", "Neurosurgery consult"],
  "references": ["PubMed PMID: 12345678"],
  "generated_at": "2026-07-14T16:30:00Z",
  "model_version": "NB-RISK-2.1.0"
}
```

---

## AI Service Deployment

```yaml
# docker-compose.ai.yml
services:
  ai-gateway:
    build: ./ai/gateway
    ports: ["8001:8001"]
    depends_on: [redis, postgres]

  risk-engine:
    build: ./ai/risk-engine
    deploy:
      resources:
        reservations: { cpus: '2', memory: '4G' }

  llm-engine:
    build: ./ai/llm
    deploy:
      resources:
        reservations: { cpus: '4', memory: '16G', devices: ['/dev/dri:/dev/dri'] }
    environment:
      - MODEL_PATH=/models/mistral-7b-q4.gguf

  rag-engine:
    build: ./ai/rag
    depends_on: [postgres, redis]

  knowledge-sync:
    build: ./ai/knowledge
    command: ["python", "sync_pubmed.py", "--schedule", "daily"]
```

---

## Resource Requirements

| Component | CPU | RAM | GPU | Storage |
|-----------|-----|-----|-----|---------|
| AI Gateway | 2 cores | 2GB | - | 1GB |
| Risk Engine | 4 cores | 8GB | - | 5GB |
| LLM Engine | 8 cores | 32GB | 24GB VRAM (RTX 4090) | 50GB |
| RAG Engine | 4 cores | 8GB | - | 20GB |
| Knowledge Sync | 2 cores | 4GB | - | 10GB |
| **Total** | **20 cores** | **54GB** | **24GB VRAM** | **86GB** |
