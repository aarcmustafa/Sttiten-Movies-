from fastapi import APIRouter, HTTPException
from app.services.tmdb import tmdb_service, TMDBError

router = APIRouter(prefix="/person", tags=["Person"])

@router.get("/{person_id}")
async def get_person_details(person_id: int):
    """بيانات الممثل وسيرته الذاتية"""
    try:
        data = await tmdb_service._get(f"person/{person_id}", append_to_response="movie_credits,tv_credits")
        return data
    except TMDBError as e:
        raise HTTPException(status_code=502, detail=str(e))
