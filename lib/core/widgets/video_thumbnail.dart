import 'package:flutter/material.dart';

/// Lightweight video thumbnail widget
/// Shows a cached image preview while full video initializes
/// 
/// Benefits:
/// - Fast rendering while scrolling
/// - Placeholder immediately visible
/// - Smooth transition to video player
/// - No video decoding until playback needed
class VideoThumbnail extends StatelessWidget {
  /// Thumbnail image URL (e.g., first frame or poster)
  final String thumbnailUrl;

  /// Size of the thumbnail container
  final double? width;
  final double? height;

  /// Callback when thumbnail is tapped (optional)
  final VoidCallback? onTap;

  /// Show a play icon overlay
  final bool showPlayIcon;

  /// Border radius for rounded corners
  final BorderRadius? borderRadius;

  /// Background color while loading
  final Color backgroundColor;

  const VideoThumbnail({
    super.key,
    required this.thumbnailUrl,
    this.width,
    this.height = 240,
    this.onTap,
    this.showPlayIcon = true,
    this.borderRadius,
    this.backgroundColor = const Color(0xFF000000),
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: borderRadius,
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Thumbnail image with fade-in animation
            Image.network(
              thumbnailUrl,
              fit: BoxFit.cover,
              width: width,
              height: height,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  width: width,
                  height: height,
                  color: backgroundColor,
                  child: const Icon(
                    Icons.image_not_supported,
                    color: Colors.grey,
                    size: 40,
                  ),
                );
              },
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Container(
                  width: width,
                  height: height,
                  color: backgroundColor,
                  child: Center(
                    child: CircularProgressIndicator(
                      value: loadingProgress.expectedTotalBytes != null
                          ? loadingProgress.cumulativeBytesLoaded /
                              loadingProgress.expectedTotalBytes!
                          : null,
                      color: Colors.white.withOpacity(0.7),
                    ),
                  ),
                );
              },
            ),

            // Play icon overlay
            if (showPlayIcon)
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.play_arrow,
                  color: Colors.white,
                  size: 28,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Skeleton loader for video thumbnail while data loads
class VideoThumbnailSkeleton extends StatelessWidget {
  final double? width;
  final double height;
  final BorderRadius? borderRadius;

  const VideoThumbnailSkeleton({
    super.key,
    this.width,
    this.height = 240,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: borderRadius,
      ),
      child: const Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}