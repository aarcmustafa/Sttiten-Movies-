from fastapi import APIRouter, Query, HTTPException
from app.services.streaming import streaming_service

router = APIRouter(prefix="/stream", tags=["Streaming"])

@router.get("/{tmdb_id}")
async def get_stream(
    tmdb_id: int,
    media_type: str = Query("movie", pattern="^(movie|tv)$"),
    season: int = Query(1, ge=1),
    episode: int = Query(1, ge=1),
):
    result = await streaming_service.get_stream(
        tmdb_id=tmdb_id, media_type=media_type, season=season, episode=episode
    )
    if not result:
        raise HTTPException(status_code=404, detail="لا توجد مصادر متاحة لهذا المحتوى حالياً.")
    return result
