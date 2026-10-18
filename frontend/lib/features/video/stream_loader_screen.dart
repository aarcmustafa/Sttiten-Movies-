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
  List<Map<String, dynamic>> _sources = [];

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
      ).timeout(const Duration(seconds: 60));

      if (!mounted) return;
      final sources = response.data['sources'] as List<dynamic>? ?? [];
      
      if (sources.isEmpty) throw 'لا توجد جودات متاحة';

      setState(() {
        _sources = sources.cast<Map<String, dynamic>>();
        _loading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = 'تعذر جلب الجودات. تحقق من اتصالك أو جرب فيلماً آخر.';
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
                  Text('جاري جلب الجودات المتاحة...', style: TextStyle(color: Colors.white70)),
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
                        ElevatedButton.icon(onPressed: _load, icon: const Icon(Icons.refresh_rounded), label: const Text('إعادة المحاولة')),
                      ],
                    ),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _sources.length,
                  itemBuilder: (context, index) {
                    final source = _sources[index];
                    final quality = source['quality'] ?? 'HD';
                    final provider = source['provider'] ?? 'مصدر';
                    final url = source['url'] as String;
                    final headers = (source['headers'] as Map<String, dynamic>?)?.map((k, v) => MapEntry(k.toString(), v.toString())) ?? {};

                    return Card(
                      color: AppColors.surfaceLight,
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: const Icon(Icons.play_circle_fill_rounded, color: AppColors.primary, size: 36),
                        title: Text('جودة: $quality', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        subtitle: Text('المزود: $provider', style: const TextStyle(color: AppColors.textTertiary, fontSize: 12)),
                        trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white54, size: 16),
                        onTap: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (_) => VideoPlayerScreen(
                                title: widget.title,
                                videoUrl: url,
                                headers: headers,
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
