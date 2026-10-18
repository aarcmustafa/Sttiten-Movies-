import logging
import os
from typing import Optional
import httpx
import urllib.parse
import json

logger = logging.getLogger("sttiten.streaming")

CINEPRO_API_URL = os.getenv("CINEPRO_API_URL", "https://core-latest-hogs.onrender.com")

class StreamingService:
    def __init__(self):
        self.base_url = CINEPRO_API_URL.rstrip("/")
        self.timeout = httpx.Timeout(60.0, connect=15.0)

    async def get_streams(self, tmdb_id: int, media_type: str = "movie", season: int = 1, episode: int = 1) -> Optional[dict]:
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
                return None

            fixed_sources = []
            for source in sources:
                stream_url = source.get("url")
                headers = source.get("headers") or {}
                
                if not stream_url:
                    continue

                # فك تشفير البروكسي لاستخراج الرابط المباشر
                if "/v1/proxy?data=" in stream_url:
                    try:
                        parsed = urllib.parse.urlparse(stream_url)
                        query_params = urllib.parse.parse_qs(parsed.query)
                        data_param = query_params.get("data", [""])[0]
                        decoded_data = urllib.parse.unquote(data_param)
                        proxy_data = json.loads(decoded_data)
                        
                        if proxy_data.get("url"):
                            stream_url = proxy_data["url"]
                        if proxy_data.get("headers"):
                            headers = proxy_data["headers"]
                    except Exception as e:
                        logger.error(f"Proxy parse error: {e}")
                        stream_url = stream_url.replace("http://localhost:3000", self.base_url)

                # نضيف كل مصدر للقائمة
                fixed_sources.append({
                    "url": stream_url,
                    "headers": headers,
                    "quality": source.get("quality", "HD"),
                    "provider": source.get("provider", {}).get("name", "Unknown") if isinstance(source.get("provider"), dict) else "Unknown",
                })

            # إزالة التكرار (بناءً على الجودة والمزود)
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
