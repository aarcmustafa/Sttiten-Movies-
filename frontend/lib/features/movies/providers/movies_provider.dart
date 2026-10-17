import 'package:flutter/foundation.dart';
import '../../../core/api_client.dart';
import '../models/movie.dart';

enum LoadingState { idle, loading, loaded, error }

class MoviesProvider extends ChangeNotifier {
  final ApiClient _api = ApiClient();

  // Popular
  List<Movie> _popularMovies = [];
  List<Movie> get popularMovies => _popularMovies;

  // Trending
  List<Movie> _trendingMovies = [];
  List<Movie> get trendingMovies => _trendingMovies;

  // Top rated
  List<Movie> _topRatedMovies = [];
  List<Movie> get topRatedMovies => _topRatedMovies;

  // Search
  List<Movie> _searchResults = [];
  List<Movie> get searchResults => _searchResults;

  // Hero movie (first trending)
  Movie? get heroMovie =>
      _trendingMovies.isNotEmpty ? _trendingMovies.first : null;

  // States
  LoadingState _popularState = LoadingState.idle;
  LoadingState _trendingState = LoadingState.idle;
  LoadingState _topRatedState = LoadingState.idle;
  LoadingState _searchState = LoadingState.idle;

  LoadingState get popularState => _popularState;
  LoadingState get trendingState => _trendingState;
  LoadingState get topRatedState => _topRatedState;
  LoadingState get searchState => _searchState;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  // ============ Load Initial Data ============
  Future<void> loadInitial() async {
    await Future.wait([
      loadTrending(),
      loadPopular(),
    ]);
    // Top rated in background
    loadTopRated();
  }

  // ============ Trending ============
  Future<void> loadTrending() async {
    _trendingState = LoadingState.loading;
    notifyListeners();
    try {
      final data = await _api.getTrendingMovies();
      final list = (data['results'] as List<dynamic>? ?? [])
          .map((e) => Movie.fromJson(e as Map<String, dynamic>))
          .toList();
      _trendingMovies = list;
      _trendingState = LoadingState.loaded;
    } catch (e) {
      _errorMessage = _friendlyError(e);
      _trendingState = LoadingState.error;
      if (kDebugMode) debugPrint('loadTrending error: $e');
    }
    notifyListeners();
  }

  // ============ Popular ============
  Future<void> loadPopular({int page = 1, bool refresh = false}) async {
    if (!refresh && _popularState == LoadingState.loading) return;
    _popularState = LoadingState.loading;
    notifyListeners();
    try {
      final data = await _api.getPopularMovies(page: page);
      final list = (data['results'] as List<dynamic>? ?? [])
          .map((e) => Movie.fromJson(e as Map<String, dynamic>))
          .toList();
      _popularMovies = refresh ? list : [..._popularMovies, ...list];
      _popularState = LoadingState.loaded;
    } catch (e) {
      _errorMessage = _friendlyError(e);
      _popularState = LoadingState.error;
    }
    notifyListeners();
  }

  // ============ Top Rated ============
  Future<void> loadTopRated() async {
    _topRatedState = LoadingState.loading;
    notifyListeners();
    try {
      final data = await _api.getTopRatedMovies();
      final list = (data['results'] as List<dynamic>? ?? [])
          .map((e) => Movie.fromJson(e as Map<String, dynamic>))
          .toList();
      _topRatedMovies = list;
      _topRatedState = LoadingState.loaded;
    } catch (e) {
      _errorMessage = _friendlyError(e);
      _topRatedState = LoadingState.error;
    }
    notifyListeners();
  }

  // ============ Search ============
  Future<void> search(String query) async {
    if (query.trim().isEmpty) {
      _searchResults = [];
      _searchState = LoadingState.idle;
      notifyListeners();
      return;
    }
    _searchState = LoadingState.loading;
    notifyListeners();
    try {
      final data = await _api.searchMovies(query);
      final list = (data['results'] as List<dynamic>? ?? [])
          .map((e) => Movie.fromJson(e as Map<String, dynamic>))
          .toList();
      _searchResults = list;
      _searchState = LoadingState.loaded;
    } catch (e) {
      _errorMessage = _friendlyError(e);
      _searchState = LoadingState.error;
    }
    notifyListeners();
  }

  void clearSearch() {
    _searchResults = [];
    _searchState = LoadingState.idle;
    notifyListeners();
  }

  // ============ Refresh ============
  Future<void> refreshAll() async {
    await Future.wait([
      loadTrending(),
      loadPopular(refresh: true),
      loadTopRated(),
    ]);
  }

  // ============ Helpers ============
  String _friendlyError(Object e) {
    final msg = e.toString();
    if (msg.contains('SocketException') || msg.contains('Connection')) {
      return 'تحقق من اتصالك بالإنترنت';
    }
    if (msg.contains('timeout')) {
      return 'انتهت مهلة الاتصال. حاول مجددًا';
    }
    return 'حدث خطأ غير متوقع';
  }
}
