import '../../../core/constants.dart';

class Movie {
  final int id;
  final String title;
  final String? originalTitle;
  final String? overview;
  final String? posterPath;
  final String? backdropPath;
  final String? releaseDate;
  final double voteAverage;
  final int voteCount;
  final double popularity;
  final List<int> genreIds;
  final String? mediaType;

  Movie({
    required this.id,
    required this.title,
    this.originalTitle,
    this.overview,
    this.posterPath,
    this.backdropPath,
    this.releaseDate,
    this.voteAverage = 0.0,
    this.voteCount = 0,
    this.popularity = 0.0,
    this.genreIds = const [],
    this.mediaType,
  });

  factory Movie.fromJson(Map<String, dynamic> json) {
    return Movie(
      id: json['id'] ?? 0,
      title: json['title'] ?? json['name'] ?? 'بدون عنوان',
      originalTitle: json['original_title'] ?? json['original_name'],
      overview: json['overview'],
      posterPath: json['poster_path'],
      backdropPath: json['backdrop_path'],
      releaseDate: json['release_date'] ?? json['first_air_date'],
      voteAverage: (json['vote_average'] ?? 0).toDouble(),
      voteCount: json['vote_count'] ?? 0,
      popularity: (json['popularity'] ?? 0).toDouble(),
      genreIds: List<int>.from(json['genre_ids'] ?? []),
      mediaType: json['media_type'],
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'original_title': originalTitle,
        'overview': overview,
        'poster_path': posterPath,
        'backdrop_path': backdropPath,
        'release_date': releaseDate,
        'vote_average': voteAverage,
        'vote_count': voteCount,
        'popularity': popularity,
        'genre_ids': genreIds,
        'media_type': mediaType,
      };

  String get posterUrl => ApiConstants.posterUrl(posterPath);
  String get backdropUrl => ApiConstants.backdropUrl(backdropPath);

  String get year {
    if (releaseDate == null || releaseDate!.isEmpty) return '';
    return releaseDate!.split('-').first;
  }

  String get rating => voteAverage.toStringAsFixed(1);

  bool get isSeries => mediaType == 'tv' || mediaType == 'series';
}

class MovieDetails extends Movie {
  final int? runtime;
  final List<Genre> genres;
  final List<CastMember> cast;
  final String? tagline;
  final String? status;
  final int? numberOfSeasons;
  final int? numberOfEpisodes;
  final List<Video> videos;
  final List<Movie> recommendations;

  MovieDetails({
    required super.id,
    required super.title,
    super.originalTitle,
    super.overview,
    super.posterPath,
    super.backdropPath,
    super.releaseDate,
    super.voteAverage,
    super.voteCount,
    super.popularity,
    super.genreIds,
    super.mediaType,
    this.runtime,
    this.genres = const [],
    this.cast = const [],
    this.tagline,
    this.status,
    this.numberOfSeasons,
    this.numberOfEpisodes,
    this.videos = const [],
    this.recommendations = const [],
  });

  factory MovieDetails.fromJson(Map<String, dynamic> json) {
    final credits = json['credits'] as Map<String, dynamic>?;
    final castList = credits?['cast'] as List<dynamic>? ?? [];
    final runtimeList = json['episode_run_time'] as List<dynamic>?;

    return MovieDetails(
      id: json['id'] ?? 0,
      title: json['title'] ?? json['name'] ?? '',
      originalTitle: json['original_title'] ?? json['original_name'],
      overview: json['overview'],
      posterPath: json['poster_path'],
      backdropPath: json['backdrop_path'],
      releaseDate: json['release_date'] ?? json['first_air_date'],
      voteAverage: (json['vote_average'] ?? 0).toDouble(),
      voteCount: json['vote_count'] ?? 0,
      popularity: (json['popularity'] ?? 0).toDouble(),
      mediaType: json['media_type'] ?? (json['first_air_date'] != null ? 'tv' : 'movie'),
      runtime: json['runtime'] ?? (runtimeList != null && runtimeList.isNotEmpty ? runtimeList.first : null),
      genres: (json['genres'] as List<dynamic>? ?? [])
          .map((g) => Genre.fromJson(g))
          .toList(),
      cast: castList
          .take(15)
          .map((c) => CastMember.fromJson(c))
          .toList(),
      tagline: json['tagline'],
      status: json['status'],
      numberOfSeasons: json['number_of_seasons'],
      numberOfEpisodes: json['number_of_episodes'],
      videos: (json['videos']?['results'] as List<dynamic>? ?? [])
          .map((v) => Video.fromJson(v))
          .where((v) => v.site == 'YouTube')
          .toList(),
      recommendations: (json['recommendations']?['results'] as List<dynamic>? ?? [])
          .map((r) => Movie.fromJson(r))
          .toList(),
    );
  }

  String get runtimeFormatted {
    if (runtime == null || runtime == 0) return '';
    final h = runtime! ~/ 60;
    final m = runtime! % 60;
    if (h > 0) return '$h س $m د';
    return '$m دقيقة';
  }
}

class Genre {
  final int id;
  final String name;

  Genre({required this.id, required this.name});

  factory Genre.fromJson(Map<String, dynamic> json) => Genre(
        id: json['id'] ?? 0,
        name: json['name'] ?? '',
      );
}

class CastMember {
  final int id;
  final String name;
  final String? character;
  final String? profilePath;

  CastMember({
    required this.id,
    required this.name,
    this.character,
    this.profilePath,
  });

  factory CastMember.fromJson(Map<String, dynamic> json) => CastMember(
        id: json['id'] ?? 0,
        name: json['name'] ?? '',
        character: json['character'],
        profilePath: json['profile_path'],
      );

  String get profileUrl => profilePath == null
      ? ''
      : '${ApiConstants.tmdbImageBase}/w200$profilePath';
}

class Video {
  final String id;
  final String key;
  final String site;
  final String type;

  Video({required this.id, required this.key, required this.site, required this.type});

  factory Video.fromJson(Map<String, dynamic> json) => Video(
        id: json['id'] ?? '',
        key: json['key'] ?? '',
        site: json['site'] ?? '',
        type: json['type'] ?? '',
      );
}


