from fastapi import APIRouter, Query, HTTPException
from app.services.resolver import resolver_service
from app.services.streaming import streaming_service

router = APIRouter(prefix="/stream", tags=["Streaming"])

@router.get("/{tmdb_id}")
async def get_stream(
    tmdb_id: int,
    media_type: str = Query("movie", pattern="^(movie|tv)$"),
    season: int = Query(1, ge=1),
    episode: int = Query(1, ge=1),
):
    # نحاول أولاً استخراج رابط HLS مباشر
    hls_url = await resolver_service.get_hls_url(
        tmdb_id=tmdb_id, 
        media_type=media_type, 
        season=season, 
        episode=episode
    )
    
    if hls_url:
        return {"type": "hls", "url": hls_url}
    
    # إذا فشل، نعود للروابط العادية (WebView fallback)
    urls = await streaming_service.get_stream_urls(
        tmdb_id=tmdb_id, 
        media_type=media_type, 
        season=season, 
        episode=episode
    )
    return {"type": "embed", "urls": urls}
