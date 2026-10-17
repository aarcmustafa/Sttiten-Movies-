import 'package:flutter/foundation.dart';
import '../../../core/api_client.dart';
import '../../movies/models/movie.dart';

class FavoritesProvider extends ChangeNotifier {
  final ApiClient _api = ApiClient();

  List<Movie> _favorites = [];
  List<Movie> get favorites => _favorites;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  // جلب المفضلة من السيرفر
  Future<void> loadFavorites() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final data = await _api.getFavorites();
      
      // تحويل بيانات السيرفر إلى نموذج Movie لفهمها في الواجهة
      _favorites = data.map((json) {
        return Movie(
          id: json['tmdb_id'] ?? 0,
          title: json['title'] ?? 'بدون عنوان',
          posterPath: json['poster_path'],
          mediaType: json['media_type'],
        );
      }).toList();
      
    } catch (e) {
      _error = 'فشل تحميل قائمة المفضلة';
      if (kDebugMode) debugPrint('loadFavorites error: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  // التحقق من وجود الفيلم في المفضلة
  bool isFavorite(int id, String mediaType) {
    return _favorites.any((m) => m.id == id && m.mediaType == mediaType);
  }

  // إضافة أو حذف فيلم من المفضلة
  Future<bool> toggleFavorite(Movie movie) async {
    final mediaType = movie.mediaType ?? (movie.isSeries ? 'tv' : 'movie');
    final currentlyFav = isFavorite(movie.id, mediaType);

    // تحديث فوري للواجهة (Optimistic UI) لتجربة سريعة
    if (currentlyFav) {
      _favorites.removeWhere((m) => m.id == movie.id && m.mediaType == mediaType);
    } else {
      _favorites.insert(0, movie);
    }
    notifyListeners();

    try {
      if (currentlyFav) {
        await _api.removeFavorite(tmdbId: movie.id, mediaType: mediaType);
      } else {
        await _api.addFavorite(
          tmdbId: movie.id,
          mediaType: mediaType,
          title: movie.title,
          posterPath: movie.posterPath,
        );
      }
      return true;
    } catch (e) {
      // في حالة الفشل، نرجع التعديل
      if (currentlyFav) {
        _favorites.insert(0, movie);
      } else {
        _favorites.removeWhere((m) => m.id == movie.id && m.mediaType == mediaType);
      }
      notifyListeners();
      if (kDebugMode) debugPrint('toggleFavorite error: $e');
      return false;
    }
  }
}
