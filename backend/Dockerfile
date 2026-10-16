# ============ Base Image ============
FROM python:3.11-slim AS base

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1 \
    PIP_DISABLE_PIP_VERSION_CHECK=1

WORKDIR /app

# ============ System Dependencies ============
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    curl \
    libpq-dev \
    && rm -rf /var/lib/apt/lists/*

# ============ Python Dependencies ============
COPY requirements.txt .
RUN pip install --upgrade pip && pip install -r requirements.txt

# ============ Application Code ============
COPY . .

# ============ Non-root User ============
RUN useradd -m -u 1000 sttiten && chown -R sttiten:sttiten /app
USER sttiten

# ============ Hugging Face Port ============
EXPOSE 7860

# ============ Healthcheck ============
HEALTHCHECK --interval=30s --timeout=5s --start-period=20s --retries=3 \
    CMD curl -f http://localhost:7860/health || exit 1

# ============ Run ============
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "7860"]
