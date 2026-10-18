import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_vlc_player/flutter_vlc_player.dart';
import '../../core/constants.dart';

class VideoPlayerScreen extends StatefulWidget {
  final String title;
  final String videoUrl;
  final Map<String, String>? headers;

  const VideoPlayerScreen({
    super.key,
    required this.title,
    required this.videoUrl,
    this.headers,
  });

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  late VlcPlayerController _vlcController;
  bool _hasError = false;
  String _errorMessage = '';
  Timer? _initTimeout;

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
    // استخراج الترويسات وتمريرها بأسلوب VLC CLI
    final referer = widget.headers?['Referer'] ?? widget.headers?['referer'] ?? 'https://brightpathsignals.com/';
    final userAgent = widget.headers?['User-Agent'] ?? widget.headers?['user-agent'] ?? 'Mozilla/5.0 (Linux; Android 13) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0.0.0 Mobile Safari/537.36';

    _vlcController = VlcPlayerController.network(
      widget.videoUrl,
      hwAcc: HwAcc.full, // التسريع العتادي مهم جداً لمنع تقطيع الصورة
      autoPlay: true,
      options: VlcPlayerOptions(
        advanced: VlcAdvancedOptions([
          '--network-caching=1500',
          '--http-referrer=$referer',
          '--http-user-agent=$userAgent',
        ]),
      ),
    );

    // مهلة التهيئة (إذا لم يعمل الفيديو خلال 15 ثانية نعتبره فشل)
    _initTimeout = Timer(const Duration(seconds: 15), () {
      if (mounted && !_vlcController.value.isInitialized && !_hasError) {
        setState(() {
          _hasError = true;
          _errorMessage = 'استغرق التحميل وقتاً طويلاً. قد يكون الرابط محمياً.';
        });
      }
    });

    _vlcController.addListener(() {
      if (!mounted) return;
      if (_vlcController.value.isInitialized) {
        _initTimeout?.cancel();
        _vlcController.setVolume(100);
      }
      if (_vlcController.value.hasError && !_hasError) {
        _initTimeout?.cancel();
        setState(() {
          _hasError = true;
          _errorMessage = _vlcController.value.errorDescription ?? 'خطأ غير معروف';
        });
      }
    });
  }

  @override
  void dispose() {
    _initTimeout?.cancel();
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
            onPressed: () {
              _vlcController.seekTo(const Duration(seconds: 0));
              _vlcController.play();
            },
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
                    const Text('تعذر تشغيل الفيديو', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text(_errorMessage, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12), textAlign: TextAlign.center),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back_rounded),
                      label: const Text('العودة لاختيار جودة أخرى'),
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

          final aspect = (value.aspectRatio > 0 && value.aspectRatio.isFinite) ? value.aspectRatio : 16 / 9;
          return Center(
            child: AspectRatio(
              aspectRatio: aspect,
              child: VlcPlayer(
                controller: _vlcController,
                aspectRatio: aspect,
                placeholder: const Center(child: CircularProgressIndicator(color: AppColors.primary)),
              ),
            ),
          );
        },
      ),
    );
  }
}
