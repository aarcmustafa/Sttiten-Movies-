import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'constants.dart';

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
        onRequest: (options, handler) {
          if (kDebugMode) {
            debugPrint('→ ${options.method} ${options.uri}');
          }
          handler.next(options);
        },
        onResponse: (response, handler) {
          if (kDebugMode) {
            debugPrint('← ${response.statusCode} ${response.requestOptions.uri}');
          }
          handler.next(response);
        },
        onError: (error, handler) {
          if (kDebugMode) {
            debugPrint('✗ ${error.requestOptions.uri} → ${error.message}');
          }
          handler.next(error);
        },
      ),
    );

    return dio;
  }

  Dio get dio => _dio;

  // ============ Movies ============

  Future<Map<String, dynamic>> getPopularMovies({
    int page = 1,
    String language = 'ar',
  }) async {
    final res = await _dio.get(
      ApiConstants.popularMovies,
      queryParameters: {'page': page, 'language': language},
    );
    return res.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getTrendingMovies({
    String timeWindow = 'week',
  }) async {
    final res = await _dio.get(
      ApiConstants.trendingMovies,
      queryParameters: {'time_window': timeWindow},
    );
    return res.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getTopRatedMovies({int page = 1}) async {
    final res = await _dio.get(
      ApiConstants.topRatedMovies,
      queryParameters: {'page': page},
    );
    return res.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> searchMovies(String query, {int page = 1}) async {
    final res = await _dio.get(
      ApiConstants.searchMovies,
      queryParameters: {'q': query, 'page': page},
    );
    return res.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getMovieDetails(int id) async {
    final res = await _dio.get('${ApiConstants.apiPrefix}/movies/$id');
    return res.data as Map<String, dynamic>;
  }

  // ============ Series ============

  Future<Map<String, dynamic>> getPopularSeries({int page = 1}) async {
    final res = await _dio.get(
      ApiConstants.popularSeries,
      queryParameters: {'page': page},
    );
    return res.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getTrendingSeries({
    String timeWindow = 'week',
  }) async {
    final res = await _dio.get(
      ApiConstants.trendingSeries,
      queryParameters: {'time_window': timeWindow},
    );
    return res.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> searchSeries(String query, {int page = 1}) async {
    final res = await _dio.get(
      ApiConstants.searchSeries,
      queryParameters: {'q': query, 'page': page},
    );
    return res.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getSeriesDetails(int id) async {
    final res = await _dio.get('${ApiConstants.apiPrefix}/series/$id');
    return res.data as Map<String, dynamic>;
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

    final res = await _dio.get(
      ApiConstants.searchSubtitles,
      queryParameters: params,
    );
    return res.data as Map<String, dynamic>;
  }

  Future<List<int>> downloadSubtitle({
    required String subtitlePath,
    String filename = 'subtitle.zip',
  }) async {
    final res = await _dio.post(
      ApiConstants.downloadSubtitle,
      data: {
        'subtitle_path': subtitlePath,
        'filename': filename,
      },
      options: Options(responseType: ResponseType.bytes),
    );
    return res.data as List<int>;
  }
}
