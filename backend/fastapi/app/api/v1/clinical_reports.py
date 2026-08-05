import logging
import uuid
from datetime import datetime, timezone
from pathlib import Path

from fastapi import APIRouter, Depends, HTTPException, Query, status
from fastapi.responses import FileResponse, HTMLResponse
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, desc, asc, func

from app.database import get_db
from app.core.dependencies import get_current_user, require_permission
from app.core.rbac import Permission
from app.models.clinical_report import ClinicalReport
from app.models.patient import Patient
from app.models.user import User
from app.models.enums import ReportStatus, ReportFormat
from app.schemas.clinical_report import (
    ClinicalReportCreate,
    ClinicalReportUpdate,
    ClinicalReportResponse,
    ClinicalReportListResponse,
)
from app.services.report_generator import report_generator
from app.services.pdf_converter import html_to_pdf

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/reports", tags=["clinical-reports"])


@router.post(
    "/", response_model=ClinicalReportResponse, status_code=status.HTTP_201_CREATED
)
async def create_report_request(
    data: ClinicalReportCreate,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(require_permission(Permission.REPORT_CREATE)),
):
    patient_result = await db.execute(
        select(Patient).where(Patient.id == data.patient_id)
    )
    patient = patient_result.scalar_one_or_none()
    if not patient:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND, detail="Patient not found"
        )

    report = ClinicalReport(
        patient_id=data.patient_id,
        alert_id=data.alert_id,
        title=data.title,
        report_type=data.report_type,
        format=ReportFormat(data.format) if data.format else ReportFormat.PDF,
        status=ReportStatus.GENERATING,
        parameters=data.parameters,
        include_shap=data.include_shap,
        include_trends=data.include_trends,
        language=data.language,
        generated_by=current_user.id,
    )
    db.add(report)
    await db.commit()
    await db.refresh(report)

    try:
        generated = await report_generator.generate(
            patient_id=str(data.patient_id),
            report_title=data.title,
            report_format=ReportFormat(data.format)
            if data.format
            else ReportFormat.PDF,
            include_shap=data.include_shap,
            include_trends=data.include_trends,
            language=data.language,
            db=db,
        )

        report.content_html = generated.content_html
        report.risk_score = generated.risk_score
        report.status = ReportStatus.COMPLETED
        report.generated_at = datetime.now(timezone.utc)

        if report.format == ReportFormat.PDF and report.content_html:
            try:
                pdf_bytes = html_to_pdf(report.content_html)
                report.file_path = f"/reports/{report.id}.pdf"
                report.file_size = len(pdf_bytes) if pdf_bytes else None
            except Exception as e:
                logger.warning("PDF conversion failed, keeping HTML", exc_info=e)
                report.file_path = f"/reports/{report.id}.html"

        await db.commit()
        await db.refresh(report)
        logger.info(
            "Report generated",
            extra={"report_id": str(report.id), "patient_id": str(data.patient_id)},
        )

    except Exception as e:
        report.status = ReportStatus.FAILED
        report.error_message = str(e)
        await db.commit()
        await db.refresh(report)
        logger.error("Report generation failed", exc_info=e)

    return report


@router.get("/", response_model=ClinicalReportListResponse)
async def list_reports(
    page: int = Query(1, ge=1),
    per_page: int = Query(50, ge=1, le=200),
    sort_by: str | None = Query(None),
    sort_order: str = Query("desc", regex="^(asc|desc)$"),
    patient_id: str | None = Query(None),
    report_type: str | None = Query(None),
    status: str | None = Query(None),
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(require_permission(Permission.REPORT_VIEW)),
):
    query = select(ClinicalReport)

    if patient_id:
        query = query.where(ClinicalReport.patient_id == patient_id)
    if report_type:
        query = query.where(ClinicalReport.report_type == report_type)
    if status:
        query = query.where(ClinicalReport.status == status)

    total = await db.scalar(select(func.count()).select_from(query.subquery()))

    sort_column = (
        getattr(ClinicalReport, sort_by, None) if sort_by else ClinicalReport.created_at
    )
    if sort_column is not None:
        order_fn = desc if sort_order == "desc" else asc
        query = query.order_by(order_fn(sort_column))

    query = query.offset((page - 1) * per_page).limit(per_page)
    result = await db.execute(query)
    reports = result.scalars().all()

    total_pages = max(1, (total + per_page - 1) // per_page)
    return ClinicalReportListResponse(
        items=[ClinicalReportResponse.model_validate(r) for r in reports],
        total=total,
        page=page,
        per_page=per_page,
        total_pages=total_pages,
        has_next=page < total_pages,
        has_prev=page > 1,
    )


@router.get("/{report_id}", response_model=ClinicalReportResponse)
async def get_report(
    report_id: uuid.UUID,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(require_permission(Permission.REPORT_VIEW)),
):
    result = await db.execute(
        select(ClinicalReport).where(ClinicalReport.id == report_id)
    )
    report = result.scalar_one_or_none()
    if not report:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND, detail="Report not found"
        )
    return report


@router.get("/{report_id}/html")
async def view_report_html(
    report_id: uuid.UUID,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(require_permission(Permission.REPORT_VIEW)),
):
    result = await db.execute(
        select(ClinicalReport).where(ClinicalReport.id == report_id)
    )
    report = result.scalar_one_or_none()
    if not report:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND, detail="Report not found"
        )
    if not report.content_html:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND, detail="Report content not available"
        )
    return HTMLResponse(content=report.content_html)


@router.get("/{report_id}/download")
async def download_report(
    report_id: uuid.UUID,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(require_permission(Permission.REPORT_VIEW)),
):
    result = await db.execute(
        select(ClinicalReport).where(ClinicalReport.id == report_id)
    )
    report = result.scalar_one_or_none()
    if not report:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND, detail="Report not found"
        )
    if not report.file_path:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Report file not generated yet",
        )
    path = Path(report.file_path)
    if not path.exists():
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Report file missing on server",
        )
    media_type = (
        "application/pdf"
        if report.format == "pdf"
        else (
            "application/vnd.openxmlformats-officedocument.wordprocessingml.document"
            if report.format == "docx"
            else "text/html"
        )
    )
    return FileResponse(
        path=path,
        media_type=media_type,
        filename=f"{Path(report.file_path).name}",
    )


@router.put("/{report_id}", response_model=ClinicalReportResponse)
async def update_report(
    report_id: uuid.UUID,
    data: ClinicalReportUpdate,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(require_permission(Permission.REPORT_CREATE)),
):
    result = await db.execute(
        select(ClinicalReport).where(ClinicalReport.id == report_id)
    )
    report = result.scalar_one_or_none()
    if not report:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND, detail="Report not found"
        )

    update_data = data.model_dump(exclude_unset=True)
    if update_data:
        for key, value in update_data.items():
            setattr(report, key, value)

    await db.commit()
    await db.refresh(report)
    return report


@router.delete("/{report_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_report(
    report_id: uuid.UUID,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(require_permission(Permission.REPORT_CREATE)),
):
    result = await db.execute(
        select(ClinicalReport).where(ClinicalReport.id == report_id)
    )
    report = result.scalar_one_or_none()
    if not report:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND, detail="Report not found"
        )

    report.is_deleted = True
    await db.commit()
