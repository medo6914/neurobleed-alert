# Current Context — NeuroBleed Alert Phase 7

## What We Are Building

A production-grade AI Platform upgrade for the NeuroBleed Alert intracranial hemorrhage detection system. The core ML engine is being upgraded from RandomForest to XGBoost with SHAP explainability, with new RAG/FAISS knowledge retrieval, PubMed integration, and AI monitoring.

## Recent Work (This Session)

### Completed
- Installed `xgboost`, `faiss-cpu`, `onnxruntime`, `langchain`, `biopython`, `onnxmltools`, `skl2onnx`, `onnxconverter-common`
- Upgraded `risk_engine.py`: RandomForest → **XGBRegressor** (200 trees, max_depth=6)
- SHAP explanations via XGBoost's built-in `pred_contribs=True`
- Created `rag_engine.py`: TF-IDF + FAISS vector search with disk persistence
- Created `pubmed_client.py`: Biopython Entrez client with 24h JSON cache
- Created `model_manager.py`: Training, save/load, synthetic data generator, ONNX export
- Updated `schemas.py`: Added 8 new Pydantic models
- Updated `service.py`: AIService orchestrates all 4 new components
- Updated `router.py`: 5 new API endpoints
- Updated models: Added `explanation`, `shap_values` to AIReport; `faiss_indexed`, `faiss_index_version` to KnowledgeBase
- Created migration `4eef07e84235_phase7_ai_upgrade.py`
- Updated Flutter DTOs, endpoints, and providers (via sub-agent)
- Smoke-tested: XGBoost trains, predicts, generates SHAP, RAG searches
- All 119 pre-existing backend tests pass

### In Progress
- Full production verification (verification script running)
- ONNX export fix (just installed missing dependency)

## Architecture Decisions

1. **XGBoost over RandomForest**: Better accuracy, native SHAP support, industry standard for tabular data
2. **XGBoost built-in SHAP**: No external `shap` library needed (avoids numba/numpy version conflicts)
3. **TF-IDF + FAISS for RAG**: Avoids 1.5GB PyTorch download; upgradeable to transformer embeddings later
4. **ONNX export via onnxmltools**: `onnxmltools.convert.xgboost` with proper `initial_types` parameter
5. **In-process Event Bus**: Redis pub/sub is optional; in-process handlers always work
6. **Graceful Redis degradation**: All Redis consumers check `None` before use
7. **SQLite for testing**: PostgreSQL target for production

## Files Changed This Session

### Backend (modified)
- `app/ai/risk_engine.py` — XGBoost + SHAP
- `app/ai/service.py` — New orchestration
- `app/ai/router.py` — 5 new endpoints
- `app/ai/schemas.py` — 8 new models
- `app/ai/__init__.py` — Added ai_service export
- `app/main.py` — Added ai_service.initialize()
- `app/models/ai_report.py` — Added explanation, shap_values
- `app/models/knowledge_base.py` — Added faiss_indexed, faiss_index_version
- `requirements.txt` — 8 new dependencies

### Backend (new)
- `app/ai/rag_engine.py` — TF-IDF + FAISS
- `app/ai/pubmed_client.py` — Biopython PubMed
- `app/ai/model_manager.py` — Model lifecycle
- `alembic/versions/4eef07e84235_phase7_ai_upgrade.py` — Migration

### Flutter/Package
- `packages/core/.../dtos/ai/model_status_dto.dart` — New
- `packages/core/.../dtos/ai/dashboard_stats_dto.dart` — New
- `packages/core/.../dtos/ai/risk_assessment_response.dart` — Updated
- `packages/core/.../dtos/ai/knowledge_search_response.dart` — Updated
- `packages/core/.../endpoints/ai_endpoints.dart` — 5 new methods
- `apps/mobile_flutter/.../providers/model_status_provider.dart` — New
- `apps/mobile_flutter/.../providers/dashboard_stats_provider.dart` — New
- `apps/mobile_flutter/.../providers/knowledge_ingest_provider.dart` — New
