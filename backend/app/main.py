import logging
from contextlib import asynccontextmanager
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from app.config import settings

logging.basicConfig(
    level=logging.DEBUG if settings.DEBUG else logging.INFO,
    format="%(asctime)s | %(levelname)-8s | %(name)s | %(message)s",
)
logger = logging.getLogger("sttiten")


@asynccontextmanager
async def lifespan(app: FastAPI):
    logger.info(f"Starting {settings.APP_NAME}")
    if settings.TMDB_API_KEY:
        logger.info("TMDB_API_KEY set")
    else:
        logger.warning("TMDB_API_KEY missing")
    if settings.SUBDL_API_KEY:
        logger.info("SUBDL_API_KEY set")
    else:
        logger.warning("SUBDL_API_KEY missing")
    if settings.OPENSUBTITLES_API_KEY:
        logger.info("OPENSUBTITLES_API_KEY set")
    else:
        logger.warning("OPENSUBTITLES_API_KEY missing")
    yield
    logger.info("Shutting down")


app = FastAPI(
    title=settings.APP_NAME,
    description="API for Sttiten Movies - Arabic movie & series data",
    version="0.2.0",
    docs_url="/docs",
    redoc_url="/redoc",
    lifespan=lifespan,
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.CORS_ORIGINS,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

from app.api.routes import movies, series, subtitles

app.include_router(movies.router, prefix=settings.API_V1_PREFIX)
app.include_router(series.router, prefix=settings.API_V1_PREFIX)
app.include_router(subtitles.router, prefix=settings.API_V1_PREFIX)


@app.get("/", tags=["Root"])
async def root():
    return {
        "app": settings.APP_NAME,
        "version": "0.2.0",
        "status": "running",
        "docs": "/docs",
    }


@app.get("/health", tags=["Root"])
async def health():
    return {"status": "healthy"}


@app.exception_handler(Exception)
async def global_exception_handler(request, exc):
    logger.error(f"Unhandled error: {exc}", exc_info=True)
    return JSONResponse(status_code=500, content={"detail": "Internal server error"})
