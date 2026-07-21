import time
import numpy as np
from sklearn.ensemble import RandomForestRegressor
from sklearn.pipeline import Pipeline
from sklearn.preprocessing import StandardScaler

from app.ai.schemas import RiskAssessmentRequest, RiskAssessmentResponse
from app.ai.medical_rules_engine import MedicalRulesEngine


class RiskEngine:
    MODEL_VERSION = "NB-RISK-1.0.0"
    FEATURE_NAMES = [
        "heart_rate", "spo2", "rso2", "ir_value", "red_value",
        "systolic_bp", "diastolic_bp", "gcs",
        "signal_quality", "motion_artifact",
        "hr_spo2_ratio", "rso2_drop", "shock_index",
    ]

    def __init__(self, rules_engine: MedicalRulesEngine | None = None):
        self.rules_engine = rules_engine or MedicalRulesEngine()
        self.pipeline = self._build_pipeline()
        self._trained = False

    def _build_pipeline(self) -> Pipeline:
        return Pipeline([
            ("scaler", StandardScaler()),
            ("model", RandomForestRegressor(
                n_estimators=100,
                max_depth=10,
                min_samples_leaf=5,
                random_state=42,
                n_jobs=-1,
            )),
        ])

    def _extract_features(self, data: RiskAssessmentRequest) -> np.ndarray:
        hr = data.heart_rate or 75.0
        spo2 = data.spo2 or 98.0
        rso2 = data.rso2 or 65.0

        features = np.zeros(len(self.FEATURE_NAMES))
        feature_map = {
            "heart_rate": hr,
            "spo2": spo2,
            "rso2": rso2,
            "ir_value": data.ir_value or 0.5,
            "red_value": data.red_value or 0.5,
            "systolic_bp": data.systolic_bp or 120.0,
            "diastolic_bp": data.diastolic_bp or 80.0,
            "gcs": data.gcs or 15.0,
            "signal_quality": data.signal_quality,
            "motion_artifact": data.motion_artifact,
            "hr_spo2_ratio": hr / max(spo2, 1.0),
            "rso2_drop": max(0, 65.0 - rso2),
            "shock_index": hr / max(data.systolic_bp or 120.0, 1.0),
        }

        for i, name in enumerate(self.FEATURE_NAMES):
            features[i] = feature_map.get(name, 0.0)

        return features.reshape(1, -1)

    def _compute_heuristic_risk(self, data: RiskAssessmentRequest) -> float:
        hr = data.heart_rate or 75.0
        spo2 = data.spo2 or 98.0
        rso2 = data.rso2 or 65.0
        gcs = data.gcs or 15.0
        systolic_bp = data.systolic_bp or 120.0
        sq = data.signal_quality or 0.0

        score = 0.0

        if hr < 50 or hr > 120:
            score += 0.2
        elif hr < 60 or hr > 100:
            score += 0.1

        if spo2 < 85:
            score += 0.35
        elif spo2 < 90:
            score += 0.25
        elif spo2 < 95:
            score += 0.1

        if rso2 < 50:
            score += 0.3
        elif rso2 < 55:
            score += 0.2
        elif rso2 < 60:
            score += 0.1

        if gcs < 9:
            score += 0.4
        elif gcs < 13:
            score += 0.25
        elif gcs < 15:
            score += 0.1

        if systolic_bp < 90:
            score += 0.2
        elif systolic_bp > 180:
            score += 0.15

        if sq < 0.5:
            score += 0.1

        return min(score, 1.0)

    def _risk_level_from_score(self, score: float) -> str:
        if score >= 0.8:
            return "critical"
        if score >= 0.6:
            return "high"
        if score >= 0.3:
            return "medium"
        return "low"

    def _compute_trend(self, data: RiskAssessmentRequest) -> str | None:
        if not data.readings_window or len(data.readings_window) < 2:
            return None
        try:
            scores = [r.get("risk_score", 0.5) for r in data.readings_window if isinstance(r, dict)]
            if len(scores) >= 2:
                trend = scores[-1] - scores[0]
                if trend > 0.1:
                    return "worsening"
                if trend < -0.1:
                    return "improving"
            return "stable"
        except Exception:
            return None

    def assess(self, data: RiskAssessmentRequest) -> RiskAssessmentResponse:
        start = time.perf_counter()

        heuristic_score = self._compute_heuristic_risk(data)
        features = self._extract_features(data)

        ml_score = 0.5
        if self._trained:
            try:
                ml_pred = self.pipeline.predict(features)[0]
                ml_score = float(np.clip(ml_pred, 0.0, 1.0))
            except Exception:
                pass

        ensemble_score = 0.6 * heuristic_score + 0.4 * ml_score
        ensemble_score = min(max(ensemble_score, 0.0), 1.0)
        risk_level = self._risk_level_from_score(ensemble_score)

        vitals = {
            "heart_rate": data.heart_rate or 75.0,
            "spo2": data.spo2 or 98.0,
            "rso2": data.rso2 or 65.0,
            "systolic_bp": data.systolic_bp or 120.0,
            "diastolic_bp": data.diastolic_bp or 80.0,
            "gcs": data.gcs or 15.0,
            "signal_quality": data.signal_quality,
            "motion_artifact": data.motion_artifact,
        }

        override_score, override_level, rules_triggered = (
            self.rules_engine.override_risk_if_needed(vitals, ensemble_score, risk_level)
        )

        trend = self._compute_trend(data)

        contributing_factors = []
        if data.heart_rate and (data.heart_rate < 60 or data.heart_rate > 100):
            contributing_factors.append("abnormal_heart_rate")
        if data.spo2 and data.spo2 < 95:
            contributing_factors.append("hypoxia")
        if data.rso2 and data.rso2 < 55:
            contributing_factors.append("cerebral_desaturation")
        if data.gcs and data.gcs < 13:
            contributing_factors.append("neurological_deficit")
        if data.systolic_bp and (data.systolic_bp < 90 or data.systolic_bp > 180):
            contributing_factors.append("hemodynamic_instability")

        elapsed = (time.perf_counter() - start) * 1000

        return RiskAssessmentResponse(
            risk_score=round(override_score, 4),
            risk_level=override_level,
            confidence=round(1.0 - abs(override_score - ensemble_score), 4),
            contributing_factors=contributing_factors,
            trend=trend,
            rules_triggered=rules_triggered,
            model_version=self.MODEL_VERSION,
            inference_time_ms=round(elapsed, 2),
        )

    def train(self, X: np.ndarray, y: np.ndarray):
        self.pipeline.fit(X, y)
        self._trained = True
