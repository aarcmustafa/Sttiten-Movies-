from typing import Optional
from fastapi import APIRouter, HTTPException, Query
from app.services.subdl import subdl_service, SubDLError
from app.services.opensubtitles import opensubtitles_service, OpenSubtitlesError

router = APIRouter(prefix="/subtitles", tags=["Subtitles"])


@router.get("/search")
async def search_subtitles(
    tmdb_id: int = Query(..., description="معرف TMDB للفيلم أو المسلسل"),
    media_type: str = Query("movie", pattern="^(movie|tv)$"),
    language: str = Query("AR", description="كود اللغة: AR للعربية"),
    season_number: Optional[int] = Query(None, ge=1),
    episode_number: Optional[int] = Query(None, ge=1),
):
    """البحث عن ترجمات عربية عبر SubDL"""
    try:
        data = await subdl_service.search_subtitles(
            tmdb_id=tmdb_id,
            media_type=media_type,
            language=language,
            season_number=season_number,
            episode_number=episode_number,
        )
        return {
            "source": "subdl",
            "tmdb_id": tmdb_id,
            "media_type": media_type,
            "language": language,
            "data": data,
        }
    except SubDLError as e:
        raise HTTPException(status_code=502, detail=str(e))


@router.get("/search-opensubtitles")
async def search_opensubtitles(
    tmdb_id: int = Query(..., description="معرف TMDB"),
    media_type: str = Query("movie", pattern="^(movie|tv)$"),
    language: str = Query("ar"),
    season_number: Optional[int] = Query(None, ge=1),
    episode_number: Optional[int] = Query(None, ge=1),
):
    """البحث عن ترجمات عبر OpenSubtitles (احتياطي)"""
    try:
        data = await opensubtitles_service.search_subtitles(
            tmdb_id=tmdb_id,
            media_type=media_type,
            languages=language,
            season_number=season_number,
            episode_number=episode_number,
        )
        return {
            "source": "opensubtitles",
            "tmdb_id": tmdb_id,
            "media_type": media_type,
            "language": language,
            "data": data,
        }
    except OpenSubtitlesError as e:
        raise HTTPException(status_code=502, detail=str(e))
