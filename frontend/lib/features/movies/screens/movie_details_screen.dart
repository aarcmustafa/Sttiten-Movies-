import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../../../core/api_client.dart';
import '../../../core/constants.dart';
import '../../../shared/widgets/loading_indicator.dart';
import '../models/movie.dart';

class MovieDetailsScreen extends StatefulWidget {
  final int movieId;
  const MovieDetailsScreen({super.key, required this.movieId});

  @override
  State<MovieDetailsScreen> createState() => _MovieDetailsScreenState();
}

class _MovieDetailsScreenState extends State<MovieDetailsScreen> {
  final _api = ApiClient();
  MovieDetails? _movie;
  bool _loading = true;
  String? _error;
  bool _isSeries = false;

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
      try {
        data = await _api.getMovieDetails(widget.movieId);
        _isSeries = false;
      } catch (_) {
        data = await _api.getSeriesDetails(widget.movieId);
        _isSeries = true;
      }
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
                      if (m.runtimeFormatted.isNotEmpty)
                        _metaItem(Icons.access_time_rounded, m.runtimeFormatted),
                      if (m.numberOfSeasons != null && m.numberOfSeasons! > 0)
                        _metaItem(Icons.layers_rounded, '${m.numberOfSeasons} مواسم'),
                      _metaItem(Icons.star_rounded, m.rating,
                          color: AppColors.rating),
                    ],
                  ),
                  const SizedBox(height: 18),
                  if (m.genres.isNotEmpty)
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: m.genres
                          .map((g) => _genreChip(g.name))
                          .toList(),
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
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _showSubtitles(context, m),
                          icon: const Icon(Icons.subtitles_rounded, size: 20),
                          label: const Text('الترجمات العربية'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceLight,
                          borderRadius:
                              BorderRadius.circular(AppSizes.radiusMedium),
                        ),
                        child: const Icon(Icons.favorite_border_rounded,
                            color: AppColors.textPrimary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),
                  if (m.cast.isNotEmpty) ...[
                    const _SectionTitle('طاقم العمل'),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 130,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: m.cast.length,
                        itemBuilder: (context, i) {
                          final c = m.cast[i];
                          return _castCard(c);
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

  Widget _castCard(CastMember c) {
    return Container(
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
    );
  }

  void _showSubtitles(BuildContext context, MovieDetails m) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _SubtitlesSheet(
          tmdbId: m.id,
          mediaType: _isSeries ? 'tv' : 'movie',
          title: m.title,
        ),
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
