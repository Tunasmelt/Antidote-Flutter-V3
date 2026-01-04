import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../utils/theme.dart';

/// Optimized network image widget with size constraints and caching
/// Prevents loading full-resolution images unnecessarily
class OptimizedNetworkImage extends StatelessWidget {
  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Widget? placeholder;
  final Widget? errorWidget;
  final BorderRadius? borderRadius;

  const OptimizedNetworkImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.placeholder,
    this.errorWidget,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: borderRadius ?? BorderRadius.zero,
      child: CachedNetworkImage(
        imageUrl: imageUrl,
        width: width,
        height: height,
        fit: fit,
        // Optimize image loading with size constraints
        maxWidthDiskCache: (width?.toInt() ?? 500) * 2, // 2x for retina
        maxHeightDiskCache: (height?.toInt() ?? 500) * 2,
        // Placeholder
        placeholder: (context, url) =>
            placeholder ??
            Container(
              width: width,
              height: height,
              color: AppTheme.cardBackground,
              child: const Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor:
                        AlwaysStoppedAnimation<Color>(AppTheme.textMuted),
                  ),
                ),
              ),
            ),
        // Error widget
        errorWidget: (context, url, error) =>
            errorWidget ??
            Container(
              width: width,
              height: height,
              color: AppTheme.cardBackground,
              child: const Icon(
                Icons.music_note,
                color: AppTheme.textMuted,
                size: 32,
              ),
            ),
      ),
    );
  }
}

/// Album art widget with optimized loading
class AlbumArtImage extends StatelessWidget {
  final String? imageUrl;
  final double size;
  final BorderRadius? borderRadius;

  const AlbumArtImage({
    super.key,
    required this.imageUrl,
    this.size = 60,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    if (imageUrl == null || imageUrl!.isEmpty) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: AppTheme.cardBackground,
          borderRadius: borderRadius ?? BorderRadius.circular(8),
        ),
        child: Icon(
          Icons.music_note,
          color: AppTheme.textMuted,
          size: size * 0.5,
        ),
      );
    }

    return OptimizedNetworkImage(
      imageUrl: imageUrl!,
      width: size,
      height: size,
      borderRadius: borderRadius ?? BorderRadius.circular(8),
      fit: BoxFit.cover,
    );
  }
}

/// Artist/Playlist cover image with circular clipping
class CircularCoverImage extends StatelessWidget {
  final String? imageUrl;
  final double size;

  const CircularCoverImage({
    super.key,
    required this.imageUrl,
    this.size = 60,
  });

  @override
  Widget build(BuildContext context) {
    if (imageUrl == null || imageUrl!.isEmpty) {
      return Container(
        width: size,
        height: size,
        decoration: const BoxDecoration(
          color: AppTheme.cardBackground,
          shape: BoxShape.circle,
        ),
        child: Icon(
          Icons.person,
          color: AppTheme.textMuted,
          size: size * 0.5,
        ),
      );
    }

    return OptimizedNetworkImage(
      imageUrl: imageUrl!,
      width: size,
      height: size,
      borderRadius: BorderRadius.circular(size / 2),
      fit: BoxFit.cover,
    );
  }
}
