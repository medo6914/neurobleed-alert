# Data Processing Pipeline

> Data Processing Pipeline — Complete

---

## Pipeline Overview

```
SENSORS -> NOISE FILTERING -> NORMALIZATION -> FEATURE EXTRACTION -> TINYML -> RISK SCORE -> CLOUD AI -> MEDICAL RULES -> DECISION ENGINE -> DOCTOR
```

---

## Stage 1: Raw Signal Acquisition

| Sensor | Signal | Rate | Bits |
|--------|--------|------|------|
| MAX30102 (IR) | PPG IR | 100 Hz | 18-bit |
| MAX30102 (Red) | PPG Red | 100 Hz | 18-bit |
| NIRS | rSO2 | 10 Hz | 16-bit |
| MPU6050 | Accel X/Y/Z | 50 Hz | 16-bit |
| MPU6050 | Gyro X/Y/Z | 50 Hz | 16-bit |

**Total data**: ~3.6 KB/s raw (before processing)

---

## Stage 2: Pre-Processing (DSP Pipeline)

### Step 2a: DC Removal
```
Input: Raw PPG signal (with DC offset)
Filter: Moving average, window = 100 samples (1 second at 100Hz)
Output: AC-coupled PPG signal (centered at 0)
Formula: ac_signal[n] = raw_signal[n] - mean(raw_signal[n-100:n])
```

### Step 2b: Bandpass Filtering
```
Heart Rate Path:
  Filter: Butterworth 4th order, bandpass 0.8 - 3.0 Hz
  Purpose: Isolate heart rate frequency (48-180 bpm)
  
SpO2 Path:
  Filter: Butterworth 4th order, bandpass 0.5 - 5.0 Hz
  Purpose: Preserve both HR and respiration components
```

### Step 2c: Motion Artifact Detection
```
IMU Data:
  - Calculate vector magnitude: mag = sqrt(x^2 + y^2 + z^2)
  - Compute variance over 0.5s window
  - Threshold: if variance > THRESHOLD_MOTION, mark sample as artifact

Signal Quality Index (SQI):
  - Ratio of valid beats to total beats in window
  - SQI = 1.0 if no motion, 0.0 if severe motion
  - Uses: IMU variance + PPG template matching + Perfusion Index
```

### Step 2d: Signal Quality Assessment
```python
def compute_signal_quality(ppg_signal, imu_data, perfusion_index):
    # Perfusion quality (AC/DC ratio)
    ac_component = np.std(ppg_signal)
    dc_component = np.mean(ppg_signal)
    perfusion_quality = ac_component / max(dc_component, 1.0)
    
    # Motion level
    motion_magnitude = np.sqrt(np.sum(imu_data**2, axis=1)).std()
    motion_quality = 1.0 / (1.0 + motion_magnitude)
    
    # Signal regularity (autocorrelation peak)
    autocorr = np.correlate(ppg_signal, ppg_signal, mode='full')
    autocorr_peak = np.max(autocorr[len(ppg_signal):])
    regularity = autocorr_peak / len(ppg_signal) / np.var(ppg_signal)
    
    # Combined score
    sqi = 0.4 * perfusion_quality + 0.3 * motion_quality + 0.3 * regularity
    return np.clip(sqi, 0.0, 1.0)
```

---

## Stage 3: Normalization

```python
# Per-feature normalization (z-score)
# Parameters: mean and std from training dataset

NORMALIZATION_PARAMS = {
    "heart_rate": {"mean": 75.0, "std": 15.0},
    "spo2": {"mean": 97.5, "std": 2.0},
    "systolic_bp": {"mean": 120.0, "std": 20.0},
    "diastolic_bp": {"mean": 80.0, "std": 12.0},
    "rso2": {"mean": 68.0, "std": 5.0},
    "ir_amplitude": {"mean": 45000.0, "std": 10000.0},
    "red_amplitude": {"mean": 28000.0, "std": 8000.0},
    "signal_quality": {"mean": 0.85, "std": 0.10},
    "motion_artifact": {"mean": 0.10, "std": 0.15},
    "perfusion_index": {"mean": 2.0, "std": 0.8},
}

def normalize(feature_name, value):
    params = NORMALIZATION_PARAMS[feature_name]
    return (value - params["mean"]) / params["std"]
```

---

## Stage 4: Feature Extraction

### Time-Domain Features (per 30-second window)
| Feature | Formula | Medical Significance |
|---------|---------|-------------------|
| Mean HR | avg(RR_intervals) | Baseline heart rate |
| HRV_SDNN | std(RR_intervals) | Autonomic nervous system |
| HRV_RMSSD | sqrt(mean(squared_diff_RR)) | Parasympathetic activity |
| SpO2_Mean | avg(SpO2_values) | Oxygenation baseline |
| SpO2_Min | min(SpO2_values) | Desaturation severity |
| SpO2_Drop | baseline - min | Desaturation depth |
| rSO2_Mean | avg(rSO2_values) | Cerebral oxygenation |
| rSO2_Trend | slope(rSO2, 5min) | Cerebral perfusion trend |

### Frequency-Domain Features
| Feature | Method | Range | Significance |
|---------|--------|-------|-------------|
| LF Power | FFT | 0.04-0.15 Hz | Sympathetic activity |
| HF Power | FFT | 0.15-0.40 Hz | Parasympathetic activity |
| LF/HF Ratio | FFT | - | Sympathovagal balance |
| SpO2 Variability | FFT | 0.01-0.05 Hz | Respiratory modulation |

### Morphology Features
| Feature | Description |
|---------|-------------|
| PPG Amax | Systolic peak amplitude |
| PPG Amax_minus_Amin | Pulse amplitude |
| PPG dAmax/dt | Maximum slope (contractility) |
| PPG T_peak_to_peak | Inter-peak interval |
| PPG Diastolic_Ratio | Dicrotic notch position |

### Feature Vector (18 features, used for ML)
```python
feature_vector = [
    heart_rate, hrv_sdnn, hrv_rmssd,           # HR features
    spo2_mean, spo2_min, spo2_drop,             # SpO2 features
    rso2_mean, rso2_trend,                      # Cerebral oxygenation
    systolic_bp, diastolic_bp,                   # BP features
    ir_amplitude, red_amplitude,                 # PPG morphology
    perfusion_index, signal_quality,             # Signal quality
    motion_level,                                # Motion
    age, gcs_score,                              # Clinical (from patient record)
    lf_hf_ratio,                                 # HRV frequency domain
]
```

---

## Stage 5: TinyML Inference (Edge)

```python
# ESP32-S3: TensorFlow Lite Micro inference
# Model: Quantized INT8, <500KB
# Input: 8 features (subset of full feature vector)
# Output: Risk score (0-1), Risk level (low/medium/high/critical)

EDGE_FEATURES = [
    "heart_rate", "spo2", "rso2", 
    "signal_quality", "motion_artifact",
    "ir_amplitude", "red_amplitude", "perfusion_index"
]

def edge_risk_assessment(features):
    # If signal quality is too low, bypass edge and send to cloud
    if features["signal_quality"] < 0.6 or features["motion_artifact"] > 0.3:
        return {"decision": "send_to_cloud", "local_score": None}
    
    # Normalize features using INT8 quantization
    input_tensor = preprocess_for_tflite(features, EDGE_FEATURES)
    
    # Run TFLite inference (<10ms on ESP32-S3)
    risk_score = tflite_interpreter.run(input_tensor)[0]
    
    return {
        "decision": "edge_ok",
        "local_score": risk_score,
        "local_risk_level": classify_risk(risk_score)
    }
```

### Edge vs Cloud Decision Matrix
```
Signal Quality | Motion Artifact | Action
> 0.8          | < 0.15          | Edge only (low power)
0.6 - 0.8      | < 0.25          | Edge + Cloud verify
< 0.6          | > 0.25          | Cloud only (full analysis)
Any            | > 0.5           | Cloud only (severe motion)
```

---

## Stage 6: Cloud AI Risk Assessment

```python
# app/services/risk_engine.py

class RiskEngine:
    def __init__(self):
        self.xgb_model = joblib.load("models/ich_risk_xgb.pkl")
        self.rules_engine = RulesEngine()
        self.feature_extractor = FeatureExtractor()
    
    async def assess(self, raw_data: SensorReading) -> RiskAssessment:
        # 1. Extract full feature set (18 features)
        features = self.feature_extractor.extract(raw_data)
        
        # 2. ML prediction
        ml_risk = self.xgb_model.predict_proba(features.to_array())[:, 1]
        
        # 3. Clinical rules override
        final_risk, triggered_rules = self.rules_engine.apply(features, ml_risk)
        
        # 4. Trend analysis (compare with recent assessments)
        trend = self.analyze_trend(raw_data.patient_id, final_risk)
        
        return RiskAssessment(
            score=final_risk,
            level=self.classify(final_risk),
            ml_score=ml_risk,
            triggered_rules=triggered_rules,
            trend=trend,
            confidence=self.compute_confidence(features),
            model_version="NB-RISK-2.1.0"
        )
```

---

## Stage 7: Medical Rules Engine

### Rule Priority System
```
Priority 1000 (Hard Override - Life Critical):
  IF hr < 40 AND spo2 < 85 THEN risk = 0.95, level = critical
  IF rso2_drop > 20% IN 5min THEN risk = 0.98, level = critical

Priority 750 (High Suspicion):
  IF gcs < 13 AND rso2 < 55 THEN risk = max(risk, 0.8)
  IF systolic_bp > 180 AND hr > 100 AND ich_history THEN risk = max(risk, 0.75)

Priority 500 (Moderate Adjustment):
  IF age > 75 AND anticoagulant THEN risk = risk * 1.2
  IF spo2_drop > 5% IN 10min THEN risk = risk * 1.3

Priority 250 (Minor Adjustment):
  IF motion_artifact > 0.3 THEN confidence *= 0.8
  IF signal_quality < 0.6 THEN confidence *= 0.6
```

---

## Stage 8: Decision Engine

```python
class DecisionEngine:
    async def decide(self, assessment: RiskAssessment, patient: Patient) -> ClinicalDecision:
        decision = ClinicalDecision()
        
        if assessment.level == "critical":
            decision.actions = [
                Action("ALERT", "CRITICAL", "ICH_SUSPECTED"),
                Action("NOTIFY", "EMERGENCY_CONTACT"),
                Action("SEND", "CT_SCAN_ORDER"),
                Action("PUSH", "NEUROSURGERY_CONSULT"),
            ]
            decision.priority = "stat"
            decision.urgency = "immediate"
            
        elif assessment.level == "high":
            decision.actions = [
                Action("ALERT", "HIGH"),
                Action("NOTIFY", "ATTENDING_PHYSICIAN"),
                Action("RECOMMEND", "ENHANCED_MONITORING"),
            ]
            decision.priority = "urgent"
            decision.urgency = "< 5 minutes"
            
        elif assessment.level == "medium":
            decision.actions = [
                Action("ALERT", "MEDIUM"),
                Action("RECOMMEND", "REVIEW_IN_30MIN"),
            ]
            decision.priority = "normal"
            decision.urgency = "< 30 minutes"
            
        else:  # low
            decision.actions = [Action("LOG", "ROUTINE")]
            decision.priority = "routine"
            decision.urgency = "next round"
        
        return decision
```

---

## Stage 9: Doctor Notification

### Alert Delivery Channels
```
CRITICAL:
  - Mobile Push (FCM): Immediate
  - SMS (Twilio): Within 5 seconds
  - Dashboard: Real-time WebSocket
  - Email: Summary
  
HIGH:
  - Mobile Push (FCM): Immediate
  - Dashboard: Real-time WebSocket
  - In-app notification

MEDIUM:
  - Dashboard badge
  - In-app notification

LOW:
  - Dashboard log
  - Next periodic summary
```

---

## End-to-End Latency Budget

```
Total end-to-end: < 3 seconds (target), < 10 seconds (maximum)

Stage Allocation:
  Sensor Read:        < 100ms  (1 reading cycle)
  Pre-processing:     < 200ms  (DSP pipeline)
  Edge Inference:     < 50ms   (TinyML)
  BLE Transfer:       < 200ms  (BLE GATT)
  LTE Transfer:       < 2000ms (LTE + MQTT)
  API Ingestion:      < 50ms   (FastAPI)
  Redis Stream:       < 5ms    (In-memory)
  Cloud AI:           < 200ms  (Risk Engine)
  DB Write:           < 50ms   (PostgreSQL)
  WebSocket Push:     < 50ms   (Redis Pub/Sub)
  UI Update:          < 100ms  (Flutter render)
  --------------------------------
  Total (BLE):        ~1005ms
  Total (LTE):        ~2805ms
```

---

## Performance Benchmarks

| Stage | Throughput | P50 Latency | P99 Latency | Scalability |
|-------|-----------|-------------|-------------|-------------|
| DSP Pipeline | 10,000/s | 50ms | 200ms | Vertical (SIMD) |
| Feature Extraction | 5,000/s | 30ms | 100ms | Horizontal |
| Risk Engine (Cloud) | 1,000/s | 80ms | 300ms | Horizontal |
| Rules Engine | 10,000/s | 5ms | 20ms | Single node |
| Decision Engine | 10,000/s | 10ms | 50ms | Single node |
| **Total Pipeline** | **1,000/s** | **175ms** | **670ms** | |
