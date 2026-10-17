import logging
from typing import Any, Dict, Optional
import httpx
from app.config import settings

logger = logging.getLogger("sttiten.subdl")


class SubDLError(Exception):
    pass


class SubDLService:
    def __init__(self):
        self.api_key = settings.SUBDL_API_KEY
        self.base_url = settings.SUBDL_BASE_URL.rstrip("/")
        # قاعدة التحميل (بدون /api/v1)
        self.download_base = "https://dl.subdl.com"
        self.timeout = httpx.Timeout(30.0, connect=5.0)

    async def _get(self, path: str, **params) -> Dict[str, Any]:
        if not self.api_key:
            raise SubDLError("SUBDL_API_KEY not set")
        params["api_key"] = self.api_key
        async with httpx.AsyncClient(timeout=self.timeout) as client:
            try:
                resp = await client.get(
                    f"{self.base_url}/{path.lstrip('/')}",
                    params=params,
                )
                resp.raise_for_status()
                return resp.json()
            except httpx.HTTPStatusError as e:
                raise SubDLError(f"SubDL returned {e.response.status_code}") from e
            except httpx.RequestError as e:
                raise SubDLError(f"Network error: {e}") from e

    async def search_subtitles(
        self,
        tmdb_id: int,
        media_type: str = "movie",
        language: str = "AR",
        season_number: Optional[int] = None,
        episode_number: Optional[int] = None,
    ) -> Dict[str, Any]:
        params = {
            "tmdb_id": tmdb_id,
            "type": media_type,
            "languages": language,
        }
        if season_number is not None:
            params["season_number"] = season_number
        if episode_number is not None:
            params["episode_number"] = episode_number
        return await self._get("subtitles", **params)

    async def download_subtitle(self, subtitle_path: str) -> bytes:
        """
        يُحمّل ملف الترجمة عبر SubDL دون كشف المفتاح للمستخدم.
        subtitle_path: مسار مثل /subtitle/3443533-8366101.zip
        """
        if not self.api_key:
            raise SubDLError("SUBDL_API_KEY not set")

        # نُزيل الـ query string إن وُجد
        clean_path = subtitle_path.split("?")[0].lstrip("/")

        # نبني رابط التحميل الكامل مع المفتاح على الخادم فقط
        # SubDL يستخدم dl.subdl.com للملفات
        url = f"{self.download_base}/{clean_path}"

        async with httpx.AsyncClient(timeout=self.timeout, follow_redirects=True) as client:
            try:
                resp = await client.get(url, params={"api_key": self.api_key})
                resp.raise_for_status()
                return resp.content
            except httpx.HTTPStatusError as e:
                raise SubDLError(f"SubDL download returned {e.response.status_code}") from e
            except httpx.RequestError as e:
                raise SubDLError(f"Network error: {e}") from e


subdl_service = SubDLService()
