// lib/shared/widgets/skeleton_widgets.dart
//
// Reusable shimmer-style skeleton placeholders for AddaLink.
// Drop-in replacements for CircularProgressIndicator while data loads.
// No external packages required — built entirely with Flutter core.
//
// Usage:
//   FeedSkeletonList()          → Feed screen initial load
//   ProfileSkeleton()           → Profile screen initial load
//   NotificationSkeletonList()  → Notification screen initial load

import 'package:flutter/material.dart';

// ─────────────────────────────────────────────────────────────────────────────
// SHIMMER ANIMATION BASE
// ─────────────────────────────────────────────────────────────────────────────

/// Wraps any child with a looping left-to-right shimmer gradient animation.
class _Shimmer extends StatefulWidget {
  final Widget child;

  const _Shimmer({required this.child});

  @override
  State<_Shimmer> createState() => _ShimmerState();
}

class _ShimmerState extends State<_Shimmer>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
    _anim = Tween<double>(begin: -1.5, end: 2.5).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOutSine),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, child) => ShaderMask(
        blendMode: BlendMode.srcATop,
        shaderCallback: (bounds) => LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: const [
            Color(0xFFE8EAF2),
            Color(0xFFF4F5FB),
            Color(0xFFFFFFFF),
            Color(0xFFF4F5FB),
            Color(0xFFE8EAF2),
          ],
          stops: const [0.0, 0.3, 0.5, 0.7, 1.0],
          transform: _SlidingGradientTransform(slidePercent: _anim.value),
        ).createShader(bounds),
        child: child!,
      ),
      child: widget.child,
    );
  }
}

class _SlidingGradientTransform extends GradientTransform {
  final double slidePercent;

  const _SlidingGradientTransform({required this.slidePercent});

  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) {
    return Matrix4.translationValues(bounds.width * slidePercent, 0, 0);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PRIMITIVE SKELETON SHAPES
// ─────────────────────────────────────────────────────────────────────────────

/// A rounded rectangle placeholder box.
class _SkeletonBox extends StatelessWidget {
  final double width;
  final double height;
  final double radius;

  const _SkeletonBox({
    required this.width,
    required this.height,
    this.radius = 8,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: const Color(0xFFE8EAF2),
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

/// A circle placeholder for avatars.
class _SkeletonCircle extends StatelessWidget {
  final double radius;

  const _SkeletonCircle({required this.radius});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: radius * 2,
      height: radius * 2,
      decoration: const BoxDecoration(
        color: Color(0xFFE8EAF2),
        shape: BoxShape.circle,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// FEED SKELETON — mirrors the PostCard layout
// ─────────────────────────────────────────────────────────────────────────────

/// One skeleton post card — matches the shape of a real feed post card.
class _FeedPostSkeleton extends StatelessWidget {
  const _FeedPostSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: avatar + username + time
          Row(
            children: [
              const _SkeletonCircle(radius: 22),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  _SkeletonBox(width: 100, height: 13, radius: 6),
                  SizedBox(height: 6),
                  _SkeletonBox(width: 60, height: 11, radius: 6),
                ],
              ),
              const Spacer(),
              const _SkeletonBox(width: 24, height: 24, radius: 6),
            ],
          ),

          const SizedBox(height: 14),

          // Content lines
          const _SkeletonBox(width: double.infinity, height: 13, radius: 6),
          const SizedBox(height: 8),
          const _SkeletonBox(width: double.infinity, height: 13, radius: 6),
          const SizedBox(height: 8),
          const _SkeletonBox(width: 200, height: 13, radius: 6),

          const SizedBox(height: 14),

          // Image placeholder (tall card)
          const _SkeletonBox(
            width: double.infinity,
            height: 180,
            radius: 14,
          ),

          const SizedBox(height: 14),

          // Action row: like + comment + share
          Row(
            children: const [
              _SkeletonBox(width: 56, height: 32, radius: 12),
              SizedBox(width: 10),
              _SkeletonBox(width: 56, height: 32, radius: 12),
              Spacer(),
              _SkeletonBox(width: 32, height: 32, radius: 12),
            ],
          ),
        ],
      ),
    );
  }
}

/// A scrollable list of [_FeedPostSkeleton] cards for the feed screen.
/// Shown while [isLoading] is true in HomeFeedScreen.
class FeedSkeletonList extends StatelessWidget {
  /// Number of skeleton cards to show (default 4 — fills most screens).
  final int itemCount;

  const FeedSkeletonList({super.key, this.itemCount = 4});

  @override
  Widget build(BuildContext context) {
    return _Shimmer(
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        child: Column(
          children: List.generate(
            itemCount,
            (_) => const _FeedPostSkeleton(),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PROFILE SKELETON — mirrors the profile header + post cards
// ─────────────────────────────────────────────────────────────────────────────

class _ProfileHeaderSkeleton extends StatelessWidget {
  const _ProfileHeaderSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(18, 12, 18, 8),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.73),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0x55FFFFFF)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Avatar ring + circle
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 106,
                height: 106,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFE8EAF2),
                ),
              ),
              const _SkeletonCircle(radius: 44),
            ],
          ),

          const SizedBox(height: 16),

          // Name
          const _SkeletonBox(width: 140, height: 16, radius: 8),
          const SizedBox(height: 10),

          // Username pill
          const _SkeletonBox(width: 90, height: 26, radius: 12),
          const SizedBox(height: 16),

          // Bio lines
          const _SkeletonBox(width: double.infinity, height: 12, radius: 6),
          const SizedBox(height: 8),
          const _SkeletonBox(width: 220, height: 12, radius: 6),
          const SizedBox(height: 20),

          // Stats row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: const [
              _SkeletonBox(width: 64, height: 48, radius: 14),
              _SkeletonBox(width: 64, height: 48, radius: 14),
              _SkeletonBox(width: 64, height: 48, radius: 14),
            ],
          ),
        ],
      ),
    );
  }
}

class _ProfilePostSkeleton extends StatelessWidget {
  const _ProfilePostSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.73),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0x55FFFFFF)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const _SkeletonCircle(radius: 20),
              const SizedBox(width: 10),
              const _SkeletonBox(width: 80, height: 12, radius: 6),
              const Spacer(),
              const _SkeletonBox(width: 50, height: 12, radius: 6),
            ],
          ),
          const SizedBox(height: 12),
          const _SkeletonBox(width: double.infinity, height: 12, radius: 6),
          const SizedBox(height: 8),
          const _SkeletonBox(width: 180, height: 12, radius: 6),
          const SizedBox(height: 12),
          const _SkeletonBox(
            width: double.infinity,
            height: 140,
            radius: 12,
          ),
          const SizedBox(height: 12),
          Row(
            children: const [
              _SkeletonBox(width: 52, height: 28, radius: 10),
              SizedBox(width: 8),
              _SkeletonBox(width: 52, height: 28, radius: 10),
            ],
          ),
        ],
      ),
    );
  }
}

/// Full profile screen skeleton: header + post list.
/// Shown while [isLoading] is true in ProfileScreen.
class ProfileSkeleton extends StatelessWidget {
  final int postCount;

  const ProfileSkeleton({super.key, this.postCount = 3});

  @override
  Widget build(BuildContext context) {
    return _Shimmer(
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _ProfileHeaderSkeleton(),

            // Section label placeholder
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 8, 18, 12),
              child: const _SkeletonBox(width: 80, height: 14, radius: 6),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: Column(
                children: List.generate(
                  postCount,
                  (_) => const _ProfilePostSkeleton(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// NOTIFICATION SKELETON — mirrors NotificationTile layout
// ─────────────────────────────────────────────────────────────────────────────

class _NotificationTileSkeleton extends StatelessWidget {
  const _NotificationTileSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE8EAF2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Avatar + badge stack
          Stack(
            children: [
              const _SkeletonCircle(radius: 24),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  width: 20,
                  height: 20,
                  decoration: const BoxDecoration(
                    color: Color(0xFFE8EAF2),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(width: 14),

          // Text content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: const [
                    _SkeletonBox(width: 90, height: 12, radius: 6),
                    SizedBox(width: 6),
                    _SkeletonBox(width: 40, height: 12, radius: 6),
                    Spacer(),
                    _SkeletonBox(width: 36, height: 10, radius: 5),
                  ],
                ),
                const SizedBox(height: 8),
                const _SkeletonBox(width: double.infinity, height: 11, radius: 6),
                const SizedBox(height: 6),
                const _SkeletonBox(width: 160, height: 11, radius: 6),
              ],
            ),
          ),

          const SizedBox(width: 12),

          // Thumbnail placeholder
          const _SkeletonBox(width: 44, height: 44, radius: 12),
        ],
      ),
    );
  }
}

/// Scrollable list of [_NotificationTileSkeleton] items.
/// Shown while [_isLoading] is true in NotificationScreen.
class NotificationSkeletonList extends StatelessWidget {
  final int itemCount;

  const NotificationSkeletonList({super.key, this.itemCount = 7});

  @override
  Widget build(BuildContext context) {
    return _Shimmer(
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        child: Column(
          children: List.generate(
            itemCount,
            (_) => const _NotificationTileSkeleton(),
          ),
        ),
      ),
    );
  }
}