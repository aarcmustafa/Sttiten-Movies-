from fastapi import APIRouter, Query, HTTPException
from app.services.streaming import streaming_service
from cachetools import TTLCache
import logging

logger = logging.getLogger("sttiten.streaming")
router = APIRouter(prefix="/stream", tags=["Streaming"])

# ذاكرة تخزين مؤقت (TTLCache) تحتفظ بالنتائج لمدة 30 دقيقة (1800 ثانية)
# maxsize=500 تعني أنها يمكنها حفظ 500 فيلم/حلقة في نفس الوقت
cache = TTLCache(maxsize=500, ttl=1800)

@router.get("/{tmdb_id}")
async def get_stream(
    tmdb_id: int,
    media_type: str = Query("movie", pattern="^(movie|tv)$"),
    season: int = Query(1, ge=1),
    episode: int = Query(1, ge=1),
):
    cache_key = f"{tmdb_id}_{media_type}_{season}_{episode}"
    
    # 1. التحقق من الذاكرة المؤقتة أولاً (أسرع رد)
    if cache_key in cache:
        logger.info(f"⚡ Returning CACHED result for {cache_key}")
        return cache[cache_key]

    # 2. إذا لم تكن موجودة، نجلبها من CinePro
    logger.info(f"🔄 Fetching NEW result from CinePro for {cache_key}")
    result = await streaming_service.get_streams(
        tmdb_id=tmdb_id, media_type=media_type, season=season, episode=episode
    )
    if not result:
        raise HTTPException(status_code=404, detail="لا توجد مصادر متاحة لهذا المحتوى حالياً.")
    
    # 3. حفظ النتيجة في الذاكرة المؤقتة
    cache[cache_key] = result
    logger.info(f"💾 Cached result for {cache_key}")
    
    return result
