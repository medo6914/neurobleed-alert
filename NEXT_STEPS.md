# Next Steps — NeuroBleed Alert Phase 7

## Immediate Next Action

**Verify ONNX export fix** — The missing `onnxconverter-common` package has been installed. The `model_manager.py` now correctly imports `FloatTensorType` from `onnxconverter_common.data_types` and calls `onnxmltools.convert.xgboost` with `initial_types=[("input", FloatTensorType([None, 13]))]`. 

Steps to verify:
1. Restart the FastAPI backend (already running at port 8000)
2. Obtain a JWT for `test@neurobleed.com`
3. Train the model via `POST /v1/ai/train`
4. Test ONNX export via `POST /v1/ai/export`
5. Run the 16-item verification script

## Full Verification Checklist

- [ ] ONNX export produces valid `.onnx` protobuf (not `.ubj`)
- [ ] Risk assessment returns SHAP explanation with risk score
- [ ] Knowledge ingest creates FAISS index entries
- [ ] Knowledge search returns ranked results
- [ ] Dashboard stats aggregate correctly
- [ ] Batch assessment processes multiple patients
- [ ] PubMed fetches and caches articles
- [ ] Model status returns training metadata
- [ ] Authentication returns correct status codes (401/403)
- [ ] All 119 pytest tests still pass
- [ ] `flutter analyze` passes (if environment available)
- [ ] `dart analyze` passes (if environment available)

## Pending Recommendations

1. **Redis**: Install Redis or configure cloud Redis URL for production. All Redis features gracefully degrade now, but production needs real rate limiting and pub/sub event bus.

2. **PostgreSQL**: Migrate from SQLite to PostgreSQL for production deployment. Alembic migrations are ready.

3. **ONNX Runtime Server**: Deploy ONNX model to ONNX Runtime Server or Triton for dedicated AI inference scaling.

4. **Transformer Embeddings**: Replace TF-IDF with `sentence-transformers` for semantic search when 1.5GB model download is acceptable.

5. **GPU Inference**: Enable GPU support in XGBoost (`tree_method='gpu_hist'`) and ONNX Runtime for low-latency clinical predictions.

6. **Model Versioning**: Add model registry with version tracking, A/B testing, and automated retraining pipeline.

7. **PubMed API Key**: Register for NCBI API key to increase rate limit from 3 to 10 req/s.

8. **Flutter Screens**: Wire the provider state to actual AI screens (dashboard, knowledge search, model management).

## Open Tasks

| Task | Priority | Owner |
|------|----------|-------|
| Complete Phase 7 verification | P0 | OpenCode |
| Wire Flutter AI provider states to UI | P1 | Flutter Dev |
| Flutter integration tests for AI flows | P2 | Flutter Dev |
| Performance benchmarks (model load, inference, search) | P1 | ML Dev |
| Generate PHASE7_FINAL_VERIFICATION.md | P0 | OpenCode |
| Git commit and push Phase 7 changes | P0 | - |
| Phase 8: Hospital Platform | P1 | - |
| Phase 9: Device Platform | P1 | - |

## How to Continue in a New Session

1. Run `cd backend/fastapi && uvicorn app.main:app --host 0.0.0.0 --port 8000` to start the backend
2. Register/login as `test@neurobleed.com` to get a JWT token
3. Run `python C:\Users\medom\AppData\Local\Temp\opencode\verify_v2.py` with the token
4. Fix any issues iteratively
5. Run `pytest -v` to confirm backend tests pass
6. Run `flutter analyze` and `dart analyze` for frontend verification
7. Generate `PHASE7_FINAL_VERIFICATION.md`
8. Commit and push to `phase7-development` branch
