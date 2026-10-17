import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../../core/api_client.dart';
import '../../../core/constants.dart';
import '../../../shared/widgets/loading_indicator.dart';
import '../../video/stream_loader_screen.dart';

class EpisodesScreen extends StatefulWidget {
  final int seriesId;
  final int seasonNumber;
  final String seasonName;
  final String seriesTitle;

  const EpisodesScreen({
    super.key,
    required this.seriesId,
    required this.seasonNumber,
    required this.seasonName,
    required this.seriesTitle,
  });

  @override
  State<EpisodesScreen> createState() => _EpisodesScreenState();
}

class _EpisodesScreenState extends State<EpisodesScreen> {
  final _api = ApiClient();
  List<dynamic> _episodes = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final data = await _api.dio.get('${ApiConstants.apiPrefix}/series/${widget.seriesId}/seasons/${widget.seasonNumber}');
      setState(() {
        _episodes = data.data['episodes'] ?? [];
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text('${widget.seriesTitle} - ${widget.seasonName}')),
      body: _loading
          ? const AppLoader()
          : _episodes.isEmpty
              ? const EmptyState(title: 'لا توجد حلقات', subtitle: 'لم يتم العثور على حلقات لهذا الموسم')
              : ListView.builder(
                  padding: const EdgeInsets.all(AppSizes.paddingM),
                  itemCount: _episodes.length,
                  itemBuilder: (context, index) {
                    final ep = _episodes[index];
                    final epNum = ep['episode_number'] ?? 0;
                    final name = ep['name'] ?? 'الحلقة $epNum';
                    final overview = ep['overview'] ?? 'لا يوجد وصف.';
                    final stillPath = ep['still_path'];
                    final imageUrl = stillPath != null ? '${ApiConstants.tmdbImageBase}/w300$stillPath' : '';

                    return Card(
                      color: AppColors.surfaceLight,
                      margin: const EdgeInsets.only(bottom: 12),
                      child: InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => StreamLoaderScreen(
                                tmdbId: widget.seriesId,
                                title: '$name - $epNum',
                                mediaType: 'tv',
                                season: widget.seasonNumber,
                                episode: epNum,
                              ),
                            ),
                          );
                        },
                        child: Row(
                          children: [
                            ClipRRect(
                              borderRadius: const BorderRadius.horizontal(right: Radius.circular(AppSizes.radiusMedium)),
                              child: SizedBox(
                                width: 120,
                                height: 80,
                                child: imageUrl.isEmpty
                                    ? Container(color: AppColors.surface, child: const Icon(Icons.play_circle_outline, color: Colors.white54))
                                    : CachedNetworkImage(imageUrl: imageUrl, fit: BoxFit.cover),
                              ),
                            ),
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.all(10),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('$epNum. $name', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 14), maxLines: 1, overflow: TextOverflow.ellipsis),
                                    const SizedBox(height: 4),
                                    Text(overview, style: const TextStyle(color: AppColors.textTertiary, fontSize: 12), maxLines: 2, overflow: TextOverflow.ellipsis),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
