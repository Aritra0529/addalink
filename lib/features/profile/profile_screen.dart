import 'package:addalink/features/auth/auth_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'profile_controller.dart';
import 'edit_profile_screen.dart';
import '../feed/post_model.dart';

// ── Palette (light / glassmorphism) ─────────────────────
const Color _bg         = Color(0xFFF0F2FF);   // soft lavender-white canvas
const Color _primary    = Color(0xFF6C4DFF);   // brand violet
const Color _secondary  = Color(0xFF9B83FF);   // lighter violet
const Color _dark       = Color(0xFF1B1D2E);   // near-black text
const Color _body       = Color(0xFF4A4C63);   // body text
const Color _muted      = Color(0xFF9496AB);   // secondary labels
const Color _white      = Colors.white;
const Color _like       = Color(0xFFFF4F7B);
const Color _cmnt       = Color(0xFF2196F3);

// glassmorphism helpers
const Color _glassWhite = Color(0xBBFFFFFF);   // 73 % white fill
const Color _glassBorder = Color(0x55FFFFFF);  // subtle white border
const Color _glassShadow = Color(0x14000000);

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  final ProfileController _controller = ProfileController();

  Map<String, dynamic>? userData;
  List<PostModel> userPosts = [];
  int totalLikes    = 0;
  int totalComments = 0;
  int postsCount    = 0;
  bool isLoading    = true;

  late AnimationController _fadeCtrl;
  late Animation<double>   _fadeAnim;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700));
    _fadeAnim =
        CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOutCubic);
    _loadProfile();
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    setState(() => isLoading = true);
    try {
      final res = await _controller.getProfile();
      if (res["success"] == true) {
        final List raw = res["posts"] ?? [];
        if (mounted) {
          setState(() {
            userData      = res["user"];
            userPosts     = raw.map((e) => PostModel.fromJson(e)).toList();
            totalLikes    = res["totalLikes"]    ?? 0;
            totalComments = res["totalComments"] ?? 0;
            postsCount    = res["postsCount"]    ?? 0;
          });
          _fadeCtrl.forward(from: 0);
        }
      }
    } catch (e) {
      debugPrint("Profile load error: $e");
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => AuthScreen()),
      (route) => false,
    );
  }

  // ── ROOT BUILD ────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: _bg,
        body: Stack(
          children: [
            // Ambient gradient blobs in the background
            _ambientBlobs(),

            if (isLoading)
              const Center(
                child: CircularProgressIndicator(color: _primary, strokeWidth: 2.5),
              )
            else
              FadeTransition(
                opacity: _fadeAnim,
                child: RefreshIndicator(
                  color: _primary,
                  backgroundColor: _white,
                  onRefresh: _loadProfile,
                  child: CustomScrollView(
                    physics: const BouncingScrollPhysics(),
                    slivers: [
                      _buildAppBar(),
                      SliverToBoxAdapter(child: _buildProfileHeader()),
                      userPosts.isEmpty
                          ? SliverToBoxAdapter(child: _buildEmptyPosts())
                          : SliverPadding(
                              padding:
                                  const EdgeInsets.fromLTRB(18, 4, 18, 0),
                              sliver: SliverList(
                                delegate: SliverChildBuilderDelegate(
                                  (ctx, i) => _buildPostCard(userPosts[i]),
                                  childCount: userPosts.length,
                                ),
                              ),
                            ),
                      const SliverToBoxAdapter(child: SizedBox(height: 52)),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // soft gradient orbs that give the glassmorphism its glow
  Widget _ambientBlobs() {
    return Stack(
      children: [
        Positioned(
          top: -60,
          left: -60,
          child: _blob(220, const Color(0x336C4DFF)),
        ),
        Positioned(
          top: 160,
          right: -80,
          child: _blob(200, const Color(0x339B83FF)),
        ),
        Positioned(
          top: 360,
          left: 40,
          child: _blob(160, const Color(0x22B2A6FF)),
        ),
      ],
    );
  }

  Widget _blob(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
      ),
    );
  }

  // ── APP BAR ───────────────────────────────────────────
  Widget _buildAppBar() {
    return SliverAppBar(
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      pinned: true,
      centerTitle: true,
      flexibleSpace: ClipRect(
        child: Container(
          decoration: const BoxDecoration(
            color: Color(0xB0F0F2FF), // frosted-glass bar
          ),
        ),
      ),
      title: Text(
        userData?["username"] ?? "Profile",
        style: const TextStyle(
          color: _dark,
          fontWeight: FontWeight.w800,
          fontSize: 16,
          letterSpacing: 0.2,
        ),
      ),
      actions: [
        _barBtn(
          icon: Icons.edit_rounded,
          onTap: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    EditProfileScreen(userData: userData ?? {}),
              ),
            );
            _loadProfile();
          },
        ),
        // Cool door-with-arrow logout icon
        _barBtn(
          icon: Icons.logout_rounded,
          onTap: _logout,
          isDestructive: true,
        ),
        const SizedBox(width: 6),
      ],
    );
  }

  Widget _barBtn({
    required IconData icon,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 9),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isDestructive
              ? const Color(0x15FF4F7B)
              : _glassWhite,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDestructive
                ? const Color(0x44FF4F7B)
                : _glassBorder,
          ),
          boxShadow: [
            BoxShadow(
              color: _glassShadow,
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Icon(
          icon,
          color: isDestructive ? _like : _primary,
          size: 17,
        ),
      ),
    );
  }

  // ── PROFILE HEADER ────────────────────────────────────
  Widget _buildProfileHeader() {
    final photo    = userData?["photo"]    ?? "";
    final name     = userData?["name"]     ?? "";
    final username = userData?["username"] ?? "";
    final bio      = userData?["bio"]      ?? "";
    final location = userData?["location"];
    final address  = location is Map ? location["address"] ?? "" : "";
    final interests = List<String>.from(userData?["interests"] ?? []);

    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 10),
      child: Column(
        children: [
          // ── Glass hero card ──
          _glassCard(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                // Avatar with gradient ring
                Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 106,
                      height: 106,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: SweepGradient(
                          colors: [_primary, _secondary, Color(0xFFD3C9FF), _primary],
                        ),
                      ),
                    ),
                    Container(
                      width: 98,
                      height: 98,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: _white,
                      ),
                    ),
                    CircleAvatar(
                      radius: 44,
                      backgroundColor: const Color(0xFFEDE9FF),
                      backgroundImage:
                          photo.isNotEmpty ? NetworkImage(photo) : null,
                      child: photo.isEmpty
                          ? const Icon(Icons.person_rounded,
                              color: _primary, size: 38)
                          : null,
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                Text(
                  name,
                  style: const TextStyle(
                    color: _dark,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.4,
                  ),
                ),

                const SizedBox(height: 6),

                // Username pill
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [_primary, _secondary],
                    ),
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: _primary.withOpacity(0.35),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Text(
                    "@$username",
                    style: const TextStyle(
                      color: _white,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),

                if (bio.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  Text(
                    bio,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: _body,
                      fontSize: 14,
                      height: 1.6,
                    ),
                  ),
                ],

                if (address.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.location_on_rounded,
                          color: _primary, size: 13),
                      const SizedBox(width: 4),
                      Text(address,
                          style:
                              const TextStyle(color: _muted, fontSize: 13)),
                    ],
                  ),
                ],

                const SizedBox(height: 22),

                // Stats
                _buildStatsRow(),
              ],
            ),
          ),

          // ── Interests ──
          if (interests.isNotEmpty) ...[
            const SizedBox(height: 14),
            _glassCard(
              padding:
                  const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 3,
                        height: 14,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                              colors: [_primary, _secondary],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        "Interests",
                        style: TextStyle(
                          color: _dark,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: interests.map((tag) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 7),
                        decoration: BoxDecoration(
                          color: _primary.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(
                              color: _primary.withOpacity(0.22)),
                        ),
                        child: Text(
                          tag,
                          style: const TextStyle(
                            color: _primary,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ],

          // Posts section label
          if (userPosts.isNotEmpty) ...[
            const SizedBox(height: 20),
            Row(
              children: [
                Container(
                  width: 3,
                  height: 16,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                        colors: [_primary, _secondary],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  "Posts",
                  style: TextStyle(
                    color: _dark,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 4),
        ],
      ),
    );
  }

  Widget _buildStatsRow() {
    return Container(
      decoration: BoxDecoration(
        color: _primary.withOpacity(0.06),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _primary.withOpacity(0.12)),
      ),
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _statCell("$postsCount", "Posts", _primary),
          _vDivider(),
          _statCell("$totalLikes", "Likes", _like),
          _vDivider(),
          _statCell("$totalComments", "Comments", _cmnt),
        ],
      ),
    );
  }

  Widget _statCell(String val, String label, Color color) {
    return Column(
      children: [
        Text(
          val,
          style: TextStyle(
            color: color,
            fontSize: 21,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.4,
          ),
        ),
        const SizedBox(height: 3),
        Text(label,
            style: const TextStyle(color: _muted, fontSize: 12)),
      ],
    );
  }

  Widget _vDivider() =>
      Container(width: 1, height: 36, color: _primary.withOpacity(0.15));

  // ── EMPTY STATE ───────────────────────────────────────
  Widget _buildEmptyPosts() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 40),
      child: Column(
        children: [
          Container(
            height: 80,
            width: 80,
            decoration: BoxDecoration(
              color: _primary.withOpacity(0.08),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: _primary.withOpacity(0.2)),
            ),
            child: const Icon(Icons.grid_off_outlined,
                color: _primary, size: 34),
          ),
          const SizedBox(height: 18),
          const Text("No posts yet",
              style: TextStyle(
                  color: _dark,
                  fontSize: 17,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          const Text(
            "Share something with your locality\nand it will appear here.",
            textAlign: TextAlign.center,
            style: TextStyle(color: _muted, fontSize: 14, height: 1.6),
          ),
        ],
      ),
    );
  }

  // ── POST CARD ─────────────────────────────────────────
  Widget _buildPostCard(PostModel post) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: _glassCard(
        padding: EdgeInsets.zero,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (post.images.isNotEmpty)
              ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(20)),
                child: Image.network(
                  List<String>.from(post.images).first,
                  height: 195,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (post.content.isNotEmpty)
                    Text(
                      post.content,
                      style: const TextStyle(
                        color: _dark,
                        fontSize: 14,
                        height: 1.6,
                      ),
                    ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      _postStat(Icons.favorite_rounded,
                          "${post.likesCount}", _like),
                      const SizedBox(width: 14),
                      _postStat(Icons.mode_comment_rounded,
                          "${post.commentsCount}", _cmnt),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: _primary.withOpacity(0.07),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          _timeAgo(post.createdAt),
                          style: const TextStyle(
                              color: _muted, fontSize: 11),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _postStat(IconData icon, String count, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 15),
        const SizedBox(width: 4),
        Text(count,
            style: const TextStyle(color: _body, fontSize: 13)),
      ],
    );
  }

  // ── GLASS CARD HELPER ─────────────────────────────────
  Widget _glassCard({required Widget child, required EdgeInsets padding}) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: _glassWhite,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _glassBorder, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: _primary.withOpacity(0.07),
            blurRadius: 24,
            spreadRadius: 0,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: _glassShadow,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }

  // ── HELPERS ───────────────────────────────────────────
  String _timeAgo(String iso) {
    try {
      final d    = DateTime.parse(iso).toLocal();
      final diff = DateTime.now().difference(d);
      if (diff.inMinutes < 60) return "${diff.inMinutes}m ago";
      if (diff.inHours   < 24) return "${diff.inHours}h ago";
      return "${diff.inDays}d ago";
    } catch (_) {
      return "";
    }
  }
}