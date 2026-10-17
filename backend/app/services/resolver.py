import logging
import asyncio
import subprocess
import json
from typing import Optional

logger = logging.getLogger("sttiten.resolver")

class VidsrcResolver:
    async def get_hls_url(self, tmdb_id: int, media_type: str = "movie", season: int = 1, episode: int = 1) -> Optional[str]:
        """
        يستخدم مكتبة vidsrc-dlp لاستخراج رابط HLS (m3u8) النهائي.
        """
        try:
            # بناء الأمر لاستدعاء vidsrc-dlp
            # نفترض أن الأمر متاح كـ moviefinder (من وثائق المكتبة)
            if media_type == "tv":
                cmd = [
                    "moviefinder", 
                    str(tmdb_id), 
                    "--type", "tv", 
                    "--season", str(season), 
                    "--episode", str(episode),
                    "--json" # نفترض أنه يدعم إخراج JSON
                ]
            else:
                cmd = [
                    "moviefinder", 
                    str(tmdb_id), 
                    "--json"
                ]

            # تنفيذ الأمر في بيئة منفصلة (Subprocess)
            process = await asyncio.create_subprocess_exec(
                *cmd,
                stdout=asyncio.subprocess.PIPE,
                stderr=asyncio.subprocess.PIPE
            )

            stdout, stderr = await process.communicate()

            if process.returncode != 0:
                logger.error(f"vidsrc-dlp error: {stderr.decode()}")
                return None

            # تحليل الناتج (نفترض أنه JSON يحتوي على hls_url)
            output = stdout.decode()
            logger.info(f"vidsrc-dlp output: {output[:200]}...")
            
            # محاولة استخراج الرابط من الناتج
            # قد يكون الناتج نصاً مباشراً أو JSON
            try:
                data = json.loads(output)
                hls_url = data.get("hls_url") or data.get("url") or data.get("stream_url")
                if hls_url:
                    return hls_url
            except json.JSONDecodeError:
                # إذا لم يكن JSON، قد يكون الرابط مباشرة في النص
                lines = [line.strip() for line in output.split('\n') if 'm3u8' in line]
                if lines:
                    return lines[0]

            return None

        except Exception as e:
            logger.error(f"Resolver error: {e}")
            return None

resolver_service = VidsrcResolver()
