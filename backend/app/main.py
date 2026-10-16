"""
نقطة انطلاق تطبيق Sttiten Movies
"""
import logging
from contextlib import asynccontextmanager

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse

from app.config import settings

# ============ Logging ============
logging.basicConfig(
    level=logging.DEBUG if settings.DEBUG else logging.INFO,
    format="%(asctime)s | %(levelname)-8s | %(name)s | %(message)s",
)
logger = logging.getLogger("sttiten")


# ============ Lifespan ============
@asynccontextmanager
async def lifespan(app: FastAPI):
    """يعمل عند بدء وإيقاف التطبيق"""
    logger.info(f"🎬 Starting {settings.APP_NAME} [{settings.APP_ENV}]")

    # التحقق من المفاتيح (تحذير فقط، لا يوقف التطبيق)
    if not settings.TMDB_API_KEY:
        logger.warning("⚠️  TMDB_API_KEY غير مضبوط — بيانات الأفلام لن تعمل")
    else:
        logger.info("✅ TMDB_API_KEY مضبوط")

    if not settings.SUBDL_API_KEY:
        logger.warning("⚠️  SUBDL_API_KEY غير مضبوط — الترجمات العربية لن تعمل (يمكنك التسجيل لاحقًا)")
    else:
        logger.info("✅ SUBDL_API_KEY مضبوط")

    if not settings.OPENSUBTITLES_API_KEY:
        logger.warning("⚠️  OPENSUBTITLES_API_KEY غير مضبوط — الترجمات الاحتياطية لن تعمل")
    else:
        logger.info("✅ OPENSUBTITLES_API_KEY مضبوط")

    yield

    logger.info(f"🛑 Shutting down {settings.APP_NAME}")


# ============ FastAPI App ============
app = FastAPI(
    title=settings.APP_NAME,
    description="🎬 API لمشاهدة الأفلام والمسلسلات مع دعم الترجمة العربية",
    version="0.1.0",
    docs_url="/docs",
    redoc_url="/redoc",
    openapi_url="/openapi.json",
    lifespan=lifespan,
)


# ============ CORS Middleware ============
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.CORS_ORIGINS,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


# ============ Root Endpoints ============
@app.get("/", tags=["Root"])
async def root():
    """الصفحة الرئيسية"""
    return {
        "app": settings.APP_NAME,
        "version": "0.1.0",
        "status": "running",
        "docs": "/docs",
        "api": settings.API_V1_PREFIX,
    }


@app.get("/health", tags=["Root"])
async def health():
    """فحص الحالة (يُستخدم من Docker healthcheck)"""
    return {"status": "healthy"}


# ============ Exception Handlers ============
@app.exception_handler(Exception)
async def global_exception_handler(request, exc):
    """معالج استثناءات عام"""
    logger.error(f"❌ Unhandled error: {exc}", exc_info=True)
    return JSONResponse(
        status_code=500,
        content={"detail": "حدث خطأ داخلي في الخادم"},
)
