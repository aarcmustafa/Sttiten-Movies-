from fastapi import APIRouter, Depends, HTTPException, Header
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.future import select
from typing import List, Optional
from pydantic import BaseModel

from app.database import get_db
from app.models.favorite import Favorite

router = APIRouter(prefix="/favorites", tags=["Favorites"])

class FavoriteCreate(BaseModel):
    tmdb_id: int
    media_type: str
    title: str
    poster_path: Optional[str] = None

class FavoriteResponse(FavoriteCreate):
    id: int

    class Config:
        from_attributes = True


@router.get("/", response_model=List[FavoriteResponse])
async def get_favorites(
    x_device_id: str = Header(..., alias="X-Device-ID"),
    db: AsyncSession = Depends(get_db)
):
    result = await db.execute(
        select(Favorite).where(Favorite.device_id == x_device_id).order_by(Favorite.created_at.desc())
    )
    return result.scalars().all()


@router.post("/", response_model=FavoriteResponse)
async def add_favorite(
    fav: FavoriteCreate,
    x_device_id: str = Header(..., alias="X-Device-ID"),
    db: AsyncSession = Depends(get_db)
):
    existing = await db.execute(
        select(Favorite).where(
            Favorite.device_id == x_device_id,
            Favorite.tmdb_id == fav.tmdb_id,
            Favorite.media_type == fav.media_type
        )
    )
    if existing.scalars().first():
        raise HTTPException(status_code=400, detail="العنصر موجود بالفعل في المفضلة")

    new_fav = Favorite(
        device_id=x_device_id,
        tmdb_id=fav.tmdb_id,
        media_type=fav.media_type,
        title=fav.title,
        poster_path=fav.poster_path
    )
    db.add(new_fav)
    await db.commit()
    await db.refresh(new_fav)
    return new_fav


@router.delete("/{tmdb_id}")
async def remove_favorite(
    tmdb_id: int,
    media_type: str,
    x_device_id: str = Header(..., alias="X-Device-ID"),
    db: AsyncSession = Depends(get_db)
):
    result = await db.execute(
        select(Favorite).where(
            Favorite.device_id == x_device_id,
            Favorite.tmdb_id == tmdb_id,
            Favorite.media_type == media_type
        )
    )
    fav = result.scalars().first()
    if not fav:
        raise HTTPException(status_code=404, detail="العنصر غير موجود")
    
    await db.delete(fav)
    await db.commit()
    return {"status": "success", "message": "تم الحذف"}
