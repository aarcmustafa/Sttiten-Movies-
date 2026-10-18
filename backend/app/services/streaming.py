import logging
import os
from typing import Optional
import httpx

logger = logging.getLogger("sttiten.streaming")

CINEPRO_API_URL = os.getenv("CINEPRO_API_URL", "https://core-latest-hogs.onrender.com")

class StreamingService:
    def __init__(self):
        self.base_url = CINEPRO_API_URL.rstrip("/")
        self.timeout = httpx.Timeout(60.0, connect=10.0)

    async def get_streams(self, tmdb_id: int, media_type: str = "movie", season: int = 1, episode: int = 1) -> Optional[dict]:
        if media_type == "tv":
            path = f"/v1/tv/{tmdb_id}/seasons/{season}/episodes/{episode}"
        else:
            path = f"/v1/movies/{tmdb_id}"

        url = f"{self.base_url}{path}"
        params = {"platform": "native"}

        try:
            async with httpx.AsyncClient(timeout=self.timeout, follow_redirects=True) as client:
                resp = await client.get(url, params=params)
                resp.raise_for_status()
                data = resp.json()

            sources = data.get("sources") or []
            if not sources:
                return None

            fixed_sources = []
            for source in sources:
                stream_url = source.get("url")
                headers = source.get("headers") or {}
                if not stream_url:
                    continue

                # نستخدم بروكسي CinePro (نستبدل localhost فقط)
                stream_url = stream_url.replace("http://localhost:3000", self.base_url)
                stream_url = stream_url.replace("https://localhost:3000", self.base_url)
                stream_url = stream_url.replace("http://127.0.0.1:3000", self.base_url)

                fixed_sources.append({
                    "url": stream_url,
                    "headers": headers,
                    "quality": source.get("quality", "HD"),
                    "provider": source.get("provider", {}).get("name", "Unknown") if isinstance(source.get("provider"), dict) else "Unknown",
                })

            unique_sources = []
            seen = set()
            for s in fixed_sources:
                key = f"{s['quality']}-{s['provider']}"
                if key not in seen:
                    seen.add(key)
                    unique_sources.append(s)

            return {"sources": unique_sources}

        except Exception as e:
            logger.error(f"CinePro error: {e}")
            return None

streaming_service = StreamingService()
