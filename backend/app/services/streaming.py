import logging
import os
import asyncio
from typing import Optional, List, Dict
import httpx
import urllib.parse
import json

logger = logging.getLogger("sttiten.streaming")

CINEPRO_API_URL = os.getenv("CINEPRO_API_URL", "https://core-latest-hogs.onrender.com")


class StreamingService:
    def __init__(self):
        self.base_url = CINEPRO_API_URL.rstrip("/")
        self.timeout = httpx.Timeout(60.0, connect=10.0)
        self._client: Optional[httpx.AsyncClient] = None
        # مهلة فحص كل مصدر (2.5 ثانية كافية)
        self._validate_timeout = 2.5

    def _get_client(self) -> httpx.AsyncClient:
        """إعادة استخدام العميل (Connection Pooling + HTTP/2)"""
        if self._client is None or self._client.is_closed:
            self._client = httpx.AsyncClient(
                timeout=self.timeout,
                limits=httpx.Limits(
                    max_keepalive_connections=20,
                    max_connections=100,
                    keepalive_expiry=30.0,
                ),
                http2=True,
                follow_redirects=True,
            )
        return self._client

    async def _validate_source(self, source: Dict) -> bool:
        """
        يتحقق إذا كان رابط المصدر يعمل بإرسال طلب صغير (أول 2KB).
        يعيد True إذا استجاب بنجاح (200 أو 206).
        """
        try:
            headers = dict(source.get("headers") or {})
            headers["Range"] = "bytes=0-2047"  # فقط أول 2 كيلوبايت
            client = self._get_client()
            resp = await client.get(
                source["url"],
                headers=headers,
                timeout=self._validate_timeout,
            )
            return resp.status_code in (200, 206)
        except Exception as e:
            logger.debug(f"Source validation failed: {e}")
            return False

    async def _filter_alive_sources(self, sources: List[Dict]) -> List[Dict]:
        """
        يختبر كل المصادر في نفس الوقت (Parallel)، ويعيد فقط التي استجابت.
        """
        if not sources:
            return []
        
        results = await asyncio.gather(
            *[self._validate_source(s) for s in sources],
            return_exceptions=True,
        )
        
        alive = [s for s, ok in zip(sources, results) if ok is True]
        logger.info(f"✅ Source validation: {len(alive)}/{len(sources)} alive")
        
        # إذا فشلت جميع المصادر، نعيد القائمة الأصلية (حتى لا يبقى المستخدم بلا خيارات)
        return alive if alive else sources

    async def get_streams(
        self,
        tmdb_id: int,
        media_type: str = "movie",
        season: int = 1,
        episode: int = 1,
    ) -> Optional[dict]:
        if media_type == "tv":
            path = f"/v1/tv/{tmdb_id}/seasons/{season}/episodes/{episode}"
        else:
            path = f"/v1/movies/{tmdb_id}"

        url = f"{self.base_url}{path}"
        params = {"platform": "native"}

        try:
            client = self._get_client()
            resp = await client.get(url, params=params)
            resp.raise_for_status()
            data = resp.json()

            sources = data.get("sources") or []
            if not sources:
                return None

            fixed_sources = []
            for source in sources:
                stream_url = source.get("url")
                headers = source.get("headers") or {}
                if not stream_url:
                    continue

                # فك تشفير البروكسي لاستخراج الرابط المباشر
                if "/v1/proxy?data=" in stream_url:
                    try:
                        parsed = urllib.parse.urlparse(stream_url)
                        query_params = urllib.parse.parse_qs(parsed.query)
                        data_param = query_params.get("data", [""])[0]
                        decoded_data = urllib.parse.unquote(data_param)
                        proxy_data = json.loads(decoded_data)

                        if proxy_data.get("url"):
                            stream_url = proxy_data["url"]
                        if proxy_data.get("headers"):
                            headers = proxy_data["headers"]
                    except Exception as e:
                        logger.error(f"Proxy parse error: {e}")
                        stream_url = stream_url.replace(
                            "http://localhost:3000", self.base_url
                        )

                fixed_sources.append({
                    "url": stream_url,
                    "headers": headers,
                    "quality": source.get("quality", "HD"),
                    "provider": (
                        source.get("provider", {}).get("name", "Unknown")
                        if isinstance(source.get("provider"), dict)
                        else "Unknown"
                    ),
                })

            # إزالة التكرار
            unique_sources = []
            seen = set()
            for s in fixed_sources:
                key = f"{s['quality']}-{s['provider']}"
                if key not in seen:
                    seen.add(key)
                    unique_sources.append(s)

            # ✨ الخطوة الذهبية: فحص المصادر قبل إرسالها
            alive_sources = await self._filter_alive_sources(unique_sources)

            return {"sources": alive_sources}

        except Exception as e:
            logger.error(f"CinePro error: {e}")
            return None

    async def close(self):
        """إغلاق العميل عند إيقاف السيرفر"""
        if self._client and not self._client.is_closed:
            await self._client.aclose()


streaming_service = StreamingService()
