import 'constants.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'device_id.dart';

class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;
  ApiClient._internal();

  late final Dio _dio = _createDio();

  Dio _createDio() {
    final dio = Dio(
      BaseOptions(
        baseUrl: ApiConstants.baseUrl,
        connectTimeout: ApiConstants.connectTimeout,
        receiveTimeout: ApiConstants.receiveTimeout,
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
      ),
    );

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          // إضافة بصمة الجهاز لكل الطلبات
          try {
            final deviceId = await DeviceIdManager.getDeviceId();
            options.headers['X-Device-ID'] = deviceId;
          } catch (e) {
            if (kDebugMode) debugPrint('Failed to get Device ID: $e');
          }

          if (kDebugMode) {
            debugPrint('-> ${options.method} ${options.uri}');
          }
          handler.next(options);
        },
        onResponse: (response, handler) {
          if (kDebugMode) {
            debugPrint('<- ${response.statusCode}');
          }
          handler.next(response);
        },
        onError: (error, handler) {
          if (kDebugMode) {
            debugPrint('X ${error.requestOptions.uri} -> ${error.message}');
          }
          handler.next(error);
        },
      ),
    );

    return dio;
  }

  Dio get dio => _dio;

  // ============ Movies ============
  Future<Map<String, dynamic>> getPopularMovies({int page = 1, String language = 'ar'}) async {
    final res = await _dio.get(ApiConstants.popularMovies, queryParameters: {'page': page, 'language': language});
    return res.data as Map<String, dynamic>? ?? {};
  }

  Future<Map<String, dynamic>> getTrendingMovies({String timeWindow = 'week'}) async {
    final res = await _dio.get(ApiConstants.trendingMovies, queryParameters: {'time_window': timeWindow});
    return res.data as Map<String, dynamic>? ?? {};
  }

  Future<Map<String, dynamic>> getTopRatedMovies({int page = 1}) async {
    final res = await _dio.get(ApiConstants.topRatedMovies, queryParameters: {'page': page});
    return res.data as Map<String, dynamic>? ?? {};
  }

  Future<Map<String, dynamic>> searchMovies(String query, {int page = 1}) async {
    final res = await _dio.get(ApiConstants.searchMovies, queryParameters: {'q': query, 'page': page});
    return res.data as Map<String, dynamic>? ?? {};
  }

  Future<Map<String, dynamic>> getMovieDetails(int id) async {
    final res = await _dio.get('${ApiConstants.apiPrefix}/movies/$id');
    return res.data as Map<String, dynamic>? ?? {};
  }

  // ============ Series ============
  Future<Map<String, dynamic>> getPopularSeries({int page = 1}) async {
    final res = await _dio.get(ApiConstants.popularSeries, queryParameters: {'page': page});
    return res.data as Map<String, dynamic>? ?? {};
  }

  Future<Map<String, dynamic>> getTrendingSeries({String timeWindow = 'week'}) async {
    final res = await _dio.get(ApiConstants.trendingSeries, queryParameters: {'time_window': timeWindow});
    return res.data as Map<String, dynamic>? ?? {};
  }

  Future<Map<String, dynamic>> searchSeries(String query, {int page = 1}) async {
    final res = await _dio.get(ApiConstants.searchSeries, queryParameters: {'q': query, 'page': page});
    return res.data as Map<String, dynamic>? ?? {};
  }

  Future<Map<String, dynamic>> getSeriesDetails(int id) async {
    final res = await _dio.get('${ApiConstants.apiPrefix}/series/$id');
    return res.data as Map<String, dynamic>? ?? {};
  }

  Future<Map<String, dynamic>> getTurkishSeries({int page = 1}) async {
    final res = await _dio.get('${ApiConstants.apiPrefix}/series/turkish', queryParameters: {'page': page});
    return res.data as Map<String, dynamic>? ?? {};
  }

  Future<Map<String, dynamic>> getIndianSeries({int page = 1}) async {
    final res = await _dio.get('${ApiConstants.apiPrefix}/series/indian', queryParameters: {'page': page});
    return res.data as Map<String, dynamic>? ?? {};
  }

  // ============ Subtitles ============
  Future<Map<String, dynamic>> searchSubtitles({
    required int tmdbId,
    String mediaType = 'movie',
    String language = 'AR',
    int? seasonNumber,
    int? episodeNumber,
  }) async {
    final params = <String, dynamic>{
      'tmdb_id': tmdbId,
      'media_type': mediaType,
      'language': language,
    };
    if (seasonNumber != null) params['season_number'] = seasonNumber;
    if (episodeNumber != null) params['episode_number'] = episodeNumber;

    final res = await _dio.get(ApiConstants.searchSubtitles, queryParameters: params);
    return res.data as Map<String, dynamic>? ?? {};
  }

  Future<List<int>> downloadSubtitle({required String subtitlePath, String filename = 'subtitle.zip'}) async {
    final res = await _dio.post(
      ApiConstants.downloadSubtitle,
      data: {'subtitle_path': subtitlePath, 'filename': filename},
      options: Options(responseType: ResponseType.bytes),
    );
    return res.data as List<int>;
  }


  // دالة الجلب المسبق (صامتة) لتسخين الذاكرة المؤقتة في السيرفر
  Future<void> prefetchStream({
    required int tmdbId,
    String mediaType = 'movie',
    int season = 1,
    int episode = 1,
  }) async {
    try {
      await _dio.get(
        '\${ApiConstants.apiPrefix}/stream/\$tmdbId',
        queryParameters: {
          'media_type': mediaType,
          'season': season,
          'episode': episode,
        },
      ).timeout(const Duration(seconds: 60));
      if (kDebugMode) debugPrint('✅ Prefetch completed for \$tmdbId');
    } catch (e) {
      // نتجاهل الأخطاء بصمت لأنها مجرد عملية جلب مسبق
      if (kDebugMode) debugPrint('Prefetch failed (silent): \$e');
    }
  }

  // ============ Favorites ============
  Future<List<dynamic>> getFavorites() async {
    final res = await _dio.get('${ApiConstants.apiPrefix}/favorites/');
    return res.data as List<dynamic>? ?? [];
  }

  Future<Map<String, dynamic>> addFavorite({
    required int tmdbId,
    required String mediaType,
    required String title,
    String? posterPath,
  }) async {
    final res = await _dio.post(
      '${ApiConstants.apiPrefix}/favorites/',
      data: {
        'tmdb_id': tmdbId,
        'media_type': mediaType,
        'title': title,
        'poster_path': posterPath,
      },
    );
    return res.data as Map<String, dynamic>? ?? {};
  }

  Future<void> removeFavorite({required int tmdbId, required String mediaType}) async {
    await _dio.delete(
      '${ApiConstants.apiPrefix}/favorites/$tmdbId',
      queryParameters: {'media_type': mediaType},
    );
  }
}
