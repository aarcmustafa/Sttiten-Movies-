from typing import Optional
from fastapi import APIRouter, HTTPException, Query, Body
from fastapi.responses import Response
from pydantic import BaseModel
from app.services.subdl import subdl_service, SubDLError
from app.services.opensubtitles import opensubtitles_service, OpenSubtitlesError

router = APIRouter(prefix="/subtitles", tags=["Subtitles"])


class DownloadRequest(BaseModel):
    subtitle_path: str
    filename: Optional[str] = None


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
        # نُنظّف الروابط من المفتاح قبل إرسالها للعميل
        subtitles = data.get("subtitles", [])
        for sub in subtitles:
            if "url" in sub and isinstance(sub["url"], str):
                sub["url"] = sub["url"].split("?")[0]
        data["subtitles"] = subtitles
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


@router.post("/download")
async def download_subtitle(request: DownloadRequest):
    """
    يُحمّل ملف الترجمة عبر الخادم دون كشف المفتاح للعميل.
    Body: {"subtitle_path": "/subtitle/3443533-8366101.zip"}
    """
    try:
        content = await subdl_service.download_subtitle(request.subtitle_path)
        filename = request.filename or "subtitle.zip"
        return Response(
            content=content,
            media_type="application/zip",
            headers={
                "Content-Disposition": f'attachment; filename="{filename}"',
            },
        )
    except SubDLError as e:
        raise HTTPException(status_code=502, detail=str(e))
