import logging
from typing import Any, Dict, Optional
import httpx
from tenacity import retry, stop_after_attempt, wait_exponential, retry_if_exception_type
from app.config import settings

logger = logging.getLogger("sttiten.tmdb")


class TMDBError(Exception):
    pass


class TMDBService:
    def __init__(self):
        self.api_key = settings.TMDB_API_KEY
        self.base_url = settings.TMDB_BASE_URL.rstrip("/")
        self.default_lang = settings.TMDB_DEFAULT_LANGUAGE
        self.timeout = httpx.Timeout(10.0, connect=5.0)

    def _params(self, **kwargs) -> Dict[str, Any]:
        params = {"api_key": self.api_key, "language": kwargs.pop("language", self.default_lang)}
        params.update(kwargs)
        return params

    @staticmethod
    def build_image_url(path: Optional[str], size: str = "w500") -> Optional[str]:
        if not path:
            return None
        return f"{settings.TMDB_IMAGE_BASE_URL.rstrip('/')}/{size}{path}"

    @retry(stop=stop_after_attempt(3), wait=wait_exponential(multiplier=1, min=1, max=8),
           retry=retry_if_exception_type((httpx.TimeoutException, httpx.NetworkError)), reraise=True)
    async def _get(self, path: str, **params) -> Dict[str, Any]:
        if not self.api_key:
            raise TMDBError("TMDB_API_KEY not set")
        async with httpx.AsyncClient(timeout=self.timeout) as client:
            try:
                resp = await client.get(f"{self.base_url}/{path.lstrip('/')}", params=self._params(**params))
                resp.raise_for_status()
                return resp.json()
            except httpx.HTTPStatusError as e:
                raise TMDBError(f"TMDB returned {e.response.status_code}") from e
            except httpx.RequestError as e:
                raise TMDBError(f"Network error: {e}") from e

    async def get_popular_movies(self, page: int = 1):
        return await self._get("movie/popular", page=page)

    async def get_trending_movies(self, time_window: str = "week"):
        return await self._get(f"trending/movie/{time_window}")

    async def get_top_rated_movies(self, page: int = 1):
        return await self._get("movie/top_rated", page=page)

    async def get_movie_details(self, movie_id: int):
        return await self._get(f"movie/{movie_id}", append_to_response="credits,videos,recommendations")

    async def search_movies(self, query: str, page: int = 1):
        return await self._get("search/movie", query=query, page=page)

    async def get_popular_series(self, page: int = 1):
        return await self._get("tv/popular", page=page)

    async def get_trending_series(self, time_window: str = "week"):
        return await self._get(f"trending/tv/{time_window}")

    async def get_series_details(self, series_id: int):
        return await self._get(f"tv/{series_id}", append_to_response="credits,videos,recommendations")

    async def search_multi(self, query: str, page: int = 1):
        return await self._get("search/multi", query=query, page=page)


tmdb_service = TMDBService()
