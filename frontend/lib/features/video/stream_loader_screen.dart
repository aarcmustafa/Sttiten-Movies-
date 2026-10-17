import 'package:flutter/material.dart';
import '../../core/api_client.dart';
import '../../core/constants.dart';
import 'video_player_screen.dart';

class StreamLoaderScreen extends StatefulWidget {
  final int tmdbId;
  final String title;
  final String mediaType;
  final int season;
  final int episode;

  const StreamLoaderScreen({
    super.key,
    required this.tmdbId,
    required this.title,
    required this.mediaType,
    this.season = 1,
    this.episode = 1,
  });

  @override
  State<StreamLoaderScreen> createState() => _StreamLoaderScreenState();
}

class _StreamLoaderScreenState extends State<StreamLoaderScreen> {
  final _api = ApiClient();
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final response = await _api.dio.get(
        '${ApiConstants.apiPrefix}/stream/${widget.tmdbId}',
        queryParameters: {
          'media_type': widget.mediaType,
          'season': widget.season,
          'episode': widget.episode,
        },
      ).timeout(const Duration(seconds: 30));

      if (!mounted) return;

      final url = response.data['url'] as String?;
      final headers = response.data['headers'] as Map<String, dynamic>? ?? {};

      if (url == null || url.isEmpty) {
        throw 'لا توجد روابط متاحة';
      }

      // تحويل الترويسات إلى Map<String, String>
      final Map<String, String> stringHeaders = headers.map(
        (key, value) => MapEntry(key.toString(), value.toString()),
      );

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => VideoPlayerScreen(
              title: widget.title,
              videoUrl: url,
              headers: stringHeaders,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = 'تعذر جلب رابط المشاهدة. قد يكون المحتوى غير متوفر حالياً.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text(widget.title)),
      body: _loading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: AppColors.primary),
                  SizedBox(height: 20),
                  Text('جاري البحث عن أفضل جودة...', style: TextStyle(color: Colors.white70)),
                ],
              ),
            )
          : Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline, color: AppColors.error, size: 64),
                    const SizedBox(height: 16),
                    Text(_error!, style: const TextStyle(color: Colors.white, fontSize: 16), textAlign: TextAlign.center),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: _load,
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text('إعادة المحاولة'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
