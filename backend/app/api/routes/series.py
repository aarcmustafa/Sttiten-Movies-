from fastapi import APIRouter, HTTPException, Query
from app.services.tmdb import tmdb_service, TMDBError

router = APIRouter(prefix="/series", tags=["Series"])

@router.get("/popular")
async def get_popular_series(page: int = Query(1, ge=1, le=500)):
    try:
        data = await tmdb_service.get_popular_series(page=page)
        return {"page": data.get("page"), "results": data.get("results", [])}
    except TMDBError as e:
        raise HTTPException(status_code=502, detail=str(e))

@router.get("/trending")
async def get_trending_series(time_window: str = Query("week", pattern="^(day|week)$")):
    try:
        data = await tmdb_service.get_trending_series(time_window=time_window)
        return {"results": data.get("results", [])}
    except TMDBError as e:
        raise HTTPException(status_code=502, detail=str(e))

@router.get("/search")
async def search_series(q: str = Query(..., min_length=1), page: int = Query(1, ge=1, le=500)):
    try:
        data = await tmdb_service.search_series(query=q, page=page)
        return {"page": data.get("page"), "results": data.get("results", [])}
    except TMDBError as e:
        raise HTTPException(status_code=502, detail=str(e))

@router.get("/turkish")
async def get_turkish_series(page: int = Query(1, ge=1)):
    try:
        data = await tmdb_service.discover_series_by_language(language_code="tr", page=page)
        return {"page": data.get("page"), "results": data.get("results", [])}
    except TMDBError as e:
        raise HTTPException(status_code=502, detail=str(e))

@router.get("/indian")
async def get_indian_series(page: int = Query(1, ge=1)):
    try:
        data = await tmdb_service.discover_series_by_language(language_code="hi", page=page)
        return {"page": data.get("page"), "results": data.get("results", [])}
    except TMDBError as e:
        raise HTTPException(status_code=502, detail=str(e))

@router.get("/{series_id}/seasons/{season_number}")
async def get_season_details(series_id: int, season_number: int):
    try:
        data = await tmdb_service.get_season_details(series_id=series_id, season_number=season_number)
        return data
    except TMDBError as e:
        raise HTTPException(status_code=502, detail=str(e))

@router.get("/{series_id}")
async def get_series_details(series_id: int):
    try:
        data = await tmdb_service.get_series_details(series_id=series_id)
        return data
    except TMDBError as e:
        raise HTTPException(status_code=502, detail=str(e))
