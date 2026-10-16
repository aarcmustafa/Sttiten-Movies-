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
        self.timeout = httpx.Timeout(15.0, connect=5.0)

    async def search_subtitles(self, tmdb_id: int, media_type: str = "movie", language: str = "AR"):
        if not self.api_key:
            raise SubDLError("SUBDL_API_KEY not set")
        params = {"api_key": self.api_key, "tmdb_id": tmdb_id, "type": media_type, "languages": language}
        async with httpx.AsyncClient(timeout=self.timeout) as client:
            try:
                resp = await client.get(f"{self.base_url}/subtitles", params=params)
                resp.raise_for_status()
                return resp.json()
            except httpx.HTTPStatusError as e:
                raise SubDLError(f"SubDL returned {e.response.status_code}") from e
            except httpx.RequestError as e:
                raise SubDLError(f"Network error: {e}") from e


subdl_service = SubDLService()
