import 'package:addalink/features/auth/auth_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';

import '../feed/post_model.dart';
import 'edit_profile_screen.dart';
import 'profile_controller.dart';

// ─── DESIGN TOKENS ─────────────────────────────────────────────────────────────
const Color backgroundColor = Color(0xFFF7F8FC);
const Color primaryColor = Color(0xFF6C4DFF);
const Color secondaryPurple = Color(0xFF8D7BFF);
const Color textDark = Color(0xFF1B1D28);
const Color textLight = Color(0xFF70758A);
const Color cardColor = Colors.white;

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ProfileController _controller = ProfileController();

  Map<String, dynamic>? profileData;
  List<PostModel> userPosts = [];
  bool isLoading = true;
  String errorMessage = "";

  @override
  void initState() {
    super.initState();
    loadProfile();
  }

  Future<void> loadProfile() async {
    setState(() {
      isLoading = true;
      errorMessage = "";
    });

    try {
      final response = await _controller.getProfile();

      if (response["success"] == true) {
        final rawPosts = (response["posts"] as List?) ?? [];

        setState(() {
          profileData = response;
          userPosts = rawPosts.map((e) => PostModel.fromJson(e)).toList();
          isLoading = false;
        });
      } else {
        setState(() {
          errorMessage = response["message"] ?? "Failed to load profile";
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = e.toString();
        isLoading = false;
      });
    }
  }

  Future<void> handleLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          "Logout",
          style: TextStyle(
            color: textDark,
            fontWeight: FontWeight.w700,
            fontSize: 20,
          ),
        ),
        content: const Text(
          "Are you sure you want to logout?",
          style: TextStyle(color: textLight, fontSize: 15),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel", style: TextStyle(color: textLight)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              "Logout",
              style: TextStyle(
                color: Colors.redAccent,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await FirebaseAuth.instance.signOut();

      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,

          MaterialPageRoute(builder: (_) => AuthScreen()),

          (route) => false,
        );
      }
    }
  }

  Future<void> openEditProfile() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EditProfileScreen(user: profileData!["user"]),
      ),
    );

    if (result == true) {
      await loadProfile();
    }
  }

  void shareProfile() {
    final username = profileData?["username"] ?? "user";
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Sharing @$username's profile…"),
        backgroundColor: primaryColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: backgroundColor,
        body: isLoading
            ? const Center(
                child: CircularProgressIndicator(color: primaryColor),
              )
            : errorMessage.isNotEmpty
            ? _buildError()
            : _buildProfile(),
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: textLight, size: 52),
            const SizedBox(height: 16),
            Text(
              errorMessage,
              style: const TextStyle(color: textLight, fontSize: 15),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            GestureDetector(
              onTap: loadProfile,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [primaryColor, secondaryPurple],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Text(
                  "Retry",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfile() {
    final int totalLikes = (profileData?["totalLikes"] as num?)?.toInt() ?? 0;
    final int totalComments =
        (profileData?["totalComments"] as num?)?.toInt() ?? 0;
    final int postsCount = userPosts.length;

    return RefreshIndicator(
      color: primaryColor,
      onRefresh: loadProfile,
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ─── COVER + APP BAR ─────────────────────────
          SliverToBoxAdapter(
            child: _buildHeader(
              totalLikes: totalLikes,
              totalComments: totalComments,
              postsCount: postsCount,
            ),
          ),

          // ─── SECTION TITLE ───────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 24, 18, 12),
              child: Row(
                children: [
                  const Text(
                    "Posts",
                    style: TextStyle(
                      color: textDark,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      postsCount.toString(),
                      style: const TextStyle(
                        color: primaryColor,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ─── POSTS LIST ──────────────────────────────
          userPosts.isEmpty
              ? SliverToBoxAdapter(child: _buildEmptyPosts())
              : SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    return _buildPostCard(userPosts[index]);
                  }, childCount: userPosts.length),
                ),

          const SliverToBoxAdapter(child: SizedBox(height: 32)),
        ],
      ),
    );
  }

  Widget _buildHeader({
    required int totalLikes,
    required int totalComments,
    required int postsCount,
  }) {
    final user = profileData?["user"] ?? {};

    final String name = user["name"] ?? "AddaLink User";

    final String email = user["email"] ?? "";

    final String bio = user["bio"] ?? "";

    final String photo = user["photo"] ?? "";

    final String username = user["username"] ?? "";

    final String address =
        (user["location"] as Map<String, dynamic>?)?["address"] ?? "";

    final List interests = (user["interests"] as List?) ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ─── COVER BANNER ─────────────────────────────
        Stack(
          clipBehavior: Clip.none,
          children: [
            // GRADIENT COVER
            Container(
              height: 180,
              width: double.infinity,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xFF6C4DFF),
                    Color(0xFF8D7BFF),
                    Color(0xFFB39DFF),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Opacity(
                opacity: 0.15,
                child: Image.network(
                  "https://www.transparenttextures.com/patterns/45-degree-fabric-dark.png",
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const SizedBox(),
                ),
              ),
            ),

            // BACK BUTTON
            Positioned(
              top: 44,
              left: 16,
              child: GestureDetector(
                onTap: () => Navigator.maybePop(context),
                child: Container(
                  height: 40,
                  width: 40,
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.arrow_back_ios_new,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
              ),
            ),

            // LOGOUT BUTTON
            Positioned(
              top: 44,

              right: 16,

              child: GestureDetector(
                onTap: handleLogout,

                child: Container(
                  height: 44,

                  width: 44,

                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.14),

                    borderRadius: BorderRadius.circular(16),

                    border: Border.all(color: Colors.white.withOpacity(0.12)),

                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),

                        blurRadius: 12,

                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),

                  child: const Icon(
                    Icons.power_settings_new_rounded,

                    color: Colors.white,

                    size: 22,
                  ),
                ),
              ),
            ),

            // PROFILE AVATAR
            Positioned(
              bottom: -50,
              left: 20,
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: backgroundColor, width: 4),
                  boxShadow: [
                    BoxShadow(
                      color: primaryColor.withOpacity(0.25),
                      blurRadius: 18,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: CircleAvatar(
                  radius: 46,
                  backgroundColor: primaryColor,
                  backgroundImage: photo.isNotEmpty
                      ? NetworkImage(photo)
                      : null,
                  child: photo.isEmpty
                      ? Text(
                          name.isNotEmpty ? name[0].toUpperCase() : "A",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 32,
                            fontWeight: FontWeight.w700,
                          ),
                        )
                      : null,
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 62),

        // ─── NAME + USERNAME + ACTIONS ─────────────────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        color: textDark,
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (username.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 3),
                        child: Text(
                          "@$username",
                          style: const TextStyle(
                            color: primaryColor,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    if (email.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 3),
                        child: Text(
                          email,
                          style: const TextStyle(
                            color: textLight,
                            fontSize: 13,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // EDIT BUTTON
              GestureDetector(
                onTap: openEditProfile,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [primaryColor, secondaryPurple],
                    ),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: primaryColor.withOpacity(0.25),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Text(
                    "Edit Profile",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // SHARE BUTTON
              GestureDetector(
                onTap: shareProfile,
                child: Container(
                  height: 40,
                  width: 40,
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.share_outlined,
                    color: textLight,
                    size: 18,
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // ─── BIO ───────────────────────────────────────
        if (bio.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              bio,
              style: const TextStyle(
                color: textDark,
                fontSize: 14,
                height: 1.55,
              ),
            ),
          ),

        if (bio.isNotEmpty) const SizedBox(height: 12),

        // ─── LOCATION ─────────────────────────────────
        if (address.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                const Icon(
                  Icons.location_on_outlined,
                  color: primaryColor,
                  size: 16,
                ),
                const SizedBox(width: 5),
                Text(
                  address,
                  style: const TextStyle(
                    color: textLight,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

        if (address.isNotEmpty) const SizedBox(height: 16),

        // ─── STATS ROW ────────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 8),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 18,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildStat(value: postsCount.toString(), label: "Posts"),
                _buildStatDivider(),
                _buildStat(value: totalLikes.toString(), label: "Likes"),
                _buildStatDivider(),
                _buildStat(value: totalComments.toString(), label: "Comments"),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),

        // ─── INTERESTS ────────────────────────────────
        if (interests.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Interests",
                  style: TextStyle(
                    color: textDark,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: interests
                      .map(
                        (i) => Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 7,
                          ),
                          decoration: BoxDecoration(
                            color: primaryColor.withOpacity(0.09),
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(
                              color: primaryColor.withOpacity(0.2),
                            ),
                          ),
                          child: Text(
                            i.toString(),
                            style: const TextStyle(
                              color: primaryColor,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ],
            ),
          ),

        if (interests.isNotEmpty) const SizedBox(height: 4),
      ],
    );
  }

  Widget _buildStat({required String value, required String label}) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              color: textDark,
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: textLight,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatDivider() {
    return Container(height: 36, width: 1, color: Colors.grey.shade200);
  }

  Widget _buildEmptyPosts() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
      child: Column(
        children: [
          Container(
            height: 80,
            width: 80,
            decoration: BoxDecoration(
              color: primaryColor.withOpacity(0.08),
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Icon(
              Icons.photo_library_outlined,
              color: primaryColor,
              size: 36,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            "No posts yet",
            style: TextStyle(
              color: textDark,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            "Share your first moment with\nyour AddaLink community.",
            style: TextStyle(color: textLight, fontSize: 14, height: 1.55),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildPostCard(PostModel post) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // POST HEADER
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: primaryColor,
                  backgroundImage: post.userProfileImage.isNotEmpty
                      ? NetworkImage(post.userProfileImage)
                      : null,
                  child: post.userProfileImage.isEmpty
                      ? Text(
                          post.username.isNotEmpty
                              ? post.username[0].toUpperCase()
                              : "A",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "@${post.username}",
                        style: const TextStyle(
                          color: textDark,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        _formatDate(post.createdAt),
                        style: const TextStyle(color: textLight, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: primaryColor.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    post.postType,
                    style: const TextStyle(
                      color: primaryColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // POST CONTENT
          if (post.content.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
              child: Text(
                post.content,
                style: const TextStyle(
                  color: textDark,
                  fontSize: 14,
                  height: 1.55,
                ),
              ),
            ),

          // IMAGE CAROUSEL
          if (post.postType == "image" && post.images.isNotEmpty)
            _buildImageCarousel(post),

          // VIDEO
          if (post.postType == "video" && post.video.isNotEmpty)
            ClipRRect(
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(22),
                bottomRight: Radius.circular(22),
              ),
              child: ProfileVideoPlayer(videoUrl: post.video),
            ),

          // STATS ROW
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 8, 14, 14),
            child: Row(
              children: [
                _buildPostStat(
                  icon: Icons.favorite_border,
                  label: "${post.likesCount}",
                ),
                const SizedBox(width: 20),
                _buildPostStat(
                  icon: Icons.chat_bubble_outline,
                  label: "${post.commentsCount}",
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageCarousel(PostModel post) {
    return StatefulBuilder(
      builder: (context, setCardState) {
        return Column(
          children: [
            SizedBox(
              height: 220,
              child: PageView.builder(
                onPageChanged: (index) {
                  setCardState(() {
                    post.currentImageIndex = index;
                  });
                },
                itemCount: post.images.length,
                itemBuilder: (context, index) {
                  return ClipRRect(
                    child: Image.network(
                      post.images[index].toString(),
                      fit: BoxFit.cover,
                      width: double.infinity,
                      errorBuilder: (_, __, ___) => Container(
                        color: Colors.grey.shade100,
                        child: const Icon(
                          Icons.image_outlined,
                          color: textLight,
                          size: 40,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            if (post.images.length > 1)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    post.images.length,
                    (i) => AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      height: 6,
                      width: i == post.currentImageIndex ? 18 : 6,
                      decoration: BoxDecoration(
                        color: i == post.currentImageIndex
                            ? primaryColor
                            : Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildPostStat({required IconData icon, required String label}) {
    return Row(
      children: [
        Icon(icon, color: textLight, size: 18),
        const SizedBox(width: 5),
        Text(
          label,
          style: const TextStyle(
            color: textLight,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  String _formatDate(String isoDate) {
    try {
      final dt = DateTime.parse(isoDate).toLocal();
      final now = DateTime.now();
      final diff = now.difference(dt);
      if (diff.inMinutes < 1) return "Just now";
      if (diff.inHours < 1) {
        return "${diff.inMinutes}m ago";
      }
      if (diff.inDays < 1) {
        return "${diff.inHours}h ago";
      }
      if (diff.inDays < 7) {
        return "${diff.inDays}d ago";
      }
      return "${dt.day}/${dt.month}/${dt.year}";
    } catch (_) {
      return isoDate;
    }
  }
}

// ─── PROFILE VIDEO PLAYER ──────────────────────────────────────────────────────
class ProfileVideoPlayer extends StatefulWidget {
  final String videoUrl;

  const ProfileVideoPlayer({super.key, required this.videoUrl});

  @override
  State<ProfileVideoPlayer> createState() => _ProfileVideoPlayerState();
}

class _ProfileVideoPlayerState extends State<ProfileVideoPlayer> {
  late VideoPlayerController _controller;
  bool isInitialized = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl));
    _controller.initialize().then((_) {
      if (mounted) {
        setState(() {
          isInitialized = true;
        });
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!isInitialized) {
      return Container(
        height: 220,
        color: Colors.grey.shade100,
        child: const Center(
          child: CircularProgressIndicator(color: primaryColor),
        ),
      );
    }

    return Stack(
      alignment: Alignment.center,
      children: [
        AspectRatio(
          aspectRatio: _controller.value.aspectRatio,
          child: VideoPlayer(_controller),
        ),
        GestureDetector(
          onTap: () {
            setState(() {
              _controller.value.isPlaying
                  ? _controller.pause()
                  : _controller.play();
            });
          },
          child: CircleAvatar(
            radius: 28,
            backgroundColor: Colors.black45,
            child: Icon(
              _controller.value.isPlaying ? Icons.pause : Icons.play_arrow,
              color: Colors.white,
              size: 30,
            ),
          ),
        ),
      ],
    );
  }
}
