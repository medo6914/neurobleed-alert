import random
import uuid
from datetime import datetime, timezone

from app.schemas.sensor_reading import SensorReadingCreate


def generate_dummy_reading(patient_id: uuid.UUID, device_id: uuid.UUID | None = None) -> SensorReadingCreate:
    normal_ir = random.uniform(30000, 60000)
    normal_red = random.uniform(20000, 40000)
    motion = random.uniform(0, 0.3)

    if random.random() < 0.05:
        ir_value = normal_ir * random.uniform(0.6, 0.8)
        red_value = normal_red * random.uniform(0.7, 0.9)
        spo2 = random.uniform(85, 92)
        risk_score = random.uniform(0.6, 0.95)
        risk_level = "critical" if risk_score > 0.8 else "high"
    else:
        ir_value = normal_ir
        red_value = normal_red
        spo2 = random.uniform(95, 100)
        risk_score = random.uniform(0, 0.3)
        risk_level = "low"

    heart_rate = random.uniform(60, 100)

    return SensorReadingCreate(
        patient_id=patient_id,
        device_id=device_id,
        timestamp=datetime.now(timezone.utc),
        ir_value=round(ir_value, 2),
        red_value=round(red_value, 2),
        spo2=round(spo2, 1),
        heart_rate=round(heart_rate, 1),
        rso2=round(spo2 + random.uniform(-2, 2), 1),
        signal_quality=round(random.uniform(0.7, 1.0), 2),
        motion_artifact=round(motion, 2),
        risk_score=round(risk_score, 4),
        risk_level=risk_level,
    )
