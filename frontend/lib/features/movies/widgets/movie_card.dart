import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../../../core/constants.dart';
import '../models/movie.dart';

class MovieCard extends StatefulWidget {
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
  State<MovieCard> createState() => _MovieCardState();
}

class _MovieCardState extends State<MovieCard> {
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
    final w = widget.width ?? AppSizes.cardWidth;
    final h = widget.height ?? AppSizes.cardHeight;

    return Focus(
      onFocusChange: (focused) {
        setState(() => _isFocused = focused);
      },
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: w,
          margin: const EdgeInsets.only(left: AppSizes.paddingM),
          transform: Matrix4.identity()..scale(_isFocused ? 1.05 : 1.0),
          transformAlignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
            border: _isFocused ? Border.all(color: AppColors.primary, width: 3) : null,
            boxShadow: _isFocused
                ? [BoxShadow(color: AppColors.primary.withOpacity(0.5), blurRadius: 15, spreadRadius: 2)]
                : [],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Hero(
                tag: 'poster_${widget.movie.id}',
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
                  child: Stack(
                    children: [
                      SizedBox(
                        width: w,
                        height: h,
                        child: widget.movie.posterUrl.isEmpty
                            ? _placeholder(w, h)
                            : CachedNetworkImage(
                                imageUrl: widget.movie.posterUrl,
                                fit: BoxFit.cover,
                                placeholder: (_, __) => _shimmer(w, h),
                                errorWidget: (_, __, ___) => _placeholder(w, h),
                              ),
                      ),
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
                      if (widget.movie.voteAverage > 0)
                        Positioned(top: 8, right: 8, child: _ratingBadge()),
                      if (widget.movie.isSeries)
                        Positioned(top: 8, left: 8, child: _tvBadge()),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.only(right: 2, left: 2),
                child: Text(
                  widget.movie.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: _isFocused ? AppColors.primaryLight : AppColors.textPrimary,
                    height: 1.3,
                  ),
                ),
              ),
              const SizedBox(height: 2),
              if (widget.movie.year.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(right: 2, left: 2),
                  child: Text(
                    widget.movie.year,
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
      ),
    );
  }

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
            widget.movie.rating,
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
