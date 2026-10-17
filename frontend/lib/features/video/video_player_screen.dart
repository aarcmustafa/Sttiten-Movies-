import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../../../core/api_client.dart';
import '../../../core/constants.dart';

class VideoPlayerScreen extends StatefulWidget {
  final String title;
  final int tmdbId;
  final String mediaType;
  final int? seasonNumber;
  final int? episodeNumber;
  final String videoUrl;

  const VideoPlayerScreen({
    super.key,
    required this.title,
    required this.tmdbId,
    required this.mediaType,
    this.seasonNumber,
    this.episodeNumber,
    this.videoUrl = 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4',
  });

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  late VideoPlayerController _videoPlayerController;
  ChewieController? _chewieController;
  final ApiClient _api = ApiClient();

  bool _isLoadingSub = false;
  List<Subtitle> _subtitles = [];

  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  Future<void> _initializePlayer() async {
    _videoPlayerController = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl));
    await _videoPlayerController.initialize();

    _chewieController = ChewieController(
      videoPlayerController: _videoPlayerController,
      autoPlay: true,
      looping: false,
      aspectRatio: _videoPlayerController.value.aspectRatio,
      materialProgressColors: ChewieProgressColors(
        playedColor: AppColors.primary,
        handleColor: AppColors.primaryLight,
        backgroundColor: Colors.white24,
        bufferedColor: Colors.white54,
      ),
    );
    setState(() {});
  }

  Future<void> _enableArabicSubtitle() async {
    setState(() => _isLoadingSub = true);
    try {
      // 1. جلب قائمة الترجمات
      final data = await _api.searchSubtitles(
        tmdbId: widget.tmdbId, 
        mediaType: widget.mediaType,
        seasonNumber: widget.seasonNumber,
        episodeNumber: widget.episodeNumber,
      );
      final list = (data['data']?['subtitles'] as List<dynamic>? ?? []);
      if (list.isEmpty) throw 'لا توجد ترجمة متاحة';

      // 2. تحميل أول ترجمة
      final firstSubUrl = list.first['url'];
      final srtBytes = await _api.downloadSubtitle(subtitlePath: firstSubUrl);
      final srtText = String.fromCharCodes(srtBytes);

      // 3. تحويل SRT إلى List<Subtitle>
      final parsedSubs = _parseSrt(srtText);

      // 4. إعادة بناء مشغل الفيديو مع الترجمة
      _chewieController?.dispose();
      _chewieController = ChewieController(
        videoPlayerController: _videoPlayerController,
        autoPlay: true,
        looping: false,
        aspectRatio: _videoPlayerController.value.aspectRatio,
        subtitle: _SubtitleWrapper(parsedSubs), // ربط الترجمة
        materialProgressColors: ChewieProgressColors(
          playedColor: AppColors.primary,
          handleColor: AppColors.primaryLight,
          backgroundColor: Colors.white24,
          bufferedColor: Colors.white54,
        ),
      );
      setState(() => _subtitles = parsedSubs);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم تفعيل الترجمة العربية بنجاح'), backgroundColor: AppColors.success),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('فشل تحميل الترجمة: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoadingSub = false);
    }
  }

  // محرك تحويل ملف SRT إلى توقيتات
  List<Subtitle> _parseSrt(String srt) {
    final List<Subtitle> subs = [];
    final blocks = srt.trim().split(RegExp(r'\n\s*\n'));
    for (var block in blocks) {
      final lines = block.split('\n');
      if (lines.length >= 3) {
        final timeLine = lines[1].split(' --> ');
        if (timeLine.length == 2) {
          try {
            final start = _parseTime(timeLine[0]);
            final end = _parseTime(timeLine[1]);
            final text = lines.sublist(2).join('\n');
            subs.add(Subtitle(start, end, text));
          } catch (_) {}
        }
      }
    }
    return subs;
  }

  Duration _parseTime(String time) {
    final parts = time.replaceAll(',', '.').split(':');
    final secs = double.parse(parts[2]);
    return Duration(
      hours: int.parse(parts[0]),
      minutes: int.parse(parts[1]),
      seconds: secs.toInt(),
      milliseconds: ((secs % 1) * 1000).toInt(),
    );
  }

  @override
  void dispose() {
    _videoPlayerController.dispose();
    _chewieController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text(widget.title),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // مشغل الفيديو
          Expanded(
            child: Center(
              child: _chewieController != null && _chewieController!.videoPlayerController.value.isInitialized
                  ? AspectRatio(
                      aspectRatio: _videoPlayerController.value.aspectRatio,
                      child: Chewie(controller: _chewieController!),
                    )
                  : const CircularProgressIndicator(color: AppColors.primary),
            ),
          ),
          
          // شريط التحكم بالترجمة (تحت الفيديو)
          Container(
            padding: const EdgeInsets.all(16),
            color: AppColors.surface,
            child: SafeArea(
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _subtitles.isNotEmpty ? null : (_isLoadingSub ? null : _enableArabicSubtitle),
                  icon: _isLoadingSub 
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : Icon(_subtitles.isNotEmpty ? Icons.check_circle_rounded : Icons.subtitles_rounded),
                  label: Text(_subtitles.isNotEmpty ? 'الترجمة العربية مفعلة' : 'تفعيل الترجمة العربية'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _subtitles.isNotEmpty ? AppColors.success : AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// فئة مساعدة لربط الترجمة بـ Chewie
class _SubtitleWrapper extends ClosedCaptionFile {
  final List<Subtitle> _subs;
  _SubtitleWrapper(this._subs);

  @override
  List<ClosedCaption> get captions => []; // لا نحتاجه هنا
}
