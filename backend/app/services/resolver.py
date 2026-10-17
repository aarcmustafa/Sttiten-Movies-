import logging
from typing import Optional
from vidsrc_dlp import VidSrcDLP

logger = logging.getLogger("sttiten.resolver")

class VidsrcResolver:
    def __init__(self):
        self.client = VidSrcDLP()

    async def get_hls_url(self, tmdb_id: int, media_type: str = "movie", season: int = 1, episode: int = 1) -> Optional[str]:
        try:
            if media_type == "tv":
                result = await self.client.extract(tmdb_id, media_type="tv", season=season, episode=episode)
            else:
                result = await self.client.extract(tmdb_id, media_type="movie")
            if result and result.get("url"):
                logger.info(f"Extracted HLS: {result['url'][:100]}...")
                return result["url"]
            return None
        except Exception as e:
            logger.error(f"Resolver error: {e}")
            return None

resolver_service = VidsrcResolver()
