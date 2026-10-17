import '../../../core/page_transitions.dart';
import '../../../core/constants.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/api_client.dart';
import '../../../shared/widgets/loading_indicator.dart';
import '../../favorites/providers/favorites_provider.dart';
import '../models/movie.dart';
import '../widgets/movie_card.dart';
import '../../series/screens/episodes_screen.dart';
import '../../person/screens/actor_details_screen.dart';
import '../../video/video_player_screen.dart';

class MovieDetailsScreen extends StatefulWidget {
  final int movieId;
  final String mediaType;
  const MovieDetailsScreen({
    super.key,
    required this.movieId,
    this.mediaType = 'movie',
  });

  @override
  State<MovieDetailsScreen> createState() => _MovieDetailsScreenState();
}

class _MovieDetailsScreenState extends State<MovieDetailsScreen> {
  final _api = ApiClient();
  MovieDetails? _movie;
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _seasons = [];

  bool get _isSeries => widget.mediaType == 'tv';

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
      Map<String, dynamic> data;
      if (_isSeries) {
        data = await _api.getSeriesDetails(widget.movieId);
      } else {
        data = await _api.getMovieDetails(widget.movieId);
      }

      final seasonsRaw = data['seasons'] as List<dynamic>? ?? [];
      _seasons = seasonsRaw
          .where((s) => (s['season_number'] ?? 0) > 0)
          .cast<Map<String, dynamic>>()
          .toList();

      setState(() {
        _movie = MovieDetails.fromJson(data);
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'فشل تحميل التفاصيل';
        _loading = false;
      });
    }
  }

  Future<void> _launchTrailer(String videoKey) async {
    final url = Uri.parse('https://www.youtube.com/watch?v=$videoKey');
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تعذر فتح الفيديو')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: AppLoader(),
      );
    }

    if (_error != null || _movie == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(),
        body: ErrorView(message: _error ?? 'خطأ', onRetry: _load),
      );
    }

    final m = _movie!;
    final trailerKey = m.videos.isNotEmpty ? m.videos.first.key : null;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 320,
            pinned: true,
            backgroundColor: AppColors.background,
            leading: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.arrow_back_rounded, size: 20),
              ),
              onPressed: () => Navigator.pop(context),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  if (m.backdropUrl.isNotEmpty)
                    CachedNetworkImage(
                      imageUrl: m.backdropUrl,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => Container(color: AppColors.surface),
                      errorWidget: (_, __, ___) => Container(color: AppColors.surface),
                    ),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          AppColors.background.withOpacity(0.4),
                          AppColors.background.withOpacity(0.9),
                          AppColors.background,
                        ],
                        stops: const [0.0, 0.4, 0.8, 1.0],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(AppSizes.paddingM),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (_isSeries)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'مسلسل 📺',
                            style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700),
                          ),
                        )
                      else
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.accent,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'فيلم 🎬',
                            style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    m.title,
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                      height: 1.2,
                    ),
                  ),
                  if (m.tagline != null && m.tagline!.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      m.tagline!,
                      style: const TextStyle(
                        fontSize: 14,
                        fontStyle: FontStyle.italic,
                        color: AppColors.primaryLight,
                      ),
                    ),
                  ],
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 14,
                    runSpacing: 8,
                    children: [
                      if (m.year.isNotEmpty) _metaItem(Icons.calendar_today_rounded, m.year),
                      if (!_isSeries && m.runtimeFormatted.isNotEmpty)
                        _metaItem(Icons.access_time_rounded, m.runtimeFormatted),
                      if (_isSeries && m.numberOfSeasons != null && m.numberOfSeasons! > 0)
                        _metaItem(Icons.layers_rounded, '${m.numberOfSeasons} مواسم'),
                      if (_isSeries && m.numberOfEpisodes != null && m.numberOfEpisodes! > 0)
                        _metaItem(Icons.playlist_play_rounded, '${m.numberOfEpisodes} حلقة'),
                      if (m.status != null && m.status!.isNotEmpty)
                        _metaItem(Icons.info_outline_rounded, _translateStatus(m.status!)),
                      _metaItem(Icons.star_rounded, m.rating, color: AppColors.rating),
                    ],
                  ),
                  const SizedBox(height: 18),
                  if (m.genres.isNotEmpty)
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: m.genres.map((g) => _genreChip(g.name)).toList(),
                    ),
                  const SizedBox(height: 24),
                  if (m.overview != null && m.overview!.isNotEmpty) ...[
                    const _SectionTitle('القصة'),
                    const SizedBox(height: 10),
                    Text(
                      m.overview!,
                      style: const TextStyle(
                        fontSize: 15,
                        height: 1.7,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          FadeSlidePageRoute(child: VideoPlayerScreen(
                          title: m.title,
                          tmdbId: m.id,
                          mediaType: _isSeries ? 'tv' : 'movie',),
                          ),
                        );
                      },
                      icon: const Icon(Icons.play_arrow_rounded, size: 28),
                      label: const Text('مشاهدة الآن', style: TextStyle(fontSize: 16)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  Row(
                    children: [
                      if (trailerKey != null) ...[
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => _launchTrailer(trailerKey),
                            icon: const Icon(Icons.play_circle_fill_rounded, size: 20),
                            label: const Text('التريلر'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.surfaceLight,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                      ],
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _showSubtitles(context, m),
                          icon: const Icon(Icons.subtitles_rounded, size: 20),
                          label: const Text('الترجمات'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Consumer<FavoritesProvider>(
                        builder: (context, favProv, _) {
                          final isFav = favProv.isFavorite(m.id, _isSeries ? 'tv' : 'movie');
                          return GestureDetector(
                            onTap: () async {
                              final wasFav = isFav;
                              final success = await favProv.toggleFavorite(m);
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(success
                                        ? (wasFav ? 'تمت الإزالة من المفضلة' : 'تمت الإضافة إلى المفضلة')
                                        : 'حدث خطأ، حاول مجدداً'),
                                    backgroundColor: wasFav ? AppColors.error : AppColors.success,
                                    duration: const Duration(seconds: 2),
                                  ),
                                );
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: isFav ? AppColors.primary.withOpacity(0.2) : AppColors.surfaceLight,
                                borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
                                border: isFav ? Border.all(color: AppColors.primary, width: 1) : null,
                              ),
                              child: Icon(
                                isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                                color: isFav ? AppColors.primary : AppColors.textPrimary,
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),

                  if (_isSeries && _seasons.isNotEmpty) ...[
                    const _SectionTitle('المواسم'),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 140,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _seasons.length,
                        itemBuilder: (context, i) => _seasonCard(_seasons[i]),
                      ),
                    ),
                    const SizedBox(height: 28),
                  ],

                  if (m.cast.isNotEmpty) ...[
                    const _SectionTitle('طاقم العمل'),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 130,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: m.cast.length,
                        itemBuilder: (context, i) => _castCard(m.cast[i]),
                      ),
                    ),
                    const SizedBox(height: 28),
                  ],

                  if (m.recommendations.isNotEmpty) ...[
                    const _SectionTitle('أعمال مشابهة'),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: AppSizes.cardHeight + 50,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.only(
                          right: AppSizes.paddingS,
                          left: AppSizes.paddingS,
                        ),
                        itemCount: m.recommendations.length,
                        itemBuilder: (context, i) {
                          final rec = m.recommendations[i];
                          return MovieCard(
                            movie: rec,
                            onTap: () {
                              Navigator.pushReplacement(
                                context,
                                FadeSlidePageRoute(child: MovieDetailsScreen(
                                    movieId: rec.id,
                                    mediaType: rec.mediaType ?? 'movie',),
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 30),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _metaItem(IconData icon, String text, {Color? color}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15, color: color ?? AppColors.textTertiary),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(
            fontSize: 13,
            color: color ?? AppColors.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _genreChip(String name) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withOpacity(0.3), width: 1),
      ),
      child: Text(
        name,
        style: const TextStyle(
          fontSize: 12,
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  

  Widget _seasonCard(Map<String, dynamic> season) {
    final number = season['season_number'] ?? 0;
    final name = season['name'] ?? 'الموسم $number';
    final episodes = season['episode_count'] ?? 0;
    final poster = season['poster_path'];
    final posterUrl = poster == null ? '' : '${ApiConstants.tmdbImageBase}/w300$poster';

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          FadeSlidePageRoute(child: EpisodesScreen(
              seriesId: _movie!.id,
              seasonNumber: number,
              seasonName: name,
              seriesTitle: _movie!.title,),
          ),
        );
      },
      child: Container(
      width: 100,
      margin: const EdgeInsets.only(left: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
            child: SizedBox(
              width: 100,
              height: 100,
              child: posterUrl.isEmpty
                  ? Container(
                      color: AppColors.surfaceLight,
                      child: Center(
                        child: Text(
                          'S$number',
                          style: const TextStyle(
                            color: AppColors.primaryLight,
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    )
                  : CachedNetworkImage(
                      imageUrl: posterUrl,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => Container(color: AppColors.surfaceLight),
                      errorWidget: (_, __, ___) => Container(
                        color: AppColors.surfaceLight,
                        child: Center(
                          child: Text(
                            'S$number',
                            style: const TextStyle(
                              color: AppColors.primaryLight,
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          Text(
            '$episodes حلقة',
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.textTertiary,
            ),
          ),
        ],
      ),
    ));
  }

  Widget _castCard(CastMember c) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          FadeSlidePageRoute(child: ActorDetailsScreen(personId: c.id)),
        );
      },
      child: Container(
      width: 90,
      margin: const EdgeInsets.only(left: 12),
      child: Column(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(50),
            child: SizedBox(
              width: 80,
              height: 80,
              child: c.profileUrl.isEmpty
                  ? Container(
                      color: AppColors.surfaceLight,
                      child: const Icon(Icons.person_rounded,
                          color: AppColors.textTertiary, size: 40),
                    )
                  : CachedNetworkImage(
                      imageUrl: c.profileUrl,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => Shimmer.fromColors(
                        baseColor: AppColors.surfaceLight,
                        highlightColor: AppColors.card,
                        child: Container(color: AppColors.surfaceLight),
                      ),
                      errorWidget: (_, __, ___) => Container(
                        color: AppColors.surfaceLight,
                        child: const Icon(Icons.person_rounded,
                            color: AppColors.textTertiary, size: 40),
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            c.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          if (c.character != null)
            Text(
              c.character!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 10,
                color: AppColors.textTertiary,
              ),
            ),
        ],
      ),
    ));
  }

  String _translateStatus(String status) {
    switch (status) {
      case 'Returning Series': return 'مستمر';
      case 'Ended': return 'منتهي';
      case 'Canceled': return 'ملغى';
      case 'In Production': return 'قيد الإنتاج';
      case 'Planned': return 'مُخطط له';
      case 'Released': return 'صدر';
      case 'Post Production': return 'ما بعد الإنتاج';
      default: return status;
    }
  }

  void _showSubtitles(BuildContext context, MovieDetails m) {
    Navigator.push(
      context,
      FadeSlidePageRoute(child: _SubtitlesSheet(
          tmdbId: m.id,
          mediaType: _isSeries ? 'tv' : 'movie',
          title: m.title,),
      ),
    );
  }
}

// ============ Section Title ============
class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
      ),
    );
  }
}

// ============ Subtitles Sheet ============
class _SubtitlesSheet extends StatefulWidget {
  final int tmdbId;
  final String mediaType;
  final String title;

  const _SubtitlesSheet({
    required this.tmdbId,
    required this.mediaType,
    required this.title,
  });

  @override
  State<_SubtitlesSheet> createState() => _SubtitlesSheetState();
}

class _SubtitlesSheetState extends State<_SubtitlesSheet> {
  final _api = ApiClient();
  List<Map<String, dynamic>> _subtitles = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final data = await _api.searchSubtitles(
        tmdbId: widget.tmdbId,
        mediaType: widget.mediaType,
      );
      final list = (data['data']?['subtitles'] as List<dynamic>? ?? [])
          .cast<Map<String, dynamic>>();
      setState(() {
        _subtitles = list;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'فشل تحميل الترجمات';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('الترجمات العربية'),
      ),
      body: _loading
          ? const AppLoader()
          : _error != null
              ? ErrorView(message: _error!, onRetry: _load)
              : _subtitles.isEmpty
                  ? const EmptyState(
                      icon: Icons.subtitles_off_rounded,
                      title: 'لا توجد ترجمات متاحة',
                      subtitle: 'لم نجد ترجمات عربية لهذا العمل حاليًا',
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(AppSizes.paddingM),
                      itemCount: _subtitles.length,
                      itemBuilder: (context, i) => _subtitleTile(_subtitles[i]),
                    ),
    );
  }

  Widget _subtitleTile(Map<String, dynamic> sub) {
    final name = sub['release_name'] ?? 'ترجمة';
    final author = sub['author'] ?? 'غير معروف';
    final lang = sub['lang'] ?? 'arabic';
    final url = sub['url'] ?? '';

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.subtitles_rounded,
              color: AppColors.primaryLight),
        ),
        title: Text(
          name,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Row(
            children: [
              const Icon(Icons.person_outline_rounded,
                  size: 13, color: AppColors.textTertiary),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  author,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 11, color: AppColors.textTertiary),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  lang.toString().toUpperCase(),
                  style: const TextStyle(
                    fontSize: 10,
                    color: AppColors.success,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
        trailing: const Icon(Icons.download_rounded,
            color: AppColors.primaryLight),
        onTap: url.isEmpty ? null : () => _downloadSubtitle(url, name),
      ),
    );
  }

  void _downloadSubtitle(String url, String name) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('جاري تحميل: $name'),
        backgroundColor: AppColors.primary,
      ),
    );
  }
}


class _StreamsListScreen extends StatefulWidget {
  final int tmdbId;
  final String title;
  final String mediaType;
  final int season;
  final int episode;

  const _StreamsListScreen({
    required this.tmdbId,
    required this.title,
    required this.mediaType,
    this.season = 1,
    this.episode = 1,
  });

  @override
  State<_StreamsListScreen> createState() => _StreamsListScreenState();
}

class _StreamsListScreenState extends State<_StreamsListScreen> {
  final _api = ApiClient();
  List<String> _urls = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadStreams();
  }

  Future<void> _loadStreams() async {
    try {
      final urls = await _api.getStreamUrls(
        tmdbId: widget.tmdbId,
        mediaType: widget.mediaType,
        season: widget.season,
        episode: widget.episode,
      );
      setState(() {
        _urls = urls;
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
      appBar: AppBar(title: Text('اختر مصدر المشاهدة')),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _urls.isEmpty
              ? const Center(child: Text('لا توجد مصادر متاحة حالياً', style: TextStyle(color: Colors.white)))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _urls.length,
                  itemBuilder: (context, index) {
                    // استخراج اسم النطاق لعرضه (مثل vidsrc.to)
                    final uri = Uri.parse(_urls[index]);
                    final host = uri.host.isNotEmpty ? uri.host : 'مصدر ${index + 1}';

                    return Card(
                      color: AppColors.surfaceLight,
                      margin: const EdgeInsets.only(bottom: 10),
                      child: ListTile(
                        leading: const Icon(Icons.play_circle_fill_rounded, color: AppColors.primary, size: 36),
                        title: Text(
                          'مصدر ${index + 1}: $host',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                        subtitle: const Text('اضغط للتشغيل (قد يحتوي على إعلانات)', style: TextStyle(color: AppColors.textTertiary, fontSize: 12)),
                        trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white54, size: 16),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => WebViewScreen(
                                title: widget.title,
                                url: _urls[index],
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
