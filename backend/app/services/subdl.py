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


subdl_service = SubDLService()
