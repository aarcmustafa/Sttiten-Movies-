from sqlalchemy import Column, Integer, String, DateTime
from datetime import datetime
from app.database import Base

class Favorite(Base):
    __tablename__ = "favorites"

    id = Column(Integer, primary_key=True, index=True)
    device_id = Column(String, index=True, nullable=False)
    tmdb_id = Column(Integer, nullable=False)
    media_type = Column(String, nullable=False)
    title = Column(String, nullable=False)
    poster_path = Column(String, nullable=True)
    created_at = Column(DateTime, default=datetime.utcnow)
