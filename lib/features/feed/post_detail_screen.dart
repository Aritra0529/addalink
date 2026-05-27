import 'package:addalink/features/profile/profile_controller.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';

import 'feed_controller.dart';
import 'post_model.dart';

const Color _bg = Color(0xFFF7F8FC);
const Color _primary = Color(0xFF6C4DFF);
const Color _secondaryPurple = Color(0xFF8D7BFF);
const Color _dark = Color(0xFF1B1D28);
const Color _light = Color(0xFF70758A);
const Color _card = Colors.white;

class PostDetailScreen
    extends StatefulWidget {

  final String postId;

  // When true the comments sheet opens automatically after load
  final bool openComments;

  const PostDetailScreen({

    super.key,

    required this.postId,

    this.openComments = false,
  });

  @override
  State<PostDetailScreen> createState() =>
      _PostDetailScreenState();
}

class _PostDetailScreenState
    extends State<PostDetailScreen> {

  final FeedController _feedController =
      FeedController();

  PostModel? post;

  bool isLoading = true;

  String currentUserPhoto = "";

  String currentUserUsername = "";

@override
  void initState() {
    super.initState();
    _loadPost();
  }

  // ADD THIS BLOCK right after initState:
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _refreshCurrentUserPhoto();
  }

  Future<void> _refreshCurrentUserPhoto() async {
    final profileResponse = await ProfileController().getProfile();
    if (mounted) {
      setState(() {
        currentUserPhoto = profileResponse["user"]["photo"] ?? "";
        currentUserUsername = profileResponse["user"]["username"] ?? "";
      });
    }
  }

  Future<void> _loadPost() async {

    setState(() {
      isLoading = true;
    });

    try {

      final user =
          FirebaseAuth.instance.currentUser;

      if (user == null) return;

      final token =
          await user.getIdToken();

      // FETCH POST
      final fetchedPost =
          await _feedController.getPostById(
        token: token!,
        postId: widget.postId,
      );

      // FETCH CURRENT USER PROFILE
      final profileResponse =
          await ProfileController().getProfile();

      if (mounted) {

        setState(() {
          post = fetchedPost;
          isLoading = false;
        });

        // AUTO-OPEN COMMENTS SHEET IF REQUESTED
        if (widget.openComments &&
            fetchedPost != null) {

          WidgetsBinding.instance
              .addPostFrameCallback((_) {
            _openCommentsSheet(fetchedPost);
          });
        }
      }

    } catch (e) {

      print("PostDetail load error: $e");

      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  void _openCommentsSheet(PostModel p) {

    final TextEditingController commentCtrl =
        TextEditingController();

    showModalBottomSheet(

      context: context,

      isScrollControlled: true,

      backgroundColor: Colors.transparent,

      builder: (_) {

        return StatefulBuilder(

          builder: (context, setSheetState) {

            return Container(

              height:
                  MediaQuery.of(context).size.height *
                  0.75,

              padding: const EdgeInsets.only(
                top: 18,
                left: 18,
                right: 18,
                bottom: 24,
              ),

              decoration: const BoxDecoration(

                color: Colors.white,

                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(30),
                ),
              ),

              child: Column(

                children: [

                  // DRAG HANDLE
                  Container(

                    width: 50,

                    height: 5,

                    decoration: BoxDecoration(

                      color: Colors.grey.shade300,

                      borderRadius:
                          BorderRadius.circular(10),
                    ),
                  ),

                  const SizedBox(height: 18),

                  // HEADER
                  Row(

                    children: [

                      const Text(

                        "Comments",

                        style: TextStyle(

                          fontSize: 20,

                          fontWeight: FontWeight.w700,

                          color: _dark,
                        ),
                      ),

                      const Spacer(),

                      Text(

                        "${p.commentsCount}",

                        style: const TextStyle(

                          color: _light,

                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // COMMENTS LIST
                  Expanded(

                    child: p.commentsCount == 0

                        ? const Center(

                            child: Text(

                              "No comments yet",

                              style: TextStyle(
                                color: _light,
                                fontSize: 15,
                              ),
                            ),
                          )

                        : ListView.builder(

                            itemCount: p.comments.length,

                            itemBuilder: (context, index) {

                              final comment =
                                  p.comments[index];

                              return Container(

                                margin: const EdgeInsets.only(
                                  bottom: 16,
                                ),

                                child: Row(

                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,

                                  children: [

                                    CircleAvatar(

                                      radius: 22,

                                      backgroundColor: _primary,

                                      backgroundImage: comment
                                              .userProfileImage
                                              .isNotEmpty
                                          ? NetworkImage(
                                              comment.userProfileImage,
                                            )
                                          : null,

                                      child: comment
                                              .userProfileImage.isEmpty
                                          ? const Icon(
                                              Icons.person,
                                              color: Colors.white,
                                            )
                                          : null,
                                    ),

                                    const SizedBox(width: 12),

                                    Expanded(

                                      child: Container(

                                        padding:
                                            const EdgeInsets.all(14),

                                        decoration: BoxDecoration(

                                          color:
                                              const Color(0xFFF4F5FA),

                                          borderRadius:
                                              BorderRadius.circular(18),
                                        ),

                                        child: Column(

                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,

                                          children: [

                                            Text(

                                              comment.username,

                                              style: const TextStyle(

                                                fontWeight:
                                                    FontWeight.w700,

                                                color: _dark,
                                              ),
                                            ),

                                            const SizedBox(height: 6),

                                            Text(

                                              comment.text,

                                              style: const TextStyle(

                                                color: _dark,

                                                height: 1.5,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                  ),

                  // COMMENT INPUT
                  Row(

                    children: [

                      Expanded(

                        child: Container(

                          padding:
                              const EdgeInsets.symmetric(
                            horizontal: 16,
                          ),

                          decoration: BoxDecoration(

                            color: const Color(0xFFF4F5FA),

                            borderRadius:
                                BorderRadius.circular(18),
                          ),

                          child: TextField(

                            controller: commentCtrl,

                            decoration:
                                const InputDecoration(

                              hintText: "Write a comment...",

                              border: InputBorder.none,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(width: 12),

                      GestureDetector(

                        onTap: () async {

                          if (commentCtrl.text
                              .trim()
                              .isEmpty) {
                            return;
                          }

                          final user =
                              FirebaseAuth
                                  .instance
                                  .currentUser;

                          if (user == null) return;

                          final token =
                              await user.getIdToken();

                          await _feedController
                              .addComment(
                            token: token!,
                            postId: p.id,
                            text: commentCtrl.text.trim(),
                          );

                          final newComment = CommentModel(
                            username: currentUserUsername,
                            userProfileImage:
                                currentUserPhoto,
                            text: commentCtrl.text.trim(),
                            createdAt:
                                DateTime.now().toString(),
                          );

                          setSheetState(() {
                            p.comments.insert(0, newComment);
                            p.commentsCount++;
                          });

                          setState(() {});

                          commentCtrl.clear();
                        },

                        child: Container(

                          padding: const EdgeInsets.all(14),

                          decoration: const BoxDecoration(

                            gradient: LinearGradient(

                              colors: [
                                _primary,
                                _secondaryPurple,
                              ],
                            ),

                            shape: BoxShape.circle,
                          ),

                          child: const Icon(

                            Icons.send,

                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
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

        backgroundColor: _bg,

        appBar: AppBar(

          backgroundColor: _bg,

          elevation: 0,

          centerTitle: true,

          leading: IconButton(

            onPressed: () =>
                Navigator.pop(context),

            icon: const Icon(
              Icons.arrow_back_ios_new,
              color: _dark,
              size: 20,
            ),
          ),

          title: const Text(

            "Post",

            style: TextStyle(
              color: _dark,
              fontWeight: FontWeight.w700,
              fontSize: 17,
            ),
          ),
        ),

        body: isLoading

            ? const Center(
                child: CircularProgressIndicator(
                  color: _primary,
                ),
              )

            : post == null

                ? _buildNotFound()

                : RefreshIndicator(

                    color: _primary,

                    onRefresh: _loadPost,

                    child: SingleChildScrollView(

                      physics:
                          const AlwaysScrollableScrollPhysics(),

                      padding: const EdgeInsets.all(18),

                      child: _buildPostCard(post!),
                    ),
                  ),
      ),
    );
  }

  Widget _buildNotFound() {

    return const Center(

      child: Column(

        mainAxisAlignment: MainAxisAlignment.center,

        children: [

          Icon(
            Icons.broken_image_outlined,
            size: 52,
            color: _light,
          ),

          SizedBox(height: 16),

          Text(

            "Post not found",

            style: TextStyle(
              color: _dark,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),

          SizedBox(height: 8),

          Text(

            "This post may have been deleted.",

            style: TextStyle(
              color: _light,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPostCard(PostModel p) {

    return Container(

      padding: const EdgeInsets.all(16),

      decoration: BoxDecoration(

        color: _card,

        borderRadius: BorderRadius.circular(26),

        boxShadow: [

          BoxShadow(

            color: Colors.black.withOpacity(0.04),

            blurRadius: 14,

            offset: const Offset(0, 5),
          ),
        ],
      ),

      child: Column(

        crossAxisAlignment: CrossAxisAlignment.start,

        children: [

          // POST HEADER — avatar + username
          Row(

            children: [

              CircleAvatar(

                radius: 22,

                backgroundColor: _primary,

                backgroundImage:
                    p.userProfileImage.isNotEmpty
                        ? NetworkImage(p.userProfileImage)
                        : null,

                child: p.userProfileImage.isEmpty
                    ? const Icon(
                        Icons.person,
                        color: Colors.white,
                      )
                    : null,
              ),

              const SizedBox(width: 12),

              Expanded(

                child: Column(

                  crossAxisAlignment:
                      CrossAxisAlignment.start,

                  children: [

                    Text(

                      p.username,

                      style: const TextStyle(

                        color: _dark,

                        fontSize: 15,

                        fontWeight: FontWeight.w700,
                      ),
                    ),

                    const SizedBox(height: 3),

                    const Text(

                      "Salt Lake",

                      style: TextStyle(
                        color: _light,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // CONTENT
          if (p.content.isNotEmpty)

            Text(

              p.content,

              style: const TextStyle(

                color: _dark,

                fontSize: 14.5,

                height: 1.6,
              ),
            ),

          // IMAGES
          if (p.images.isNotEmpty)

            Padding(

              padding: const EdgeInsets.only(top: 16),

              child: SizedBox(

                height: 260,

                child: Stack(

                  children: [

                    ClipRRect(

                      borderRadius:
                          BorderRadius.circular(22),

                      child: PageView.builder(

                        itemCount: p.images.length,

                        onPageChanged: (value) {
                          setState(() {
                            p.currentImageIndex = value;
                          });
                        },

                        itemBuilder: (context, i) {

                          return Image.network(

                            List<String>.from(
                              p.images,
                            )[i],

                            fit: BoxFit.cover,

                            width: double.infinity,
                          );
                        },
                      ),
                    ),

                    // IMAGE COUNTER
                    if (p.images.length > 1)

                      Positioned(

                        top: 12,

                        right: 12,

                        child: Container(

                          padding:
                              const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),

                          decoration: BoxDecoration(

                            color: Colors.black
                                .withOpacity(0.55),

                            borderRadius:
                                BorderRadius.circular(18),
                          ),

                          child: Text(

                            "${p.currentImageIndex + 1}/${p.images.length}",

                            style: const TextStyle(

                              color: Colors.white,

                              fontSize: 11,

                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),

          // VIDEO
          if (p.video.isNotEmpty)

            Padding(

              padding: const EdgeInsets.only(top: 16),

              child: ClipRRect(

                borderRadius: BorderRadius.circular(22),

                child: _DetailVideoPlayer(
                  videoUrl: p.video,
                ),
              ),
            ),

          const SizedBox(height: 18),

          // ACTIONS ROW
          Row(

            children: [

              // LIKE
              GestureDetector(

                onTap: () async {

                  final user =
                      FirebaseAuth.instance.currentUser;

                  if (user == null) return;

                  final token =
                      await user.getIdToken();

                  setState(() {
                    p.isLiked = !p.isLiked;
                    p.isLiked
                        ? p.likesCount++
                        : p.likesCount--;
                  });

                  await _feedController.toggleLike(
                    token: token!,
                    postId: p.id,
                  );
                },

                child: Row(

                  children: [

                    Icon(

                      p.isLiked
                          ? Icons.favorite
                          : Icons.favorite_border,

                      color: p.isLiked
                          ? Colors.red
                          : _light,

                      size: 20,
                    ),

                    const SizedBox(width: 6),

                    Text(

                      "${p.likesCount}",

                      style: const TextStyle(

                        color: _light,

                        fontSize: 13,

                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 22),

              // COMMENT
              GestureDetector(

                onTap: () =>
                    _openCommentsSheet(p),

                child: Row(

                  children: [

                    const Icon(

                      Icons.mode_comment_outlined,

                      color: _light,

                      size: 20,
                    ),

                    const SizedBox(width: 6),

                    Text(

                      "${p.commentsCount}",

                      style: const TextStyle(

                        color: _light,

                        fontSize: 13,

                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// INLINE VIDEO PLAYER FOR POST DETAIL
class _DetailVideoPlayer extends StatefulWidget {

  final String videoUrl;

  const _DetailVideoPlayer({
    required this.videoUrl,
  });

  @override
  State<_DetailVideoPlayer> createState() =>
      _DetailVideoPlayerState();
}

class _DetailVideoPlayerState
    extends State<_DetailVideoPlayer> {

  late VideoPlayerController controller;

  bool isInitialized = false;

  @override
  void initState() {

    super.initState();

    controller = VideoPlayerController.networkUrl(
      Uri.parse(widget.videoUrl),
    );

    controller.initialize().then((_) {
      if (mounted) {
        setState(() {
          isInitialized = true;
        });
      }
    });
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    if (!isInitialized) {

      return Container(

        height: 240,

        color: Colors.black12,

        child: const Center(
          child: CircularProgressIndicator(
            color: _primary,
          ),
        ),
      );
    }

    return Stack(

      alignment: Alignment.center,

      children: [

        AspectRatio(

          aspectRatio: controller.value.aspectRatio,

          child: VideoPlayer(controller),
        ),

        GestureDetector(

          onTap: () {
            setState(() {
              controller.value.isPlaying
                  ? controller.pause()
                  : controller.play();
            });
          },

          child: CircleAvatar(

            radius: 30,

            backgroundColor: Colors.black45,

            child: Icon(

              controller.value.isPlaying
                  ? Icons.pause
                  : Icons.play_arrow,

              color: Colors.white,

              size: 34,
            ),
          ),
        ),
      ],
    );
  }
}