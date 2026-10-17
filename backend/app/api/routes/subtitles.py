from typing import Optional
from fastapi import APIRouter, HTTPException, Query
from fastapi.responses import Response
from pydantic import BaseModel
import zipfile
import io
from app.services.subdl import subdl_service, SubDLError
from app.services.opensubtitles import opensubtitles_service, OpenSubtitlesError

router = APIRouter(prefix="/subtitles", tags=["Subtitles"])

class DownloadRequest(BaseModel):
    subtitle_path: str
    filename: Optional[str] = None

@router.get("/search")
async def search_subtitles(
    tmdb_id: int = Query(...),
    media_type: str = Query("movie", pattern="^(movie|tv)$"),
    language: str = Query("AR"),
    season_number: Optional[int] = Query(None, ge=1),
    episode_number: Optional[int] = Query(None, ge=1),
):
    try:
        data = await subdl_service.search_subtitles(
            tmdb_id=tmdb_id, media_type=media_type, language=language,
            season_number=season_number, episode_number=episode_number,
        )
        for sub in data.get("subtitles", []):
            if "url" in sub and isinstance(sub["url"], str):
                sub["url"] = sub["url"].split("?")[0]
        return {"source": "subdl", "data": data}
    except SubDLError as e:
        raise HTTPException(status_code=502, detail=str(e))

@router.get("/search-opensubtitles")
async def search_opensubtitles(
    tmdb_id: int = Query(...),
    media_type: str = Query("movie", pattern="^(movie|tv)$"),
    language: str = Query("ar"),
    season_number: Optional[int] = Query(None, ge=1),
    episode_number: Optional[int] = Query(None, ge=1),
):
    try:
        data = await opensubtitles_service.search_subtitles(
            tmdb_id=tmdb_id, media_type=media_type, languages=language,
            season_number=season_number, episode_number=episode_number,
        )
        return {"source": "opensubtitles", "data": data}
    except OpenSubtitlesError as e:
        raise HTTPException(status_code=502, detail=str(e))

@router.post("/download")
async def download_subtitle(request: DownloadRequest):
    try:
        content = await subdl_service.download_subtitle(request.subtitle_path)
        
        # محاولة فك ضغط الملف إذا كان ZIP لاستخراج ملف الـ SRT
        try:
            with zipfile.ZipFile(io.BytesIO(content)) as z:
                for filename in z.namelist():
                    if filename.endswith('.srt'):
                        srt_content = z.read(filename)
                        return Response(
                            content=srt_content.decode('utf-8', errors='ignore'),
                            media_type="text/plain; charset=utf-8"
                        )
        except zipfile.BadZipFile:
            # إذا لم يكن ZIP، نرجعه كما هو
            return Response(content=content.decode('utf-8', errors='ignore'), media_type="text/plain; charset=utf-8")
            
        raise HTTPException(status_code=404, detail="لم يتم العثور على ملف SRT داخل الملف المضغوط")
    except SubDLError as e:
        raise HTTPException(status_code=502, detail=str(e))
