import '../../../core/page_transitions.dart';
import '../../../core/constants.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../shared/widgets/loading_indicator.dart';
import '../../movies/providers/movies_provider.dart';
import '../../movies/widgets/movie_card.dart';
import '../../movies/screens/movie_details_screen.dart';
import '../../series/providers/series_provider.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _controller = TextEditingController();
  String _lastQuery = '';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _search(String query) {
    if (query.trim() == _lastQuery) return;
    _lastQuery = query;
    if (query.trim().isEmpty) {
      context.read<MoviesProvider>().clearSearch();
      context.read<SeriesProvider>().clearSearch();
      return;
    }
    context.read<MoviesProvider>().search(query);
    context.read<SeriesProvider>().search(query);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: TextField(
          controller: _controller,
          autofocus: false,
          style: const TextStyle(color: AppColors.textPrimary),
          textInputAction: TextInputAction.search,
          onSubmitted: _search,
          decoration: InputDecoration(
            hintText: 'ابحث عن فيلم أو مسلسل...',
            prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textTertiary),
            suffixIcon: _controller.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear_rounded),
                    onPressed: () {
                      _controller.clear();
                      _search('');
                      setState(() {});
                    },
                  )
                : null,
          ),
          onChanged: (val) {
            setState(() {}); // لتحديث زر المسح
          },
        ),
      ),
      body: Consumer2<MoviesProvider, SeriesProvider>(
        builder: (context, moviesProv, seriesProv, _) {
          final isSearching = moviesProv.searchState == LoadingState.loading ||
              seriesProv.searchState == LoadingState.loading;

          if (isSearching) return const Center(child: CircularProgressIndicator(color: AppColors.primary));

          if (moviesProv.searchResults.isEmpty && seriesProv.searchResults.isEmpty) {
            if (_lastQuery.isEmpty) {
              return const EmptyState(
                icon: Icons.search_rounded,
                title: 'ابحث عن شيء ممتع',
                subtitle: 'اكتب اسم فيلم أو مسلسل للبدء',
              );
            }
            return const EmptyState(
              icon: Icons.search_off_rounded,
              title: 'لا توجد نتائج',
              subtitle: 'جرب البحث بكلمات مختلفة',
            );
          }

          return ListView(
            padding: const EdgeInsets.only(top: AppSizes.paddingM, bottom: 30),
            children: [
              if (moviesProv.searchResults.isNotEmpty) ...[
                const SectionTitle(title: 'أفلام 🎬'),
                ...moviesProv.searchResults.map(
                  (m) => MovieCardHorizontal(
                    movie: m,
                    onTap: () => _open(context, m.id, 'movie'),
                  ),
                ),
              ],
              if (seriesProv.searchResults.isNotEmpty) ...[
                const SectionTitle(title: 'مسلسلات 📺'),
                ...seriesProv.searchResults.map(
                  (s) => MovieCardHorizontal(
                    movie: s,
                    onTap: () => _open(context, s.id, 'tv'),
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  void _open(BuildContext context, int id, String mediaType) {
    Navigator.push(
      context,
      FadeSlidePageRoute(child: MovieDetailsScreen(movieId: id, mediaType: mediaType),
      ),
    );
  }
}
