import logging
from typing import Any

from fastapi import APIRouter, Depends, File, UploadFile

from app.core.dependencies import get_current_user
from app.models.user import User
from app.services.file_service import file_service

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/files", tags=["files"])


@router.post("/upload")
async def upload_file(
    file: UploadFile = File(...),
    folder: str = "neurobleed",
    current_user: User = Depends(get_current_user),
) -> dict[str, Any]:
    content = await file.read()
    result = await file_service.upload(file.filename or "upload.bin", content, folder)
    result["status"] = "ok"
    return result
