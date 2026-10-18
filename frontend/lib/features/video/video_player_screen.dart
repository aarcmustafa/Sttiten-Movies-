import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_vlc_player/flutter_vlc_player.dart';
import '../../core/constants.dart';

class VideoPlayerScreen extends StatefulWidget {
  final String title;
  final String videoUrl;
  final Map<String, String>? headers;
  final int? tmdbId;
  final String? mediaType;
  final int? seasonNumber;
  final int? episodeNumber;

  const VideoPlayerScreen({
    super.key,
    required this.title,
    required this.videoUrl,
    this.headers,
    this.tmdbId,
    this.mediaType,
    this.seasonNumber,
    this.episodeNumber,
  });

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  late VlcPlayerController _vlcController;
  bool _hasError = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    _initializePlayer();
  }

  void _initializePlayer() {
    _vlcController = VlcPlayerController.network(
      widget.videoUrl,
      hwAcc: HwAcc.disabled,
      autoPlay: true,
      options: VlcPlayerOptions(
        advanced: VlcAdvancedOptions([
          // تقليل زمن التخزين المؤقت إلى 500 مللي ثانية لبدء أسرع
          VlcAdvancedOptions.networkCaching(500),
        ]),
      ),
    );

    _vlcController.addListener(() {
      if (!mounted) return;
      if (_vlcController.value.isInitialized) {
        _vlcController.setVolume(100);
      }
      if (_vlcController.value.hasError && !_hasError) {
        setState(() {
          _hasError = true;
          _errorMessage = _vlcController.value.errorDescription ?? 'خطأ غير معروف';
        });
      }
    });
  }

  // إعادة المحاولة مع زمن تخزين مؤقت أعلى (في حال كان الإنترنت بطيئاً)
  void _retryWithHighCache() {
    setState(() {
      _hasError = false;
      _errorMessage = '';
    });
    _vlcController.dispose();
    _vlcController = VlcPlayerController.network(
      widget.videoUrl,
      hwAcc: HwAcc.disabled,
      autoPlay: true,
      options: VlcPlayerOptions(
        advanced: VlcAdvancedOptions([
          // زيادة الكاش إلى 2000 مللي ثانية إذا كان الفيديو يتقطع
          VlcAdvancedOptions.networkCaching(2000),
        ]),
      ),
    );
    _vlcController.addListener(() {
      if (!mounted) return;
      if (_vlcController.value.isInitialized) {
        _vlcController.setVolume(100);
      }
      if (_vlcController.value.hasError && !_hasError) {
        setState(() {
          _hasError = true;
          _errorMessage = _vlcController.value.errorDescription ?? 'خطأ غير معروف';
        });
      }
    });
    setState(() {});
  }

  @override
  void dispose() {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    _vlcController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black.withOpacity(0.5),
        title: Text(widget.title, style: const TextStyle(fontSize: 14)),
        actions: [
          IconButton(
            icon: const Icon(Icons.replay_rounded),
            tooltip: 'إعادة التشغيل',
            onPressed: () {
              _vlcController.seekTo(const Duration(seconds: 0));
              _vlcController.play();
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings_ethernet_rounded),
            tooltip: 'تقليل التقطيع (زيادة الكاش)',
            onPressed: _retryWithHighCache,
          ),
        ],
      ),
      body: ValueListenableBuilder<VlcPlayerValue>(
        valueListenable: _vlcController,
        builder: (context, value, _) {
          if (_hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline, color: AppColors.error, size: 64),
                    const SizedBox(height: 16),
                    const Text(
                      'تعذر تشغيل الفيديو',
                      style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _errorMessage,
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: _retryWithHighCache,
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text('إعادة المحاولة (كاش أعلى)'),
                    ),
                  ],
                ),
              ),
            );
          }

          if (!value.isInitialized) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: AppColors.primary),
                  SizedBox(height: 16),
                  Text('جاري تشغيل الفيديو...', style: TextStyle(color: Colors.white70)),
                ],
              ),
            );
          }

          final aspect = (value.aspectRatio > 0 && value.aspectRatio.isFinite)
              ? value.aspectRatio
              : 16 / 9;

          return Center(
            child: AspectRatio(
              aspectRatio: aspect,
              child: VlcPlayer(
                controller: _vlcController,
                aspectRatio: aspect,
                placeholder: const Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
