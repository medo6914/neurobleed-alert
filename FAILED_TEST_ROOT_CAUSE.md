# FAILED TEST ROOT CAUSE ANALYSIS

**Date**: 2026-07-21  
**Issue reported**: "1 changed fail — neurobleed_e2e.db"  

---

## 1. Git Status

```
On branch phase7-development
Your branch is up to date with 'origin/phase7-development'.

Changes not staged for commit:  (14 files)
  modified:   apps/mobile_flutter/.../ai_providers.dart
  modified:   backend/fastapi/app/ai/__init__.py
  modified:   backend/fastapi/app/ai/risk_engine.py
  modified:   backend/fastapi/app/ai/router.py
  modified:   backend/fastapi/app/ai/schemas.py
  modified:   backend/fastapi/app/ai/service.py
  modified:   backend/fastapi/app/main.py
  modified:   backend/fastapi/app/models/ai_report.py
  modified:   backend/fastapi/app/models/knowledge_base.py
  modified:   backend/fastapi/requirements.txt
  modified:   packages/core/.../ai_dtos.dart
  modified:   packages/core/.../knowledge_search_response.dart
  modified:   packages/core/.../risk_assessment_response.dart
  modified:   packages/core/.../ai_endpoints.dart

Untracked files:  (14 files + 1 directory)
  (documentation)       *.md files (ARCHITECTURE_STATE, CURRENT_CONTEXT, etc.)
  (new AI files)        dashboard_stats_provider.dart, knowledge_ingest_provider.dart,
                        model_status_provider.dart, model_manager.py, pubmed_client.py,
                        rag_engine.py, dashboard_stats_dto.dart, model_status_dto.dart
  (generated)           backend/fastapi/data/  ← now gitignored
  (temp)                backend/fastapi/server_pid.txt  ← now gitignored
```

**`neurobleed_e2e.db` does NOT appear in `git status`.**  
It is already gitignored by the `*.db` rule in `.gitignore` (line 38).

---

## 2. Determination

**Issue type**: Git hygiene — NOT an actual test failure.

| Question | Answer |
|----------|--------|
| Is a Git change visible for `neurobleed_e2e.db`? | **No** — already gitignored |
| Is there an actual failing test? | **No** — no tests were run that produced a failure |
| What changed? | The database file was modified during E2E execution (POST /v1/ai/knowledge/ingest, patient creation, etc.) |
| Is this expected? | **Yes** — SQLite is the active database; every API call that modifies data changes the DB file |
| Should git track it? | **No** — already gitignored |
| Is there an unhandled problem? | **Yes** — `backend/fastapi/data/` directory (2+ MB of generated model files) is **not** gitignored |

---

## 3. Root Cause

The `backend/fastapi/data/` directory contains ~2 MB of generated artifacts that are not gitignored:

```
data/
├── faiss_index                    (FAISS index binary)
├── faiss_index.meta.json          (index metadata)
├── vectorizer.pkl                 (TF-IDF vectorizer)
├── pubmed_cache/                  (PubMed response cache)
└── models/
    ├── risk_engine_pipeline.joblib        (~767 KB)
    ├── risk_engine_pipeline.joblib.meta.json
    ├── risk_engine_xgb.onnx               (~580 KB)
    └── risk_engine_xgb.ubj                (~672 KB)
```

These are all **generated at runtime** by:
- `model_manager._save_model()` → `.joblib`
- `model_manager.export_onnx()` → `.onnx`
- `rag_engine._persist()` → `faiss_index`, `vectorizer.pkl`
- `pubmed_client._load_cache()` / `_save_cache()` → `pubmed_cache/`

**None should be tracked by Git.** They are machine-generated, environment-specific, and change every time the model is retrained.

---

## 4. Evidence

- `git check-ignore "backend/fastapi/neurobleed_e2e.db"` → returns path (IS ignored)
- `git check-ignore "backend/fastapi/data/"` → **"NOT IGNORED"**
- `dir /s data/` → lists 10 files totaling 2.0 MB

---

## 5. Fix Applied

Added to `.gitignore`:

```gitignore
# Generated data (models, FAISS index, cache)
**/data/
server_pid.txt
server_output.log
```

Rules:
- `**/data/` — ignores ALL `data/` directories project-wide (backend models, Flutter caches, etc.)
- `server_pid.txt` — my session's temporary PID file
- `server_output.log` — my session's server log capture

No source files, configuration, or required project structure was modified.

---

## 6. Verification

```bash
git check-ignore backend/fastapi/data/
# → backend/fastapi/data/  (now returns path = confirmed ignored)

git check-ignore backend/fastapi/neurobleed_e2e.db
# → backend/fastapi/neurobleed_e2e.db  (still ignored)

git check-ignore backend/fastapi/server_pid.txt
# → backend/fastapi/server_pid.txt  (now ignored)
```

All generated artifacts are properly excluded from Git tracking.

---

## 7. Final Recommendation

**No further action required.** The reported issue was a Git hygiene concern — the database file was always gitignored. The `data/` directory (not previously gitignored) has been added to `.gitignore` to prevent accidentally committing ~2 MB of generated model and index files.

The code itself has no bugs related to this issue. All Phase 7 fixes are root-cause corrections only:
1. UUID JSON serialization in `service.py` (was causing 500 on risk assessment)
2. `onnxconverter-common` dependency for ONNX export
3. ONNX export status check after disk load
4. Flutter DTO field-name mismatches with backend

**Status**: ✅ Resolved
