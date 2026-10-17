import logging
from typing import List

logger = logging.getLogger("sttiten.streaming")

class StreamingService:
    def __init__(self):
        pass

    async def get_stream_urls(self, tmdb_id: int, media_type: str = "movie", season: int = 1, episode: int = 1) -> List[str]:
        urls = []
        
        if media_type == "tv":
            # للمسلسلات
            urls = [
                f"https://vidsrc.to/embed/tv/{tmdb_id}/{season}/{episode}",
                f"https://vidsrc.pm/embed/tv/{tmdb_id}/{season}/{episode}",
                f"https://vidfast.pro/tv/{tmdb_id}/{season}/{episode}",
                f"https://vidlink.pro/tv/{tmdb_id}/{season}/{episode}",
                f"https://vidsrc.net/embed/tv/{tmdb_id}/{season}/{episode}",
                f"https://embed.su/embed/tv/{tmdb_id}/{season}/{episode}",
                f"https://2embed.cc/embedtv/{tmdb_id}&s={season}&e={episode}",
            ]
        else:
            # للأفلام
            urls = [
                f"https://vidsrc.to/embed/movie/{tmdb_id}",
                f"https://vidsrc.pm/embed/movie/{tmdb_id}",
                f"https://vidfast.pro/movie/{tmdb_id}",
                f"https://vidlink.pro/movie/{tmdb_id}",
                f"https://vidsrc.net/embed/movie/{tmdb_id}",
                f"https://embed.su/embed/movie/{tmdb_id}",
                f"https://2embed.cc/embed/{tmdb_id}",
            ]
        
        logger.info(f"Generated {len(urls)} streaming sources for {media_type} ID: {tmdb_id}")
        return urls

streaming_service = StreamingService()
