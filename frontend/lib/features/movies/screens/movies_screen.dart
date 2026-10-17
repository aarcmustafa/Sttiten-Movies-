import '../../../core/constants.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../shared/widgets/loading_indicator.dart';
import '../providers/movies_provider.dart';
import '../widgets/movie_card.dart';
import 'movie_details_screen.dart';
import '../../settings/screens/settings_screen.dart';

class MoviesScreen extends StatefulWidget {
  const MoviesScreen({super.key});

  @override
  State<MoviesScreen> createState() => _MoviesScreenState();
}

class _MoviesScreenState extends State<MoviesScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<MoviesProvider>();
      if (provider.trendingMovies.isEmpty && provider.popularMovies.isEmpty) {
        provider.loadInitial();
      }
    });
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 500) {
      context.read<MoviesProvider>().loadPopular();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      floatingActionButton: FloatingActionButton(
        mini: true,
        backgroundColor: AppColors.surfaceLight,
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen())),
        child: const Icon(Icons.settings, color: Colors.white),
      ),
      body: Consumer<MoviesProvider>(
        builder: (context, provider, _) {
          if (provider.trendingState == LoadingState.loading &&
              provider.trendingMovies.isEmpty) {
            return const AppLoader();
          }

          if (provider.trendingState == LoadingState.error &&
              provider.trendingMovies.isEmpty) {
            return ErrorView(
              message: provider.errorMessage ?? 'فشل تحميل البيانات',
              onRetry: () => provider.loadInitial(),
            );
          }

          return RefreshIndicator(
            color: AppColors.primary,
            backgroundColor: AppColors.surface,
            onRefresh: () => provider.refreshAll(),
            child: CustomScrollView(
          controller: _scrollController,
              slivers: [
                // ============ Hero Banner ============
                if (provider.heroMovie != null)
                  _HeroBanner(
                    movie: provider.heroMovie!,
                    onTap: () => _open(context, provider.heroMovie!.id),
                  ),

                // ============ Trending ============
                if (provider.trendingMovies.isNotEmpty) ...[
                  const SliverToBoxAdapter(
                    child: SectionTitle(title: 'الأكثر رواجًا 🔥'),
                  ),
                  SliverToBoxAdapter(
                    child: SizedBox(
                      height: AppSizes.cardHeight + 50,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.only(
                          right: AppSizes.paddingM,
                          left: AppSizes.paddingS,
                        ),
                        itemCount: provider.trendingMovies.length,
                        itemBuilder: (context, i) {
                          final movie = provider.trendingMovies[i];
                          return MovieCard(
                            movie: movie,
                            onTap: () => _open(context, movie.id),
                          );
                        },
                      ),
                    ),
                  ),
                ],

                // ============ Popular ============
                if (provider.popularMovies.isNotEmpty) ...[
                  const SliverToBoxAdapter(
                    child: SectionTitle(title: 'الأفلام الشائعة 🎬'),
                  ),
                  SliverToBoxAdapter(
                    child: SizedBox(
                      height: AppSizes.cardHeight + 50,
                      child: provider.popularState == LoadingState.loading
                          ? ListView.builder(
                              scrollDirection: Axis.horizontal,
                              padding: const EdgeInsets.only(
                                right: AppSizes.paddingM,
                                left: AppSizes.paddingS,
                              ),
                              itemCount: 5,
                              itemBuilder: (_, __) => const ShimmerCard(),
                            )
                          : ListView.builder(
                              scrollDirection: Axis.horizontal,
                              padding: const EdgeInsets.only(
                                right: AppSizes.paddingM,
                                left: AppSizes.paddingS,
                              ),
                              itemCount: provider.popularMovies.length,
                              itemBuilder: (context, i) {
                                final movie = provider.popularMovies[i];
                                return MovieCard(
                                  movie: movie,
                                  onTap: () => _open(context, movie.id),
                                );
                              },
                            ),
                    ),
                  ),
                ],

                // ============ Top Rated ============
                if (provider.topRatedMovies.isNotEmpty) ...[
                  const SliverToBoxAdapter(
                    child: SectionTitle(title: 'الأعلى تقييمًا ⭐'),
                  ),
                  SliverToBoxAdapter(
                    child: SizedBox(
                      height: AppSizes.cardHeight + 50,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.only(
                          right: AppSizes.paddingM,
                          left: AppSizes.paddingS,
                        ),
                        itemCount: provider.topRatedMovies.length,
                        itemBuilder: (context, i) {
                          final movie = provider.topRatedMovies[i];
                          return MovieCard(
                            movie: movie,
                            onTap: () => _open(context, movie.id),
                          );
                        },
                      ),
                    ),
                  ),
                ],

                const SliverToBoxAdapter(child: SizedBox(height: 30)),
              ],
            ),
          );
        },
      ),
    );
  }

  void _open(BuildContext context, int id) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MovieDetailsScreen(movieId: id, mediaType: 'movie'),
      ),
    );
  }
}

// ============ Hero Banner ============
class _HeroBanner extends StatelessWidget {
  final dynamic movie;
  final VoidCallback onTap;

  const _HeroBanner({required this.movie, required this.onTap});

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 500) {
      context.read<MoviesProvider>().loadPopular();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final bannerHeight = screenHeight * 0.62;

    return SliverToBoxAdapter(
      child: SizedBox(
        height: bannerHeight,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Backdrop
            if (movie.backdropUrl.isNotEmpty)
              Image.network(
                movie.backdropUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(color: AppColors.surface),
              ),

            // Gradient overlay
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    AppColors.background.withOpacity(0.4),
                    AppColors.background.withOpacity(0.85),
                    AppColors.background,
                  ],
                  stops: const [0.0, 0.5, 0.8, 1.0],
                ),
              ),
            ),

            // Content
            Positioned(
              right: AppSizes.paddingL,
              left: AppSizes.paddingL,
              bottom: AppSizes.paddingL,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'جديد',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Title
                  Text(
                    movie.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      height: 1.2,
                    ),
                  ),

                  const SizedBox(height: 10),

                  // Meta row
                  Row(
                    children: [
                      const Icon(Icons.star_rounded,
                          size: 16, color: AppColors.rating),
                      const SizedBox(width: 4),
                      Text(
                        movie.rating,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (movie.year.isNotEmpty) ...[
                        const SizedBox(width: 14),
                        Text(
                          movie.year,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Buttons
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: onTap,
                          icon: const Icon(Icons.play_arrow_rounded, size: 22),
                          label: const Text('عرض التفاصيل'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceLight,
                          borderRadius:
                              BorderRadius.circular(AppSizes.radiusMedium),
                        ),
                        child: const Icon(
                          Icons.add_rounded,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
