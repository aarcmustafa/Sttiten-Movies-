import '../../../core/constants.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../shared/widgets/loading_indicator.dart';
import '../../movies/providers/movies_provider.dart';
import '../providers/series_provider.dart';
import '../../movies/widgets/movie_card.dart';
import '../../movies/screens/movie_details_screen.dart';

class SeriesScreen extends StatefulWidget {
  const SeriesScreen({super.key});

  @override
  State<SeriesScreen> createState() => _SeriesScreenState();
}

class _SeriesScreenState extends State<SeriesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final p = context.read<SeriesProvider>();
      if (p.popularSeries.isEmpty && p.trendingSeries.isEmpty) {
        p.loadInitial();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('المسلسلات 📺'),
        automaticallyImplyLeading: false,
      ),
      body: Consumer<SeriesProvider>(
        builder: (context, provider, _) {
          if (provider.popularState == LoadingState.loading &&
              provider.popularSeries.isEmpty) {
            return const AppLoader();
          }

          if (provider.popularState == LoadingState.error &&
              provider.popularSeries.isEmpty) {
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
              slivers: [
                // ===== Trending =====
                if (provider.trendingSeries.isNotEmpty) ...[
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
                        itemCount: provider.trendingSeries.length,
                        itemBuilder: (context, i) {
                          final s = provider.trendingSeries[i];
                          return MovieCard(
                            movie: s,
                            onTap: () => _open(context, s.id),
                          );
                        },
                      ),
                    ),
                  ),
                ],

                // ===== Popular =====
                if (provider.popularSeries.isNotEmpty) ...[
                  const SliverToBoxAdapter(
                    child: SectionTitle(title: 'المسلسلات الشائعة 📺'),
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
                        itemCount: provider.popularSeries.length,
                        itemBuilder: (context, i) {
                          final s = provider.popularSeries[i];
                          return MovieCard(
                            movie: s,
                            onTap: () => _open(context, s.id),
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
        builder: (_) => MovieDetailsScreen(movieId: id, mediaType: 'tv'),
      ),
    );
  }
}
