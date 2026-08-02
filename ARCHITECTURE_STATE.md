# Architecture State — NeuroBleed Alert

## System Architecture (Current State)

```
┌─────────────────────────────────────────────────────────────┐
│                   Flutter Apps (Mobile + Web)               │
│  ┌─────────────┐ ┌──────────────┐ ┌────────────────────┐    │
│  │ Risk Input   │ │ Dashboard    │ │ Knowledge Search   │    │
│  └──────┬──────┘ └──────┬───────┘ └────────┬───────────┘    │
│         │               │                  │                 │
│         └───────────────┼──────────────────┘                 │
│                    packages/core (DTOs, Endpoints)           │
└────────────────────────┼────────────────────────────────────┘
                         │ HTTP (REST API)
┌────────────────────────┼────────────────────────────────────┐
│              FastAPI Backend (uvicorn)                       │
│  ┌─────────┐ ┌──────────┐ ┌─────────┐ ┌──────────────────┐ │
│  │ Auth    │ │ Risk     │ │ AI      │ │ Knowledge Base   │ │
│  │ (JWT)   │ │ Engine   │ │ Service │ │ (CRUD)           │ │
│  └─────────┘ └────┬─────┘ └────┬────┘ └──────────────────┘ │
│                   │             │                            │
│        ┌──────────┼─────────────┼──────────┐                │
│        │ XGBoost  │  SHAP       │  FAISS   │                │
│        │ Model    │  Explainer  │  Index   │                │
│        └──────────┴─────────────┴──────────┘                │
│                   │             │                            │
│              ┌────┴─────────────┴────┐                      │
│              │   Model Manager      │                       │
│              │  (Train, Save, ONNX) │                       │
│              └──────────────────────┘                       │
│                   │                                         │
│              ┌────┴────────────┐                             │
│              │  PubMed Client  │                             │
│              │  (Biopython)    │                             │
│              └─────────────────┘                             │
│                                                             │
│  ┌─────────────┐  ┌────────────┐  ┌──────────────────────┐  │
│  │ Redis (opt)  │  │ SQLite/    │  │ Alembic Migrations  │  │
│  │ Rate Limit   │  │ PostgreSQL │  │                      │  │
│  │ Event Bus    │  │            │  │                      │  │
│  └─────────────┘  └────────────┘  └──────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
```

## Component Details

### AI Platform (New — Phase 7)

| Component | Tech | Status | Key File |
|-----------|------|--------|----------|
| Risk Engine | XGBRegressor + SHAP | ✅ Done | `backend/fastapi/app/ai/risk_engine.py` |
| RAG Engine | TF-IDF + FAISS (L2) | ✅ Done | `backend/fastapi/app/ai/rag_engine.py` |
| PubMed Client | Biopython Entrez | ✅ Done | `backend/fastapi/app/ai/pubmed_client.py` |
| Model Manager | Joblib + ONNX | ✅ Done | `backend/fastapi/app/ai/model_manager.py` |
| AI Service | Orchestration layer | ✅ Done | `backend/fastapi/app/ai/service.py` |
| AI Router | 5 endpoints + 3 legacy | ✅ Done | `backend/fastapi/app/ai/router.py` |

### AI Endpoints

| Method | Path | Status | Dependencies |
|--------|------|--------|--------------|
| GET | `/v1/ai/model/status` | ✅ | model_manager._training_status |
| POST | `/v1/ai/train` | ✅ | risk_engine, model_manager |
| POST | `/v1/ai/export` | ✅ | model_manager.export_onnx() |
| POST | `/v1/ai/risk/assess` | ✅ | risk_engine |
| GET | `/v1/ai/knowledge/search` | ✅ | rag_engine, knowledge_base |
| POST | `/v1/ai/knowledge/ingest` | ✅ | rag_engine, knowledge_base |
| GET | `/v1/ai/knowledge/dashboard` | ✅ | knowledge_base, risk_engine |
| POST | `/v1/ai/knowledge/batch` | ✅ | knowledge_base |

### Data Flow

**Risk Assessment**:
```
POST /v1/ai/risk/assess
  → Validate JWT → Validate input → risk_engine.predict()
  → risk_engine.explain() (SHAP)
  → Save AIReport to DB
  → Return prediction + explanation
```

**Knowledge Search**:
```
GET /v1/ai/knowledge/search?q=...&top_k=5
  → Validate JWT → rag_engine.similarity_search()
  → Return ranked results with scores
```

**Knowledge Ingest**:
```
POST /v1/ai/knowledge/ingest
  → service.ingest_knowledge()
  → Fetch PubMed articles via pubmed_client
  → Process and save to knowledge_base
  → Rebuild FAISS index via rag_engine.build_index()
```

## Persistence Layer

### Model Storage (`backend/fastapi/data/models/`)
- `risk_engine_pipeline.joblib` — Full sklearn Pipeline (NLP + XGBoost)
- `risk_engine_scaler.pkl` — Feature scaler
- `risk_engine_xgb.onnx` — ONNX export (target, currently UBJ)
- `risk_engine_xgb.ubj` — XGBoost UBJ fallback

### FAISS Storage (`backend/fastapi/data/`)
- `faiss_index` — FAISS FlatL2 index file
- `vectorizer.pkl` — TF-IDF vectorizer
- `faiss_index.meta.json` — Metadata mapping

## Database Schema (New AI Tables)

### ai_reports
- `id` (PK)
- `patient_id` (uuid, unique)
- `risk_score` (float), `risk_category` (varchar)
- `prediction` (float), `probability` (float)
- `explanation` (JSON), `shap_values` (JSON)
- `features_used` (JSON)
- `created_at`, `updated_at`

### knowledge_base
- `id` (PK)
- `title`, `content`, `source`
- `faiss_indexed` (boolean, default false)
- `faiss_index_version` (int, nullable)
- Vector store managed externally by FAISS

## Key Architectural Decisions

1. **XGBoost + Joblib Pipeline**: sklearn Pipeline wrapping SimpleImputer, OneHotEncoder, StandardScaler, then XGBRegressor. Full pipeline serialized with joblib for end-to-end inference consistency.

2. **SHAP via XGBoost native**: `model.get_booster().predict(xgb_data, pred_contribs=True)` — avoids external `shap` library. Returns per-feature contribution matrix.

3. **TF-IDF + FAISS Offline Index**: TF-IDF vectorization stored as pickle, FAISS FlatL2 index stored on disk. `build_index()` rebuilds from all knowledge_base entries. `similarity_search()` encodes query and searches FAISS.

4. **ONNX Export Strategy**: Try `onnxmltools.convert.xgboost` → fallback `skl2onnx` → fallback XGBoost UBJ. Primary path needs `initial_types=[("input", FloatTensorType([None, 13]))]`.

5. **PubMed Rate Limiting**: Biopython Entrez automatically handles NCBI's 3 req/s limit via `Entrez.sleep_between_tries`. Additional 1s sleep between queries. 24h JSON file cache.

6. **Graceful Degradation**: All external dependencies (Redis, PubMed, FAISS) have try/except with `None` returns and logged warnings. Training and prediction never break despite external failures.
