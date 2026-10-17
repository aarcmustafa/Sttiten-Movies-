import 'package:flutter/material.dart';

class ApiConstants {
  static const String baseUrl = 'https://sttiten-movies.onrender.com';
  static const String apiPrefix = '/api/v1';

  static const String popularMovies = '$apiPrefix/movies/popular';
  static const String trendingMovies = '$apiPrefix/movies/trending';
  static const String topRatedMovies = '$apiPrefix/movies/top-rated';
  static const String searchMovies = '$apiPrefix/movies/search';
  static const String popularSeries = '$apiPrefix/series/popular';
  static const String trendingSeries = '$apiPrefix/series/trending';
  static const String searchSeries = '$apiPrefix/series/search';
  static const String searchSubtitles = '$apiPrefix/subtitles/search';
  static const String downloadSubtitle = '$apiPrefix/subtitles/download';

  static const String tmdbImageBase = 'https://image.tmdb.org/t/p';
  static const String posterSize = 'w500';
  static const String backdropSize = 'w1280';

  static String posterUrl(String? path) =>
      path == null ? '' : '$tmdbImageBase/$posterSize$path';

  static String backdropUrl(String? path) =>
      path == null ? '' : '$tmdbImageBase/$backdropSize$path';

  static const Duration connectTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 30);
}

class AppColors {
  static const Color primary = Color(0xFF7C3AED);
  static const Color primaryDark = Color(0xFF5B21B6);
  static const Color primaryLight = Color(0xFFA78BFA);
  static const Color accent = Color(0xFFEC4899);

  static const Color background = Color(0xFF0A0A0F);
  static const Color surface = Color(0xFF15151D);
  static const Color surfaceLight = Color(0xFF1E1E2A);
  static const Color card = Color(0xFF1A1A24);

  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFB8B8C7);
  static const Color textTertiary = Color(0xFF6E6E80);

  static const Color success = Color(0xFF10B981);
  static const Color error = Color(0xFFEF4444);
  static const Color warning = Color(0xFFF59E0B);
  static const Color rating = Color(0xFFFFB800);
}

class AppSizes {
  static const double radiusSmall = 8;
  static const double radiusMedium = 12;
  static const double radiusLarge = 20;
  static const double radiusXL = 28;

  static const double paddingXS = 4;
  static const double paddingS = 8;
  static const double paddingM = 16;
  static const double paddingL = 24;
  static const double paddingXL = 32;

  static const double cardWidth = 140;
  static const double cardHeight = 210;
  static const double heroHeight = 500;
}
