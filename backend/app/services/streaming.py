import logging
import os
from typing import Optional
import httpx

logger = logging.getLogger("sttiten.streaming")

CINEPRO_API_URL = os.getenv("CINEPRO_API_URL", "https://core-latest-hogs.onrender.com")

class StreamingService:
    def __init__(self):
        self.base_url = CINEPRO_API_URL.rstrip("/")
        self.timeout = httpx.Timeout(30.0, connect=10.0)

    async def get_stream(self, tmdb_id: int, media_type: str = "movie", season: int = 1, episode: int = 1) -> Optional[dict]:
        if media_type == "tv":
            path = f"/v1/tv/{tmdb_id}/seasons/{season}/episodes/{episode}"
        else:
            path = f"/v1/movies/{tmdb_id}"

        url = f"{self.base_url}{path}"
        params = {"platform": "native"}

        try:
            async with httpx.AsyncClient(timeout=self.timeout) as client:
                resp = await client.get(url, params=params)
                resp.raise_for_status()
                data = resp.json()

            sources = data.get("sources") or []
            if not sources:
                logger.warning(f"CinePro returned no sources for {tmdb_id}")
                return None

            first = sources[0]
            stream_url = first.get("url")
            headers = first.get("headers") or {}

            if not stream_url:
                return None

            if stream_url.startswith("/"):
                stream_url = f"{self.base_url}{stream_url}"

            return {
                "type": "hls",
                "url": stream_url,
                "headers": headers,
                "quality": first.get("quality"),
                "provider": first.get("provider", {}).get("name") if isinstance(first.get("provider"), dict) else None,
            }

        except httpx.HTTPStatusError as e:
            logger.error(f"CinePro HTTP error: {e.response.status_code}")
            return None
        except Exception as e:
            logger.error(f"CinePro error: {e}")
            return None

streaming_service = StreamingService()
