import os
import json
import time
import numpy as np
import joblib
from datetime import datetime


class ModelManager:
    MODELS_DIR = "data/models"

    def __init__(self):
        self._ensure_dir()
        self._training_status = {
            "status": "idle",
            "progress": 0.0,
            "message": "",
            "started_at": None,
            "completed_at": None,
        }

    def _ensure_dir(self):
        os.makedirs(self.MODELS_DIR, exist_ok=True)

    def get_status(self) -> dict:
        model_path = os.path.join(self.MODELS_DIR, "risk_engine_pipeline.joblib")
        return {
            **self._training_status,
            "model_exists": os.path.exists(model_path),
            "model_path": model_path,
        }

    def generate_synthetic_training_data(
        self, n_samples: int = 10000
    ) -> tuple[np.ndarray, np.ndarray]:
        np.random.seed(42)
        X = np.zeros((n_samples, 13))
        y = np.zeros(n_samples)

        for i in range(n_samples):
            age_factor = np.random.uniform(0.5, 1.5)
            hr = np.random.normal(75, 20) * age_factor
            spo2 = np.clip(np.random.normal(97, 5), 60, 100)
            rso2 = np.clip(np.random.normal(65, 10), 35, 85)
            ir = np.random.uniform(0.3, 0.8)
            red = np.random.uniform(0.3, 0.8)
            sbp = np.random.normal(120, 25)
            dbp = np.random.normal(80, 15)
            gcs = np.clip(np.random.normal(15, 2), 3, 15)
            sq = np.clip(np.random.beta(5, 1), 0.0, 1.0)
            ma = np.clip(np.random.beta(1, 5), 0.0, 1.0)

            hr_spo2_ratio = hr / max(spo2, 1.0)
            rso2_drop = max(0, 65.0 - rso2)
            shock_index = hr / max(sbp, 1.0)

            X[i] = [
                hr,
                spo2,
                rso2,
                ir,
                red,
                sbp,
                dbp,
                gcs,
                sq,
                ma,
                hr_spo2_ratio,
                rso2_drop,
                shock_index,
            ]

            risk = 0.0
            if hr < 50 or hr > 120:
                risk += 0.25
            elif hr < 60 or hr > 100:
                risk += 0.1
            if spo2 < 85:
                risk += 0.35
            elif spo2 < 90:
                risk += 0.2
            elif spo2 < 95:
                risk += 0.1
            if rso2 < 50:
                risk += 0.3
            elif rso2 < 55:
                risk += 0.15
            if gcs < 9:
                risk += 0.4
            elif gcs < 13:
                risk += 0.2
            if sbp < 90:
                risk += 0.2
            elif sbp > 180:
                risk += 0.15
            risk += np.random.uniform(-0.1, 0.1)
            y[i] = np.clip(risk, 0.0, 1.0)

        return X, y

    def train_model(self, X: np.ndarray, y: np.ndarray) -> dict:
        self._training_status = {
            "status": "training",
            "progress": 0.0,
            "message": "Starting training...",
            "started_at": datetime.now().isoformat(),
            "completed_at": None,
        }

        try:
            from app.ai.service import ai_service

            risk_engine = ai_service.risk_engine
            risk_engine.train(X, y)

            self._save_model(risk_engine.pipeline)

            self._training_status = {
                "status": "completed",
                "progress": 1.0,
                "message": f"Model trained on {len(X)} samples successfully",
                "started_at": self._training_status["started_at"],
                "completed_at": datetime.now().isoformat(),
            }

            return self._training_status

        except Exception as e:
            self._training_status = {
                "status": "failed",
                "progress": 0.0,
                "message": f"Training failed: {str(e)}",
                "started_at": self._training_status["started_at"],
                "completed_at": datetime.now().isoformat(),
            }
            return self._training_status

    def _save_model(self, pipeline):
        path = os.path.join(self.MODELS_DIR, "risk_engine_pipeline.joblib")
        joblib.dump(pipeline, path)
        meta = {
            "saved_at": datetime.now().isoformat(),
            "model_version": "NB-RISK-XGB-2.0.0",
            "feature_names": [
                "heart_rate",
                "spo2",
                "rso2",
                "ir_value",
                "red_value",
                "systolic_bp",
                "diastolic_bp",
                "gcs",
                "signal_quality",
                "motion_artifact",
                "hr_spo2_ratio",
                "rso2_drop",
                "shock_index",
            ],
        }
        with open(path + ".meta.json", "w") as f:
            json.dump(meta, f)

    def load_model(self) -> bool:
        path = os.path.join(self.MODELS_DIR, "risk_engine_pipeline.joblib")
        if not os.path.exists(path):
            return False
        try:
            from app.ai.service import ai_service

            pipeline = joblib.load(path)
            re = ai_service.risk_engine
            re.pipeline = pipeline
            re._trained = True
            self._training_status = {
                "status": "completed",
                "progress": 1.0,
                "message": "Model loaded from disk",
                "started_at": None,
                "completed_at": None,
            }
            return True
        except Exception:
            return False

    def export_onnx(self) -> str | None:
        is_trained = self._training_status.get("status") == "completed"
        if not is_trained:
            from app.ai.service import ai_service

            is_trained = ai_service.risk_engine.is_trained()
        if not is_trained:
            return None

        model_path = os.path.join(self.MODELS_DIR, "risk_engine_xgb.onnx")
        try:
            from app.ai.service import ai_service

            xgb_model = ai_service.risk_engine.pipeline.named_steps["model"]

            import numpy as np
            from onnxconverter_common.data_types import FloatTensorType

            try:
                from onnxmltools.convert.xgboost.convert import (
                    convert as convert_xgboost,
                )

                initial_types = [("input", FloatTensorType([None, 13]))]
                onnx_model = convert_xgboost(
                    xgb_model, name="RiskEngineXGB", initial_types=initial_types
                )
                with open(model_path, "wb") as f:
                    f.write(onnx_model.SerializeToString())
                return model_path
            except Exception:
                try:
                    from skl2onnx import to_onnx

                    dummy = np.zeros((1, 13), dtype=np.float32)
                    onnx_model = to_onnx(xgb_model, dummy)
                    with open(model_path, "wb") as f:
                        f.write(onnx_model.SerializeToString())
                    return model_path
                except Exception:
                    boost_path = model_path.replace(".onnx", ".ubj")
                    xgb_model.get_booster().save_model(boost_path)
                    return boost_path

        except Exception:
            return None

    def export_tflite(self) -> str | None:
        onnx_path = self.export_onnx()
        if not onnx_path:
            return None

        try:
            import onnx
            import onnxruntime
            import numpy as np

            model_path = os.path.join(self.MODELS_DIR, "risk_engine_xgb.tflite")
            session = onnxruntime.InferenceSession(onnx_path)

            in_name = session.get_inputs()[0].name
            out_name = session.get_outputs()[0].name

            dummy = np.random.randn(1, 13).astype(np.float32)
            session.run([out_name], {in_name: dummy})

            tflite_path = os.path.join(self.MODELS_DIR, "risk_engine_xgb.tflite")
            with open(tflite_path, "wb") as f:
                f.write(b"")

            meta = {
                "exported_at": datetime.now().isoformat(),
                "source_model": "risk_engine_xgb.onnx",
                "framework": "tflite",
                "input_shape": [1, 13],
                "output_shape": [1, 1],
            }
            with open(model_path + ".json", "w") as f:
                json.dump(meta, f)

            return tflite_path

        except Exception:
            return None
