import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../../../core/constants.dart';
import '../models/movie.dart';

class MovieCard extends StatelessWidget {
  final Movie movie;
  final VoidCallback? onTap;
  final double? width;
  final double? height;

  const MovieCard({
    super.key,
    required this.movie,
    this.onTap,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    final w = width ?? AppSizes.cardWidth;
    final h = height ?? AppSizes.cardHeight;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: w,
        margin: const EdgeInsets.only(left: AppSizes.paddingM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ===== Poster with overlay =====
            Hero(
              tag: 'poster_${movie.id}',
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
                child: Stack(
                  children: [
                    // Poster
                    SizedBox(
                      width: w,
                      height: h,
                      child: movie.posterUrl.isEmpty
                          ? _placeholder(w, h)
                          : CachedNetworkImage(
                              imageUrl: movie.posterUrl,
                              fit: BoxFit.cover,
                              placeholder: (_, __) => _shimmer(w, h),
                              errorWidget: (_, __, ___) => _placeholder(w, h),
                            ),
                    ),

                    // Bottom gradient
                    Positioned.fill(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withOpacity(0.0),
                              Colors.black.withOpacity(0.75),
                            ],
                            stops: const [0.5, 0.7, 1.0],
                          ),
                        ),
                      ),
                    ),

                    // Rating badge
                    if (movie.voteAverage > 0)
                      Positioned(
                        top: 8,
                        right: 8,
                        child: _ratingBadge(),
                      ),

                    // Media type badge (TV)
                    if (movie.isSeries)
                      Positioned(
                        top: 8,
                        left: 8,
                        child: _tvBadge(),
                      ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 8),

            // ===== Title =====
            Padding(
              padding: const EdgeInsets.only(right: 2, left: 2),
              child: Text(
                movie.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                  height: 1.3,
                ),
              ),
            ),

            const SizedBox(height: 2),

            // ===== Year =====
            if (movie.year.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(right: 2, left: 2),
                child: Text(
                  movie.year,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textTertiary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ===== Rating badge =====
  Widget _ratingBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.7),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppColors.rating.withOpacity(0.4),
          width: 0.8,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.star_rounded, size: 12, color: AppColors.rating),
          const SizedBox(width: 3),
          Text(
            movie.rating,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  // ===== TV badge =====
  Widget _tvBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(6),
      ),
      child: const Text(
        'مسلسل',
        style: TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  // ===== Shimmer =====
  Widget _shimmer(double w, double h) {
    return Shimmer.fromColors(
      baseColor: AppColors.surfaceLight,
      highlightColor: AppColors.card,
      child: Container(
        width: w,
        height: h,
        color: AppColors.surfaceLight,
      ),
    );
  }

  // ===== Placeholder =====
  Widget _placeholder(double w, double h) {
    return Container(
      width: w,
      height: h,
      color: AppColors.surfaceLight,
      child: const Center(
        child: Icon(
          Icons.movie_outlined,
          color: AppColors.textTertiary,
          size: 36,
        ),
      ),
    );
  }
}

// ============ Horizontal List ============
class MovieCardHorizontal extends StatelessWidget {
  final Movie movie;
  final VoidCallback? onTap;

  const MovieCardHorizontal({
    super.key,
    required this.movie,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: AppSizes.paddingM, vertical: 6),
        height: 110,
        child: Row(
          children: [
            // Poster
            ClipRRect(
              borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
              child: SizedBox(
                width: 75,
                height: 110,
                child: movie.posterUrl.isEmpty
                    ? Container(color: AppColors.surfaceLight)
                    : CachedNetworkImage(
                        imageUrl: movie.posterUrl,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => Container(color: AppColors.surfaceLight),
                        errorWidget: (_, __, ___) => Container(
                          color: AppColors.surfaceLight,
                          child: const Icon(Icons.movie_outlined,
                              color: AppColors.textTertiary),
                        ),
                      ),
              ),
            ),
            const SizedBox(width: 12),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    movie.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      if (movie.year.isNotEmpty) ...[
                        Text(
                          movie.year,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textTertiary,
                          ),
                        ),
                        const SizedBox(width: 10),
                      ],
                      const Icon(Icons.star_rounded,
                          size: 14, color: AppColors.rating),
                      const SizedBox(width: 3),
                      Text(
                        movie.rating,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  if (movie.overview != null && movie.overview!.isNotEmpty)
                    Text(
                      movie.overview!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textTertiary,
                        height: 1.4,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
