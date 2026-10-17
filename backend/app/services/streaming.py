import logging
from typing import List

logger = logging.getLogger("sttiten.streaming")

class StreamingService:
    def __init__(self):
        pass

    async def get_stream_urls(self, tmdb_id: int, media_type: str = "movie", season: int = 1, episode: int = 1) -> List[str]:
        """
        يُعيد قائمة بروابط التضمين من عدة مزودين.
        """
        urls = []
        if media_type == "tv":
            urls = [
                f"https://vidsrc.to/embed/tv/{tmdb_id}/{season}/{episode}",
                f"https://vidsrc.net/embed/tv/{tmdb_id}/{season}/{episode}",
                f"https://vidsrc.cc/v2/embed/tv/{tmdb_id}/{season}/{episode}",
                f"https://embed.su/embed/tv/{tmdb_id}/{season}/{episode}",
            ]
        else:
            urls = [
                f"https://vidsrc.to/embed/movie/{tmdb_id}",
                f"https://vidsrc.net/embed/movie/{tmdb_id}",
                f"https://vidsrc.cc/v2/embed/movie/{tmdb_id}",
                f"https://embed.su/embed/movie/{tmdb_id}",
            ]
        
        logger.info(f"Generated {len(urls)} streaming sources for {media_type} ID: {tmdb_id}")
        return urls

streaming_service = StreamingService()
