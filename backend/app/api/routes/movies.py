from typing import Optional
from fastapi import APIRouter, HTTPException, Query
from app.services.tmdb import tmdb_service, TMDBError

router = APIRouter(prefix="/movies", tags=["Movies"])


@router.get("/popular")
async def get_popular_movies(
    page: int = Query(1, ge=1, le=500),
    language: Optional[str] = Query("ar", description="كود اللغة مثل ar أو en"),
):
    """الأفلام الشائعة"""
    try:
        data = await tmdb_service.get_popular_movies(page=page, language=language)
        return {
            "page": data.get("page"),
            "total_pages": data.get("total_pages"),
            "total_results": data.get("total_results"),
            "results": data.get("results", []),
        }
    except TMDBError as e:
        raise HTTPException(status_code=502, detail=str(e))


@router.get("/trending")
async def get_trending_movies(
    time_window: str = Query("week", pattern="^(day|week)$"),
):
    """الأفلام الأكثر رواجًا"""
    try:
        data = await tmdb_service.get_trending_movies(time_window=time_window)
        return {"results": data.get("results", [])}
    except TMDBError as e:
        raise HTTPException(status_code=502, detail=str(e))


@router.get("/top-rated")
async def get_top_rated_movies(page: int = Query(1, ge=1, le=500)):
    """الأفلام الأعلى تقييمًا"""
    try:
        data = await tmdb_service.get_top_rated_movies(page=page)
        return {
            "page": data.get("page"),
            "total_pages": data.get("total_pages"),
            "results": data.get("results", []),
        }
    except TMDBError as e:
        raise HTTPException(status_code=502, detail=str(e))


@router.get("/search")
async def search_movies(
    q: str = Query(..., min_length=1, description="كلمة البحث"),
    page: int = Query(1, ge=1, le=500),
):
    """البحث عن فيلم"""
    try:
        data = await tmdb_service.search_movies(query=q, page=page)
        return {
            "page": data.get("page"),
            "total_results": data.get("total_results"),
            "results": data.get("results", []),
        }
    except TMDBError as e:
        raise HTTPException(status_code=502, detail=str(e))


@router.get("/{movie_id}")
async def get_movie_details(movie_id: int):
    """تفاصيل فيلم كاملة"""
    try:
        data = await tmdb_service.get_movie_details(movie_id=movie_id)
        return data
    except TMDBError as e:
        raise HTTPException(status_code=502, detail=str(e))
