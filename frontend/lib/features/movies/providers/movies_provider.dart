import 'package:flutter/foundation.dart';
import '../../../core/api_client.dart';
import '../models/movie.dart';

enum LoadingState { idle, loading, loaded, error }

class MoviesProvider extends ChangeNotifier {
  final ApiClient _api = ApiClient();

  List<Movie> _popularMovies = [];
  List<Movie> get popularMovies => _popularMovies;

  List<Movie> _trendingMovies = [];
  List<Movie> get trendingMovies => _trendingMovies;

  List<Movie> _topRatedMovies = [];
  List<Movie> get topRatedMovies => _topRatedMovies;

  List<Movie> _searchResults = [];
  List<Movie> get searchResults => _searchResults;

  Movie? get heroMovie => _trendingMovies.isNotEmpty ? _trendingMovies.first : null;

  LoadingState _popularState = LoadingState.idle;
  LoadingState _trendingState = LoadingState.idle;
  LoadingState _topRatedState = LoadingState.idle;
  LoadingState _searchState = LoadingState.idle;

  LoadingState get popularState => _popularState;
  LoadingState get trendingState => _trendingState;
  LoadingState get topRatedState => _topRatedState;
  LoadingState get searchState => _searchState;

  int _popularPage = 1;
  bool _hasMorePopular = true;
  bool _isLoadingMorePopular = false;
  bool get isLoadingMorePopular => _isLoadingMorePopular;
  bool get hasMorePopular => _hasMorePopular;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  Future<void> loadInitial() async {
    await loadTrending();
    await loadPopular(refresh: true);
    await loadTopRated();
  }

  Future<void> loadTrending() async {
    _trendingState = LoadingState.loading;
    notifyListeners();
    try {
      final data = await _api.getTrendingMovies();
      _trendingMovies = (data['results'] as List<dynamic>? ?? [])
          .map((e) => Movie.fromJson(e as Map<String, dynamic>))
          .toList();
      _trendingState = LoadingState.loaded;
    } catch (e) {
      _errorMessage = _friendlyError(e);
      _trendingState = LoadingState.error;
    }
    notifyListeners();
  }

  Future<void> loadPopular({bool refresh = false}) async {
    if (refresh) {
      _popularPage = 1;
      _hasMorePopular = true;
      _popularState = LoadingState.loading;
    } else {
      if (_isLoadingMorePopular || !_hasMorePopular) return;
      _isLoadingMorePopular = true;
      notifyListeners();
    }
    try {
      final data = await _api.getPopularMovies(page: _popularPage);
      final list = (data['results'] as List<dynamic>? ?? [])
          .map((e) => Movie.fromJson(e as Map<String, dynamic>))
          .toList();
      if (refresh) {
        _popularMovies = list;
        _popularState = LoadingState.loaded;
      } else {
        _popularMovies.addAll(list);
      }
      _popularPage++;
      final totalPages = data['total_pages'];
      if (totalPages is int) {
        _hasMorePopular = _popularPage <= totalPages;
      } else {
        _hasMorePopular = false;
      }
    } catch (e) {
      _errorMessage = _friendlyError(e);
      if (refresh) _popularState = LoadingState.error;
    }
    _isLoadingMorePopular = false;
    notifyListeners();
  }

  Future<void> loadTopRated() async {
    _topRatedState = LoadingState.loading;
    notifyListeners();
    try {
      final data = await _api.getTopRatedMovies();
      _topRatedMovies = (data['results'] as List<dynamic>? ?? [])
          .map((e) => Movie.fromJson(e as Map<String, dynamic>))
          .toList();
      _topRatedState = LoadingState.loaded;
    } catch (e) {
      _topRatedState = LoadingState.error;
    }
    notifyListeners();
  }

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
      _searchResults = (data['results'] as List<dynamic>? ?? [])
          .map((e) => Movie.fromJson(e as Map<String, dynamic>))
          .toList();
      _searchState = LoadingState.loaded;
    } catch (e) {
      _searchState = LoadingState.error;
    }
    notifyListeners();
  }

  void clearSearch() {
    _searchResults = [];
    _searchState = LoadingState.idle;
    notifyListeners();
  }

  Future<void> refreshAll() async {
    await loadTrending();
    await loadPopular(refresh: true);
    await loadTopRated();
  }

  String _friendlyError(Object e) {
    final msg = e.toString();
    if (msg.contains('SocketException') || msg.contains('Connection')) return 'تحقق من اتصالك بالإنترنت';
    if (msg.contains('timeout')) return 'انتهت مهلة الاتصال. حاول مجدداً';
    return 'حدث خطأ غير متوقع';
  }
}
