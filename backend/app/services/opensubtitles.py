import logging
from typing import Any, Dict, List, Optional
import httpx
from app.config import settings

logger = logging.getLogger("sttiten.opensubtitles")


class OpenSubtitlesError(Exception):
    pass


class OpenSubtitlesService:
    def __init__(self):
        self.api_key = settings.OPENSUBTITLES_API_KEY
        self.base_url = settings.OPENSUBTITLES_BASE_URL.rstrip("/")
        self.user_agent = settings.OPENSUBTITLES_USER_AGENT
        self.timeout = httpx.Timeout(15.0, connect=5.0)

    def _headers(self) -> Dict[str, str]:
        return {
            "Api-Key": self.api_key,
            "User-Agent": self.user_agent,
            "Content-Type": "application/json",
            "Accept": "application/json",
        }

    async def search_subtitles(
        self,
        tmdb_id: int,
        media_type: str = "movie",
        languages: str = "ar",
        season_number: Optional[int] = None,
        episode_number: Optional[int] = None,
    ) -> Dict[str, Any]:
        if not self.api_key:
            raise OpenSubtitlesError("OPENSUBTITLES_API_KEY not set")

        params: Dict[str, Any] = {
            "tmdb_id": tmdb_id,
            "languages": languages,
        }
        if media_type == "tv" or media_type == "series":
            params["type"] = "episode"
            if season_number is not None:
                params["season_number"] = season_number
            if episode_number is not None:
                params["episode_number"] = episode_number
        else:
            params["type"] = "movie"

        async with httpx.AsyncClient(timeout=self.timeout) as client:
            try:
                resp = await client.get(
                    f"{self.base_url}/subtitles",
                    params=params,
                    headers=self._headers(),
                )
                resp.raise_for_status()
                return resp.json()
            except httpx.HTTPStatusError as e:
                raise OpenSubtitlesError(f"OpenSubtitles returned {e.response.status_code}") from e
            except httpx.RequestError as e:
                raise OpenSubtitlesError(f"Network error: {e}") from e


opensubtitles_service = OpenSubtitlesService()
