import logging
from contextlib import asynccontextmanager
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from app.config import settings
from app.database import engine, Base

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger("sttiten")


@asynccontextmanager
async def lifespan(app: FastAPI):
    logger.info(f"Starting {settings.APP_NAME}")
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)
    logger.info("Database tables created/verified.")
    yield
    logger.info("Shutting down")


app = FastAPI(
    title=settings.APP_NAME,
    description="API for Sttiten Movies",
    version="0.4.0",
    docs_url="/docs",
    lifespan=lifespan,
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# استدعاء جميع المسارات
from app.api.routes import movies, series, subtitles, favorites, person, streaming

app.include_router(movies.router, prefix=settings.API_V1_PREFIX)
app.include_router(series.router, prefix=settings.API_V1_PREFIX)
app.include_router(subtitles.router, prefix=settings.API_V1_PREFIX)
app.include_router(favorites.router, prefix=settings.API_V1_PREFIX)
app.include_router(person.router, prefix=settings.API_V1_PREFIX)
app.include_router(streaming.router, prefix=settings.API_V1_PREFIX)

@app.get("/", tags=["Root"])
async def root():
    return {"app": settings.APP_NAME, "version": "0.4.0", "status": "running"}

@app.get("/health", tags=["Root"])
async def health():
    return {"status": "healthy"}
