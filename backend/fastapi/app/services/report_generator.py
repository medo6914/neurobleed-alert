import logging
from datetime import datetime, timezone

from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, desc

from app.models.patient import Patient
from app.models.alert import Alert
from app.models.sensor_reading import SensorReading
from app.models.ai_report import AIReport
from app.models.clinical_report import ClinicalReport
from app.models.enums import ReportStatus, ReportFormat

logger = logging.getLogger(__name__)


class ReportGenerator:
    def __init__(self):
        self.templates: dict[str, str] = {}

    async def generate(
        self,
        patient_id: str,
        report_title: str,
        report_format: ReportFormat = ReportFormat.PDF,
        include_shap: bool = False,
        include_trends: bool = True,
        language: str = "en",
        db: AsyncSession | None = None,
    ) -> ClinicalReport:
        if db is None:
            raise ValueError("Database session required")

        result = await db.execute(select(Patient).where(Patient.id == patient_id))
        patient = result.scalar_one_or_none()
        if not patient:
            raise ValueError(f"Patient {patient_id} not found")

        vitals_result = await db.execute(
            select(SensorReading)
            .where(SensorReading.patient_id == patient_id)
            .order_by(desc(SensorReading.created_at))
            .limit(50)
        )
        vitals = vitals_result.scalars().all()

        alerts_result = await db.execute(
            select(Alert)
            .where(Alert.patient_id == patient_id)
            .order_by(desc(Alert.created_at))
            .limit(20)
        )
        alerts = alerts_result.scalars().all()

        ai_result = await db.execute(
            select(AIReport)
            .where(AIReport.patient_id == patient_id)
            .order_by(desc(AIReport.created_at))
            .limit(10)
        )
        ai_reports = ai_result.scalars().all()

        latest_ai = ai_reports[0] if ai_reports else None
        risk_score = latest_ai.risk_score if latest_ai else None

        html_content = self._build_html_report(
            patient=patient,
            vitals=vitals,
            alerts=alerts,
            ai_reports=ai_reports,
            include_shap=include_shap,
            include_trends=include_trends,
            language=language,
        )

        return ClinicalReport(
            patient_id=patient_id,
            title=report_title,
            report_type="clinical_summary",
            format=report_format,
            status=ReportStatus.COMPLETED,
            content_html=html_content,
            generated_at=datetime.now(timezone.utc),
            risk_score=risk_score,
            include_shap=include_shap,
            include_trends=include_trends,
            language=language,
        )

    def _build_html_report(
        self,
        patient,
        vitals: list,
        alerts: list,
        ai_reports: list,
        include_shap: bool,
        include_trends: bool,
        language: str,
    ) -> str:
        title = "تقرير سريري" if language == "ar" else "Clinical Report"
        patient_section = self._patient_section(patient, language)
        vitals_section = self._vitals_section(vitals, language)
        alerts_section = self._alerts_section(alerts, language)
        ai_section = self._ai_section(ai_reports, include_shap, language)
        vitals_trend = self._vitals_trend_chart(vitals, language) if include_trends else ""
        footer = (
            f'<div class="footer">Generated: {datetime.now(timezone.utc).strftime("%Y-%m-%d %H:%M UTC")}</div>'
        )

        return f"""<!DOCTYPE html>
<html lang="{language}">
<head>
<meta charset="UTF-8">
<style>
body {{ font-family: 'Segoe UI', Arial, sans-serif; margin: 40px; color: #333; }}
h1 {{ color: #1a73e8; border-bottom: 2px solid #1a73e8; padding-bottom: 10px; }}
h2 {{ color: #444; margin-top: 30px; }}
table {{ width: 100%; border-collapse: collapse; margin: 10px 0; }}
th, td {{ padding: 10px; text-align: left; border-bottom: 1px solid #ddd; }}
th {{ background: #f5f5f5; }}
.critical {{ color: #d32f2f; font-weight: bold; }}
.warning {{ color: #f57c00; font-weight: bold; }}
.stable {{ color: #388e3c; }}
.section {{ margin: 20px 0; padding: 15px; background: #fafafa; border-radius: 8px; }}
.footer {{ margin-top: 40px; font-size: 12px; color: #999; text-align: center; }}
.badge {{ display: inline-block; padding: 3px 8px; border-radius: 4px; font-size: 12px; }}
.badge-critical {{ background: #ffebee; color: #d32f2f; }}
.badge-warning {{ background: #fff3e0; color: #f57c00; }}
.badge-stable {{ background: #e8f5e9; color: #388e3c; }}
</style>
</head>
<body>
<h1>{title}</h1>
{patient_section}
{vitals_section}
{vitals_trend}
{alerts_section}
{ai_section}
{footer}
</body>
</html>"""

    def _patient_section(self, patient, language: str) -> str:
        if language == "ar":
            return f"""<div class="section">
<h2>معلومات المريض</h2>
<table>
<tr><td>الاسم</td><td>{patient.full_name}</td></tr>
<tr><td>MRN</td><td>{patient.mrn or '-'}</td></tr>
<tr><td>تاريخ الميلاد</td><td>{patient.date_of_birth}</td></tr>
<tr><td>الجنس</td><td>{patient.gender.value if hasattr(patient.gender, 'value') else patient.gender}</td></tr>
<tr><td>فصيلة الدم</td><td>{patient.blood_type.value if hasattr(patient.blood_type, 'value') else (patient.blood_type or '-')}</td></tr>
<tr><td>السرير</td><td>{patient.bed_number or '-'}</td></tr>
</table>
</div>"""
        return f"""<div class="section">
<h2>Patient Information</h2>
<table>
<tr><td>Name</td><td>{patient.full_name}</td></tr>
<tr><td>MRN</td><td>{patient.mrn or '-'}</td></tr>
<tr><td>Date of Birth</td><td>{patient.date_of_birth}</td></tr>
<tr><td>Gender</td><td>{patient.gender.value if hasattr(patient.gender, 'value') else patient.gender}</td></tr>
<tr><td>Blood Type</td><td>{patient.blood_type.value if hasattr(patient.blood_type, 'value') else (patient.blood_type or '-')}</td></tr>
<tr><td>Bed</td><td>{patient.bed_number or '-'}</td></tr>
</table>
</div>"""

    def _vitals_section(self, vitals: list, language: str) -> str:
        if not vitals:
            return ""
        title = "العلامات الحيوية" if language == "ar" else "Vital Signs"
        latest = vitals[0]
        hr_label = "معدل ضربات القلب" if language == "ar" else "Heart Rate"
        spo2_label = "تشبع الأكسجين" if language == "ar" else "SpO2"
        bp_label = "ضغط الدم" if language == "ar" else "Blood Pressure"
        temp_label = "درجة الحرارة" if language == "ar" else "Temperature"

        hr = f"{latest.heart_rate:.0f}" if latest.heart_rate else "-"
        spo2 = f"{latest.oxygen_saturation:.0f}%" if latest.oxygen_saturation else "-"
        bp = f"{latest.systolic_bp:.0f}/{latest.diastolic_bp:.0f}" if latest.systolic_bp else "-"
        temp = f"{latest.temperature:.1f}°C" if latest.temperature else "-"

        return f"""<div class="section">
<h2>{title}</h2>
<table>
<tr><th>{hr_label}</th><th>{spo2_label}</th><th>{bp_label}</th><th>{temp_label}</th></tr>
<tr><td>{hr}</td><td>{spo2}</td><td>{bp}</td><td>{temp}</td></tr>
</table>
</div>"""

    def _vitals_trend_chart(self, vitals: list, language: str) -> str:
        if len(vitals) < 3:
            return ""
        title = "اتجاهات العلامات الحيوية" if language == "ar" else "Vital Signs Trends"

        rows = ""
        for v in vitals[:20]:
            ts = v.created_at.strftime("%m-%d %H:%M") if v.created_at else "-"
            hr = f"{v.heart_rate:.0f}" if v.heart_rate else "-"
            spo2 = f"{v.oxygen_saturation:.0f}" if v.oxygen_saturation else "-"
            sbp = f"{v.systolic_bp:.0f}" if v.systolic_bp else "-"
            dbp = f"{v.diastolic_bp:.0f}" if v.diastolic_bp else "-"
            rows += f"<tr><td>{ts}</td><td>{hr}</td><td>{spo2}</td><td>{sbp}/{dbp}</td></tr>"

        return f"""<div class="section">
<h2>{title}</h2>
<table>
<tr><th>Time</th><th>HR</th><th>SpO2</th><th>BP</th></tr>
{rows}
</table>
</div>"""

    def _alerts_section(self, alerts: list, language: str) -> str:
        if not alerts:
            return ""
        title = "التنبيهات" if language == "ar" else "Alerts"
        rows = ""
        for a in alerts[:20]:
            badge_class = "badge-critical" if a.severity.name == "CRITICAL" else "badge-warning" if a.severity.name in ("HIGH", "MEDIUM") else "badge-stable"
            sev = a.severity.value if hasattr(a.severity, 'value') else str(a.severity)
            rows += f"""<tr>
<td>{a.created_at.strftime("%Y-%m-%d %H:%M") if a.created_at else "-"}</td>
<td>{a.message[:80]}</td>
<td><span class="badge {badge_class}">{sev}</span></td>
</tr>"""
        return f"""<div class="section">
<h2>{title}</h2>
<table>
<tr><th>Time</th><th>Message</th><th>Severity</th></tr>
{rows}
</table>
</div>"""

    def _ai_section(self, ai_reports: list, include_shap: bool, language: str) -> str:
        if not ai_reports:
            return ""
        title = "تقييم الذكاء الاصطناعي للمخاطر" if language == "ar" else "AI Risk Assessment"
        latest = ai_reports[0]
        risk = f"{latest.risk_score:.2f}" if latest.risk_score else "N/A"
        bleeding = latest.bleeding_type or "N/A"
        icp = latest.icp_risk.value if latest.icp_risk else "N/A"
        herniation = latest.herniation_risk.value if latest.herniation_risk else "N/A"

        shap_section = ""
        if include_shap and latest.shap_values:
            shap_section = "<h3>SHAP Explanation</h3><pre>" + str(latest.shap_values) + "</pre>"

        return f"""<div class="section">
<h2>{title}</h2>
<table>
<tr><td>Risk Score</td><td class="{'critical' if (latest.risk_score or 0) > 0.7 else 'warning' if (latest.risk_score or 0) > 0.4 else 'stable'}">{risk}</td></tr>
<tr><td>Bleeding Type</td><td>{bleeding}</td></tr>
<tr><td>ICP Risk</td><td>{icp}</td></tr>
<tr><td>Herniation Risk</td><td>{herniation}</td></tr>
</table>
{shap_section}
</div>"""


report_generator = ReportGenerator()
