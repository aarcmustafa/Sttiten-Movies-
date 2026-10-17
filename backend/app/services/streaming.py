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

    def _fix_url(self, url: str) -> str:
        """يستبدل localhost برابط CinePro العام"""
        if not url:
            return url
        replacements = [
            ("http://localhost:3000", self.base_url),
            ("https://localhost:3000", self.base_url),
            ("http://127.0.0.1:3000", self.base_url),
            ("https://127.0.0.1:3000", self.base_url),
            ("http://localhost", self.base_url),
            ("http://0.0.0.0:3000", self.base_url),
        ]
        for old, new in replacements:
            if old in url:
                url = url.replace(old, new)
                logger.info(f"Fixed URL: replaced {old} with {new}")
        return url

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

            # إصلاح جميع الروابط في كل المصادر
            for source in sources:
                if source.get("url"):
                    source["url"] = self._fix_url(source["url"])
                # إصلاح روابط الـ subtitles أيضاً
                for sub in source.get("subtitles", []):
                    if sub.get("url"):
                        sub["url"] = self._fix_url(sub["url"])

            first = sources[0]
            stream_url = first.get("url")
            headers = first.get("headers") or {}

            if not stream_url:
                return None

            if stream_url.startswith("/"):
                stream_url = f"{self.base_url}{stream_url}"

            logger.info(f"Final stream URL: {stream_url[:120]}")

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
