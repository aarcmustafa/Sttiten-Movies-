import 'package:flutter/material.dart';
import '../../core/api_client.dart';
import '../../core/constants.dart';
import 'video_player_screen.dart';
import 'webview_screen.dart';

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
  String? _hlsUrl;
  List<String> _embedUrls = [];

  @override
  void initState() {
    super.initState();
    _fetchStream();
  }

  Future<void> _fetchStream() async {
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
      ).timeout(const Duration(seconds: 15));

      if (!mounted) return;

      if (response.data == null) throw 'بيانات فارغة من السيرفر';
      final type = response.data['type'] ?? 'embed';

      if (type == 'hls' && response.data['url'] != null) {
        _hlsUrl = response.data['url'];
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => VideoPlayerScreen(
                title: widget.title,
                videoUrl: _hlsUrl!,
              ),
            ),
          );
        }
      } else {
        final urls = response.data['urls'] as List<dynamic>? ?? [];
        if (urls.isEmpty) throw 'لا توجد مصادر متاحة';
        setState(() {
          _embedUrls = List<String>.from(urls);
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = 'تعذر جلب روابط المشاهدة. تحقق من اتصالك.';
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
                  Text('جاري البحث عن أفضل مصدر...', style: TextStyle(color: Colors.white70)),
                ],
              ),
            )
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, color: AppColors.error, size: 60),
                        const SizedBox(height: 16),
                        Text(_error!, style: const TextStyle(color: Colors.white, fontSize: 16), textAlign: TextAlign.center),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: _fetchStream,
                          icon: const Icon(Icons.refresh_rounded),
                          label: const Text('إعادة المحاولة'),
                        ),
                      ],
                    ),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _embedUrls.length,
                  itemBuilder: (context, index) {
                    final uri = Uri.parse(_embedUrls[index]);
                    final host = uri.host;
                    return Card(
                      color: AppColors.surfaceLight,
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: const Icon(Icons.play_circle_fill_rounded, color: AppColors.primary, size: 36),
                        title: Text('مصدر ${index + 1}: $host', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        subtitle: const Text('اضغط للتشغيل عبر المتصفح المدمج', style: TextStyle(color: AppColors.textTertiary, fontSize: 12)),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => WebViewScreen(
                                title: widget.title,
                                url: _embedUrls[index],
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
    );
  }
}
