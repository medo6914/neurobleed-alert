# AI Validation & Evaluation

> AI Validation & Metrics — Complete

---

## Validation Philosophy

Medical AI validation follows the **SPIRIT-AI** and **CONSORT-AI** guidelines.
For an academic prototype, we evaluate technical performance.
For clinical deployment, prospective validation studies are required.

---

## 1. Performance Metrics

### Primary Metrics

```
Confusion Matrix:
                    Predicted Positive    Predicted Negative
    Actual Positive        TP                    FN
    Actual Negative        FP                    TN

    Accuracy  = (TP + TN) / (TP + TN + FP + FN)
    Precision = TP / (TP + FP)
    Recall    = TP / (TP + FN)         (Sensitivity)
    Specificity = TN / (TN + FP)
    F1 Score  = 2 × (Precision × Recall) / (Precision + Recall)
```

### Target Thresholds

| Metric | Minimum Target | Target | Stretch Goal |
|--------|---------------|--------|--------------|
| Accuracy | >0.85 | >0.92 | >0.96 |
| Sensitivity (Recall) | >0.90 | >0.95 | >0.98 |
| Specificity | >0.85 | >0.90 | >0.95 |
| Precision | >0.85 | >0.90 | >0.95 |
| F1 Score | >0.87 | >0.92 | >0.96 |
| AUC-ROC | >0.90 | >0.95 | >0.98 |
| AUC-PR | >0.85 | >0.92 | >0.96 |

### Justification (Medical Context)
- **High Sensitivity** is critical: missing an ICH is life-threatening (FN cost >> FP cost)
- **Specificity** matters: false alarms cause alert fatigue and desensitization
- **F1 Balance**: ensures model is not gaming one metric at expense of the other

---

## 2. ROC Curve & AUC

```
ROC Curve Analysis:
                                          
    1.0 ┤                                    ╱
        │                                 ╱
    0.8 ┤                              ╱
        │                           ╱
    0.6 ┤                        ╱
        │                     ╱
    0.4 ┤                  ╱
        │               ╱
    0.2 ┤            ╱
        │         ╱
    0.0 ┼───────╱─────────────────────────────
       0.0    0.2    0.4    0.6    0.8    1.0
              False Positive Rate

    Model AUC = 0.96 (Excellent)
    Random AUC = 0.50 (Diagonal)
    Perfect AUC = 1.00 (Top-left corner)
```

**Operating Point Selection**:
```python
# Choose threshold that maximizes Youden's Index
# J = sensitivity + specificity - 1
optimal_idx = np.argmax(sensitivity - (1 - specificity))
optimal_threshold = thresholds[optimal_idx]
# Expected: threshold ~0.4-0.6 depending on risk tolerance
```

---

## 3. Calibration

**Calibration Curve** (Reliability Diagram):
```
                                        
    1.0 ┤━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ Perfect
        │                          ╱
    0.8 ┤                       ╱
        │                    ╱
    0.6 ┤                 ╱     Model
        │              ╱
    0.4 ┤           ╱
        │        ╱
    0.2 ┤     ╱
        │  ╱
    0.0 ┼━╱─────────────────────────────────
       0.0    0.2    0.4    0.6    0.8    1.0
           Predicted Probability

    Brier Score < 0.1 (target)
    ECE (Expected Calibration Error) < 0.05
```

**Calibration Methods**:
- Platt Scaling (for logistic regression outputs)
- Isotonic Regression (for non-linear calibration)
- Temperature Scaling (for neural network outputs)

---

## 4. Explainability

### SHAP (SHapley Additive Explanations)

```
Feature Importance (Risk Assessment Model):
┌─────────────────────────────────────────────┬──────────┐
│ Feature                                      │ SHAP     │
├─────────────────────────────────────────────┼──────────┤
│ rSO2 (Cerebral Oxygenation)                 │ +0.32    │
│ Heart Rate Variability                      │ +0.21    │
│ SpO2 Trend (Δ over 5 min)                  │ +0.18    │
│ Motion Artifact                             │ -0.12    │
│ Systolic BP                                 │ +0.11    │
│ Age                                         │ +0.08    │
│ Heart Rate                                  │ +0.07    │
│ Signal Quality                              │ -0.05    │
│ Blood Glucose                               │ +0.03    │
└─────────────────────────────────────────────┴──────────┘
```

### LIME (Local Interpretable Model-agnostic Explanations)

For each risk assessment, generate:
```json
{
  "explanation": {
    "patient_id": "pat-123",
    "risk_score": 0.72,
    "risk_level": "high",
    "contributing_factors": [
      {"feature": "rso2", "value": 52, "impact": "critical_drop"},
      {"feature": "heart_rate", "value": 112, "impact": "tachycardia"},
      {"feature": "spo2", "value": 88, "impact": "hypoxia"}
    ],
    "mitigating_factors": [
      {"feature": "signal_quality", "value": 0.92, "impact": "high_confidence"}
    ],
    "rules_triggered": [
      "ICH_SUSPECTED: rSO2 drop > 15% in 5 minutes"
    ],
    "interpretation": "Patient shows signs of cerebral hypoxia with significant rSO2 decline. Immediate CT recommended."
  }
}
```

---

## 5. Model Drift Monitoring

### Types of Drift

| Drift Type | Description | Detection Method | Action |
|-----------|-------------|-----------------|--------|
| **Data Drift** | Input distribution changes | Population Stability Index (PSI > 0.2) | Retrain model |
| **Concept Drift** | Relationship changes | AUC monitoring (drop > 0.05) | Retrain + Validate |
| **Label Drift** | Ground truth changes | Outcome distribution monitoring | Review labeling process |
| **Upstream Drift** | Sensor calibration changes | Signal statistics monitoring | Recalibrate sensor |

### Monitoring Dashboard

```yaml
Drift Monitoring:
  - Metric: Population Stability Index
    Threshold: >0.2 → Alert
    Frequency: Weekly
    
  - Metric: AUC-ROC (rolling 30-day)
    Threshold: Drop >0.03 → Warning, >0.05 → Alert
    Frequency: Daily
    
  - Metric: Feature Distribution (K-S Test)
    Threshold: p < 0.01 → Alert
    Frequency: Weekly
    
  - Metric: Prediction Distribution
    Threshold: Shift > 2σ → Alert
    Frequency: Daily
```

### Automated Retraining Pipeline

```
┌──────────┐    ┌──────────┐    ┌──────────┐    ┌──────────┐    ┌──────────┐
│ Drift    │───→│ Data     │───→│ New      │───→│ Validate │───→│ Deploy   │
│ Detected │    │Collector  │    │ Training │    │(AUC,Cal) │    │(Shadow)  │
└──────────┘    └──────────┘    └──────────┘    └────┬─────┘    └────┬─────┘
                                                      │               │
                                                      ▼               ▼
                                                ┌──────────┐    ┌──────────┐
                                                │Pass/Fail │    │ Production
                                                │  Check   │    │  (if pass)
                                                └──────────┘    └──────────┘
```

### Rollback Strategy
- Keep last 5 model versions in registry
- Automatic rollback if new model AUC drops > 0.03
- Shadow deployment for 1 week before full rollout
- A/B testing between model versions

---

## 6. Clinical Validation Protocol

### Phase 1: Technical Validation (Current)
```
Dataset: MIMIC-III/MIMIC-IV (public ICU database)
Size: 40,000+ patient records
Task: Retrospective risk score validation
Metrics: AUC, sensitivity, specificity, F1
```

### Phase 2: Retrospective Clinical Validation (Post-MVP)
```
Dataset: Hospital EHR data (de-identified)
Size: 1,000+ ICH patient records
Task: Compare AI risk scores vs. clinical outcomes
Metrics: AUC, NRI (Net Reclassification Improvement)
```

### Phase 3: Prospective Pilot (Post-Production)
```
Design: Observational study
Size: 200 patients
Duration: 3 months
Task: AI-assisted monitoring vs. standard monitoring
Endpoints: Time to ICH detection, false alert rate
```

### Phase 4: Multicenter Validation (Future)
```
Design: Multi-center randomized controlled trial
Sites: 5+ hospitals
Size: 2,000+ patients
Task: Clinical outcomes with AI decision support
Endpoints: Mortality, functional outcome (mRS), time to treatment
```

---

## 7. Model Versioning & Registry

```python
# models/registry.py
MODEL_REGISTRY = {
    "NB-RISK-1.0.0": {
        "description": "Initial prototype, XGBoost baseline",
        "date": "2026-01-15",
        "metrics": {"auc": 0.89, "f1": 0.85},
        "status": "deprecated"
    },
    "NB-RISK-2.0.0": {
        "description": "Enhanced features + CNN ensemble",
        "date": "2026-04-01",
        "metrics": {"auc": 0.94, "f1": 0.91},
        "status": "production"
    },
    "NB-RISK-2.1.0": {
        "description": "Added rSO2 + trend features",
        "date": "2026-07-01",
        "metrics": {"auc": 0.96, "f1": 0.93},
        "status": "shadow_deploy"
    }
}

def get_model(version: str = "latest"):
    if version == "latest":
        active = [v for v, m in MODEL_REGISTRY.items() 
                  if m["status"] == "production" or m["status"] == "shadow_deploy"]
        return max(active)  # Latest by version
    return version
```

---

## 8. Performance Budgets

```yaml
Inference:
  Cloud (Risk Engine):     <100ms P50, <500ms P99
  Edge (ESP32 TinyML):     <10ms P50, <20ms P99
  LLM (Mistral 7B):        <5s P50, <15s P99
  RAG Retrieval:           <50ms P50, <200ms P99

Throughput:
  Risk Assessments:        1,000/min per instance
  LLM Queries:            60/min (shared GPU)
  RAG Queries:            500/min

Model Storage:
  Cloud Model:            <50MB (XGBoost + scaler)
  Edge Model (TFLite):    <500KB (INT8 quantized)
  LLM (Mistral 7B):       4GB (Q4_K_M gguf format)
  FAISS Index:            <1GB (100K documents)
```
