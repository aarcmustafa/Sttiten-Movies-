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
        # زيادة المهلة إلى 60 ثانية لأن CinePro قد يكون نائماً
        self.timeout = httpx.Timeout(60.0, connect=15.0)

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

            # فك تشفير رابط البروكسي
            if "/v1/proxy?data=" in stream_url:
                try:
                    parsed = urllib.parse.urlparse(stream_url)
                    query_params = urllib.parse.parse_qs(parsed.query)
                    data_param = query_params.get("data", [""])[0]
                    
                    decoded_data = urllib.parse.unquote(data_param)
                    proxy_data = json.loads(decoded_data)
                    
                    if proxy_data.get("url"):
                        stream_url = proxy_data["url"]
                        logger.info(f"Extracted real URL: {stream_url[:100]}")
                    if proxy_data.get("headers"):
                        headers = proxy_data["headers"]
                except Exception as e:
                    logger.error(f"Failed to parse proxy URL: {e}")
                    # خطة بديلة: استبدال localhost برابط CinePro العام
                    stream_url = stream_url.replace("http://localhost:3000", self.base_url)
                    stream_url = stream_url.replace("https://localhost:3000", self.base_url)

            return {
                "type": "hls",
                "url": stream_url,
                "headers": headers,
                "quality": first.get("quality"),
            }

        except httpx.HTTPStatusError as e:
            logger.error(f"CinePro HTTP error: {e.response.status_code}")
            return None
        except httpx.TimeoutException:
            logger.error("CinePro timeout error: Server is probably sleeping")
            return None
        except Exception as e:
            logger.error(f"CinePro error: {e}")
            return None

streaming_service = StreamingService()
