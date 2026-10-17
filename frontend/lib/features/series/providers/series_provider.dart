import 'package:flutter/foundation.dart';
import '../../../core/api_client.dart';
import '../../movies/models/movie.dart';
import '../../movies/providers/movies_provider.dart';

class SeriesProvider extends ChangeNotifier {
  final ApiClient _api = ApiClient();

  // Popular
  List<Movie> _turkishSeries = [];
  List<Movie> get turkishSeries => _turkishSeries;
  List<Movie> _indianSeries = [];
  List<Movie> get indianSeries => _indianSeries;

  List<Movie> _popularSeries = [];
  List<Movie> get popularSeries => _popularSeries;

  // Trending
  List<Movie> _trendingSeries = [];
  List<Movie> get trendingSeries => _trendingSeries;

  // Search
  List<Movie> _searchResults = [];
  List<Movie> get searchResults => _searchResults;

  // States
  LoadingState _popularState = LoadingState.idle;
  LoadingState _trendingState = LoadingState.idle;
  LoadingState _searchState = LoadingState.idle;

  LoadingState get popularState => _popularState;
  LoadingState get trendingState => _trendingState;
  LoadingState get searchState => _searchState;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  // ============ Initial Load ============
  Future<void> loadInitial() async {
    await Future.wait([
      loadTrending(),
      loadPopular(),
    ]);
  }

  // ============ Trending ============
  Future<void> loadTrending() async {
    _trendingState = LoadingState.loading;
    notifyListeners();
    try {
      final data = await _api.getTrendingSeries();
      final list = (data['results'] as List<dynamic>? ?? [])
          .map((e) => Movie.fromJson(e as Map<String, dynamic>))
          .toList();
      _trendingSeries = list;
      _trendingState = LoadingState.loaded;
    } catch (e) {
      _errorMessage = _friendlyError(e);
      _trendingState = LoadingState.error;
    }
    notifyListeners();
  }

  // ============ Popular ============
  Future<void> loadPopular({int page = 1, bool refresh = false}) async {
    if (!refresh && _popularState == LoadingState.loading) return;
    _popularState = LoadingState.loading;
    notifyListeners();
    try {
      final data = await _api.getPopularSeries(page: page);
      final list = (data['results'] as List<dynamic>? ?? [])
          .map((e) => Movie.fromJson(e as Map<String, dynamic>))
          .toList();
      _popularSeries = refresh ? list : [..._popularSeries, ...list];
      _popularState = LoadingState.loaded;
    } catch (e) {
      _errorMessage = _friendlyError(e);
      _popularState = LoadingState.error;
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
      final data = await _api.searchSeries(query);
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
