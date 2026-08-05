import logging
import time
from pathlib import Path
from typing import Any

import httpx

from app.config import settings

logger = logging.getLogger(__name__)


class FileService:
    """File upload: Cloudinary when configured, local disk fallback (free, no key)."""

    def __init__(self) -> None:
        self.local_dir = Path("uploads")

    def cloudinary_configured(self) -> bool:
        return bool(
            settings.CLOUDINARY_CLOUD_NAME
            and settings.CLOUDINARY_API_KEY
            and settings.CLOUDINARY_API_SECRET
        )

    async def upload(
        self, filename: str, content: bytes, folder: str = "neurobleed"
    ) -> dict[str, Any]:
        if self.cloudinary_configured():
            return await self._upload_cloudinary(filename, content, folder)
        return self._upload_local(filename, content, folder)

    async def _upload_cloudinary(
        self, filename: str, content: bytes, folder: str
    ) -> dict[str, Any]:
        try:
            cloud = settings.CLOUDINARY_CLOUD_NAME
            url = f"https://api.cloudinary.com/v1_1/{cloud}/auto/upload"
            params = {
                "api_key": settings.CLOUDINARY_API_KEY,
                "timestamp": str(int(time.time())),
                "folder": folder,
            }
            async with httpx.AsyncClient(timeout=60) as client:
                resp = await client.post(
                    url,
                    data=params,
                    files={"file": (filename, content)},
                )
            if resp.status_code != 200:
                logger.warning("Cloudinary upload failed: %s", resp.text)
                return self._upload_local(filename, content, folder)
            data = resp.json()
            return {
                "provider": "cloudinary",
                "url": data["secure_url"],
                "public_id": data["public_id"],
                "bytes": data.get("bytes"),
            }
        except Exception as e:
            logger.warning("Cloudinary upload error: %s", e)
            return self._upload_local(filename, content, folder)

    def _upload_local(
        self, filename: str, content: bytes, folder: str
    ) -> dict[str, Any]:
        target = self.local_dir / folder
        target.mkdir(parents=True, exist_ok=True)
        safe_name = Path(filename).name
        path = target / safe_name
        path.write_bytes(content)
        return {"provider": "local", "path": str(path), "bytes": len(content)}


file_service = FileService()
