import 'package:addalink/core/services/video_manager_service.dart';
import 'package:addalink/core/widgets/feed_video_player.dart';
import 'package:addalink/core/widgets/skeleton_widgets.dart';
import 'package:addalink/features/profile/profile_controller.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'create_post_screen.dart';
import 'feed_controller.dart';

import 'post_model.dart';
import '../profile/profile_screen.dart';
import '../notifications/notification_controller.dart';
import '../notifications/notification_screen.dart';



const Color backgroundColor =
    Color(0xFFF7F8FC);

const Color primaryColor =
    Color(0xFF6C4DFF);

const Color secondaryPurple =
    Color(0xFF8D7BFF);

const Color textDark =
    Color(0xFF1B1D28);

const Color textLight =
    Color(0xFF70758A);

const Color cardColor =
    Colors.white;

class HomeFeedScreen
    extends StatefulWidget {

  const HomeFeedScreen({
    super.key,
  });

  @override
  State<HomeFeedScreen>
      createState() =>
          _HomeFeedScreenState();
}

class _HomeFeedScreenState
         extends State<HomeFeedScreen>
         with WidgetsBindingObserver {

  final FeedController
      controller =
          FeedController();

  final ScrollController
      _scrollController =
          ScrollController();

  List<PostModel> posts = [];

  String currentUserPhoto = "";

  String currentUserUsername = "";

  bool isLoading = true;

  int currentBottomIndex = 0;

  int unreadCount = 0;

@override
     void didChangeAppLifecycleState(AppLifecycleState state) {
       if (state == AppLifecycleState.resumed) {
         _loadUnreadCount();
       }
     }

@override
  void initState() {

    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _scrollController.addListener(
      _onScroll,
    );

    loadFeed();
    _loadUnreadCount();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    WidgetsBinding.instance.removeObserver(this);
    VideoManagerService().disposeAll();
    super.dispose();
  }

  void _onScroll() {
    if (!mounted) return;
    if (isLoading) return;
    if (posts.isEmpty) return;
    if (!controller.hasMore) return;
    if (controller.isLoadingMore) return;

    final position =
        _scrollController.position;

    if (position.pixels >=
        position.maxScrollExtent - 300) {
      _loadMorePosts();
    }
  }

  Future<void> _loadMorePosts() async {
    if (!mounted) return;

    if (!controller.hasMore ||
        controller.isLoadingMore) return;

    try {

      final user =
          FirebaseAuth.instance.currentUser;

      if (user == null) return;

      final token =
          await user.getIdToken();

      final updatedPosts =
          await controller.getFeedPosts(
        token: token!,
      );

      if (mounted) {
        setState(() {
          posts = updatedPosts;
        });
      }

    } catch (e) {

      print("Load more failed: $e");
    }
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

    Future<void> _loadUnreadCount() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final token = await user.getIdToken();
      if (token == null) return;

      // Calls GET /api/notifications/unread-count — a single countDocuments
      // query on the backend. Does NOT fetch or parse the full notification list.
      final count = await NotificationController().getUnreadCount(token: token);

      if (mounted) {
        setState(() {
          unreadCount = count;
        });
      }
    } catch (_) {}
  }


  Future<void> loadFeed() async {

    try {

      final user =
          FirebaseAuth
              .instance
              .currentUser;

      if (user == null) {
        return;
      }

      final token =
          await user.getIdToken();

final fetchedPosts =
          await controller
              .getFeedPosts(
        token: token!,
        refresh: true,
      );

      final profileResponse =
          await ProfileController()
              .getProfile();

      if (mounted) {
        setState(() {
          posts = fetchedPosts;
          currentUserPhoto =
              profileResponse["user"]["photo"] ?? "";
          currentUserUsername =
              profileResponse["user"]["username"] ?? "";
          isLoading = false;
        });
      }

    } catch (e) {

      print(e);

      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<void>
      openCreatePost() async {

    final result =
        await Navigator.push(

      context,

      MaterialPageRoute(

        builder: (_) =>
            const CreatePostScreen(),
      ),
    );

    if (result == true) {

      setState(() {
        isLoading = true;
      });

      await loadFeed();
    }
  }

  @override
  Widget build(BuildContext context) {

    final currentUser =
        FirebaseAuth
            .instance
            .currentUser;

    return AnnotatedRegion<
        SystemUiOverlayStyle>(

      value:
          const SystemUiOverlayStyle(

        statusBarColor:
            Colors.transparent,

        statusBarIconBrightness:
            Brightness.dark,
      ),

      child: Scaffold(

        backgroundColor:
            backgroundColor,

        body: RefreshIndicator(

          color: primaryColor,

          onRefresh: loadFeed,

          child: SafeArea(

            child: isLoading

                ? const FeedSkeletonList()

                : CustomScrollView(

                    controller:
                        _scrollController,

                    physics:
                        const BouncingScrollPhysics(),

                    slivers: [

                      SliverToBoxAdapter(

                        child: Padding(

                          padding:
                              const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 16,
                          ),

                          child: Column(

                            crossAxisAlignment:
                                CrossAxisAlignment
                                    .start,

                            children: [

                              // HEADER
                              Row(

                                children: [

                                  Expanded(

                                    child: Column(

                                      crossAxisAlignment:
                                          CrossAxisAlignment
                                              .start,

                                      children: [

                                        Text(

                                          "Hello, ${currentUser?.displayName ?? 'User'} 👋",

                                          style:
                                              const TextStyle(

                                            color:
                                                textDark,

                                            fontSize:
                                                26,

                                            fontWeight:
                                                FontWeight.w700,
                                          ),
                                        ),

                                        const SizedBox(
                                          height: 6,
                                        ),

                                        const Row(

                                          children: [

                                            Icon(

                                              Icons.location_on,

                                              color:
                                                  textLight,

                                              size: 16,
                                            ),

                                            SizedBox(
                                              width: 4,
                                            ),

                                            Text(

                                              "Salt Lake, Kolkata",

                                              style:
                                                  TextStyle(

                                                color:
                                                    textLight,

                                                fontSize:
                                                    14,

                                                fontWeight:
                                                    FontWeight.w500,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),

                                

                                  const SizedBox(
                                    width: 12,
                                  ),

                                  GestureDetector(

                                    onTap: () async {
                                      await Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) =>
                                              const NotificationScreen(),
                                        ),
                                      );
                                      _loadUnreadCount();
                                    },

                                    child: Stack(

                                      clipBehavior: Clip.none,

                                      children: [

                                        Container(

                                          height: 46,

                                          width: 46,

                                          decoration:
                                              BoxDecoration(

                                            color:
                                                Colors.white,

                                            borderRadius:
                                                BorderRadius.circular(
                                              16,
                                            ),

                                            boxShadow: [

                                              BoxShadow(

                                                color: Colors.black
                                                    .withOpacity(
                                                  0.05,
                                                ),

                                                blurRadius: 12,

                                                offset:
                                                    const Offset(
                                                  0,
                                                  4,
                                                ),
                                              ),
                                            ],
                                          ),

                                          child: const Icon(

                                            Icons.notifications_none,

                                            color:
                                                textDark,
                                          ),
                                        ),

                                        if (unreadCount > 0)

                                          Positioned(

                                            top: -4,

                                            right: -4,

                                            child: Container(

                                              padding:
                                                  const EdgeInsets.all(
                                                4,
                                              ),

                                              decoration:
                                                  const BoxDecoration(

                                                color:
                                                    Color(0xFFFF3B30),

                                                shape:
                                                    BoxShape.circle,
                                              ),

                                              constraints:
                                                  const BoxConstraints(

                                                minWidth: 18,

                                                minHeight: 18,
                                              ),

                                              child: Text(

                                                unreadCount > 99
                                                    ? "99+"
                                                    : "$unreadCount",

                                                style:
                                                    const TextStyle(

                                                  color:
                                                      Colors.white,

                                                  fontSize: 10,

                                                  fontWeight:
                                                      FontWeight.w700,
                                                ),

                                                textAlign:
                                                    TextAlign.center,
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(
                                height: 28,
                              ),

                              // QUICK ACTIONS
                              SizedBox(

                                height: 92,

                                child: ListView(

                                  scrollDirection:
                                      Axis.horizontal,

                                  children: [

                                    quickAction(

                                      icon:
                                          Icons.location_searching,

                                      label:
                                          "Nearby",

                                      color:
                                          const Color(
                                        0xFFE9E4FF,
                                      ),
                                    ),

                                    quickAction(

                                      icon:
                                          Icons.storefront,

                                      label:
                                          "Marketplace",

                                      color:
                                          const Color(
                                        0xFFFFF0E2,
                                      ),
                                    ),

                                    quickAction(

                                      icon:
                                          Icons.groups,

                                      label:
                                          "Groups",

                                      color:
                                          const Color(
                                        0xFFE4F7EB,
                                      ),
                                    ),

                                    quickAction(

                                      icon:
                                          Icons.event,

                                      label:
                                          "Events",

                                      color:
                                          const Color(
                                        0xFFFFE8F0,
                                      ),
                                    ),

                                    quickAction(

                                      icon:
                                          Icons.warning_amber,

                                      label:
                                          "Alerts",

                                      color:
                                          const Color(
                                        0xFFFFEEE8,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(
                                height: 28,
                              ),

                              // CREATE POST
                              GestureDetector(

                                onTap:
                                    openCreatePost,

                                child: Container(

                                  padding:
                                      const EdgeInsets.all(
                                    16,
                                  ),

                                  decoration:
                                      BoxDecoration(

                                    color:
                                        cardColor,

                                    borderRadius:
                                        BorderRadius.circular(
                                      24,
                                    ),

                                    boxShadow: [

                                      BoxShadow(

                                        color: Colors.black
                                            .withOpacity(
                                          0.04,
                                        ),

                                        blurRadius: 14,

                                        offset:
                                            const Offset(
                                          0,
                                          5,
                                        ),
                                      ),
                                    ],
                                  ),

                                  child: Column(

                                    children: [

                                      Row(

                                        children: [

                                         CircleAvatar(

  radius: 24,

  backgroundColor:
      primaryColor,

  backgroundImage:

      currentUserPhoto
              .isNotEmpty

          ? NetworkImage(
              currentUserPhoto,
            )

          : null,

  child:
      currentUserPhoto
              .isEmpty

          ? const Icon(

              Icons.person,

              color:
                  Colors.white,
            )

          : null,
),

                                          const SizedBox(
                                            width: 12,
                                          ),

                                          Expanded(

                                            child: Container(

                                              padding:
                                                  const EdgeInsets.symmetric(

                                                horizontal:
                                                    16,

                                                vertical:
                                                    14,
                                              ),

                                              decoration:
                                                  BoxDecoration(

                                                color:
                                                    const Color(
                                                  0xFFF4F5FA,
                                                ),

                                                borderRadius:
                                                    BorderRadius.circular(
                                                  18,
                                                ),
                                              ),

                                              child: const Text(

                                                "What's happening in your locality?",

                                                style:
                                                    TextStyle(

                                                  color:
                                                      textLight,

                                                  fontSize:
                                                      14,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),

                                      const SizedBox(
                                        height: 18,
                                      ),

                                      Row(

                                        mainAxisAlignment:
                                            MainAxisAlignment
                                                .spaceAround,

                                        children: [

                                          composerButton(

                                            icon:
                                                Icons.image,

                                            label:
                                                "Photo",
                                          ),

                                          composerButton(

                                            icon:
                                                Icons.video_call,

                                            label:
                                                "Video",
                                          ),

                                          composerButton(

                                            icon:
                                                Icons.poll,

                                            label:
                                                "Poll",
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                              const SizedBox(
                                height: 24,
                              ),

                              // FILTERS
                              SizedBox(

                                height: 42,

                                child: ListView(

                                  scrollDirection:
                                      Axis.horizontal,

                                  children: [

                                    filterChip(
                                      title:
                                          "All",
                                      selected:
                                          true,
                                    ),

                                    filterChip(
                                      title:
                                          "For You",
                                    ),

                                    filterChip(
                                      title:
                                          "Nearby",
                                    ),

                                    filterChip(
                                      title:
                                          "Trending",
                                    ),

                                    filterChip(
                                      title:
                                          "Alerts",
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(
                                height: 22,
                              ),
                            ],
                          ),
                        ),
                      ),

                      // POSTS
                      SliverPadding(

                        padding:
                            const EdgeInsets.only(

                          left: 18,

                          right: 18,

                          bottom: 120,
                        ),

                        sliver: posts.isEmpty

                            ? SliverToBoxAdapter(

                                child: Container(

                                  margin:
                                      const EdgeInsets.only(
                                    top: 40,
                                  ),

                                  padding:
                                      const EdgeInsets.all(
                                    28,
                                  ),

                                  decoration:
                                      BoxDecoration(

                                    color:
                                        cardColor,

                                    borderRadius:
                                        BorderRadius.circular(
                                      26,
                                    ),
                                  ),

                                  child: const Column(

                                    children: [

                                      Icon(

                                        Icons.feed_outlined,

                                        size: 60,

                                        color:
                                            primaryColor,
                                      ),

                                      SizedBox(
                                        height: 16,
                                      ),

                                      Text(

                                        "No Posts Yet",

                                        style:
                                            TextStyle(

                                          color:
                                              textDark,

                                          fontSize:
                                              18,

                                          fontWeight:
                                              FontWeight.w700,
                                        ),
                                      ),

                                      SizedBox(
                                        height: 8,
                                      ),

                                      Text(

                                        "Create the first community update around you.",

                                        textAlign:
                                            TextAlign.center,

                                        style:
                                            TextStyle(

                                          color:
                                              textLight,

                                          fontSize:
                                              14,

                                          height:
                                              1.5,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              )

                            : SliverList(

                                delegate:
                                    SliverChildBuilderDelegate(

                                  (
                                    context,
                                    index,
                                  ) {

                                    final post =
                                        posts[index];

                                    return buildPostCard(
                                      post,
                                    );
                                  },

                                  childCount:
                                      posts.length,
                                ),
                              ),
                      ),

                      // BOTTOM LOADING INDICATOR
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: 16,
                          ),
                          child: controller.isLoadingMore
                              ? const Center(
                                  child: CircularProgressIndicator(
                                    color: primaryColor,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const SizedBox.shrink(),
                        ),
                      ),
                    ],
                  ),
          ),
        ),

        floatingActionButton:
            FloatingActionButton(

          backgroundColor:
              primaryColor,

          elevation: 4,

          onPressed:
              openCreatePost,

          child: const Icon(

            Icons.auto_awesome,

            color: Colors.white,
          ),
        ),

        bottomNavigationBar:
            buildBottomNavigation(),
      ),
    );
  }

  Widget quickAction({

    required IconData icon,

    required String label,

    required Color color,
  }) {

    return Padding(

      padding:
          const EdgeInsets.only(
        right: 16,
      ),

      child: Column(

        children: [

          Container(

            height: 62,

            width: 62,

            decoration:
                BoxDecoration(

              color: color,

              borderRadius:
                  BorderRadius.circular(
                22,
              ),
            ),

            child: Icon(

              icon,

              color:
                  textDark,
            ),
          ),

          const SizedBox(
            height: 8,
          ),

          Text(

            label,

            style:
                const TextStyle(

              color:
                  textDark,

              fontSize: 12,

              fontWeight:
                  FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget composerButton({

    required IconData icon,

    required String label,
  }) {

    return Row(

      children: [

        Icon(

          icon,

          color:
              textLight,

          size: 20,
        ),

        const SizedBox(
          width: 6,
        ),

        Text(

          label,

          style:
              const TextStyle(

            color:
                textLight,

            fontWeight:
                FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget filterChip({

    required String title,

    bool selected = false,
  }) {

    return Container(

      margin:
          const EdgeInsets.only(
        right: 10,
      ),

      padding:
          const EdgeInsets.symmetric(

        horizontal: 18,

        vertical: 10,
      ),

      decoration:
          BoxDecoration(

        color: selected
            ? primaryColor
            : Colors.white,

        borderRadius:
            BorderRadius.circular(
          16,
        ),
      ),

      child: Text(

        title,

        style: TextStyle(

          color: selected
              ? Colors.white
              : textLight,

          fontWeight:
              FontWeight.w600,

          fontSize: 13,
        ),
      ),
    );
  }

  Widget buildPostCard(
    PostModel post,
  ) {

    return Container(

      margin:
          const EdgeInsets.only(
        bottom: 20,
      ),

      padding:
          const EdgeInsets.all(16),

      decoration:
          BoxDecoration(

        color: cardColor,

        borderRadius:
            BorderRadius.circular(26),

        boxShadow: [

          BoxShadow(

            color: Colors.black
                .withOpacity(0.04),

            blurRadius: 14,

            offset:
                const Offset(0, 5),
          ),
        ],
      ),

      child: Column(

        crossAxisAlignment:
            CrossAxisAlignment.start,

        children: [

          // HEADER
          Row(

            children: [

             CircleAvatar(

  radius: 22,

  backgroundColor:
      primaryColor,

  backgroundImage:

      post.userProfileImage
              .isNotEmpty

          ? NetworkImage(

              post.userProfileImage,
            )

          : null,

  child:
      post.userProfileImage
                  .isEmpty

          ? const Icon(

              Icons.person,

              color:
                  Colors.white,
            )

          : null,
),

              const SizedBox(
                width: 12,
              ),

              Expanded(

                child: Column(

                  crossAxisAlignment:
                      CrossAxisAlignment
                          .start,

                  children: [

                    Text(

                      post.username,

                      style:
                          const TextStyle(

                        color:
                            textDark,

                        fontSize:
                            15,

                        fontWeight:
                            FontWeight.w700,
                      ),
                    ),

                    const SizedBox(
                      height: 3,
                    ),

                    const Text(

                      "Salt Lake",

                      style:
                          TextStyle(

                        color:
                            textLight,

                        fontSize:
                            12,
                      ),
                    ),
                  ],
                ),
              ),

              IconButton(

                onPressed: () {},

                icon: const Icon(

                  Icons.more_horiz,

                  color:
                      textLight,
                ),
              ),
            ],
          ),

          const SizedBox(
            height: 16,
          ),

          // CONTENT
          if (post.content
              .isNotEmpty)

            Text(

              post.content,

              style:
                  const TextStyle(

                color:
                    textDark,

                fontSize:
                    14.5,

                height:
                    1.6,
              ),
            ),

          // IMAGES
          if (post.images
              .isNotEmpty)

            Padding(

              padding:
                  const EdgeInsets.only(
                top: 16,
              ),

              child: SizedBox(

                height: 250,

                child: Stack(

                  children: [

                    ClipRRect(

                      borderRadius:
                          BorderRadius.circular(
                        22,
                      ),

                      child:
                          PageView.builder(

                        itemCount:
                            post.images.length,

                        onPageChanged:
                            (value) {

                          setState(() {

                            post.currentImageIndex =
                                value;
                          });
                        },

                        itemBuilder:
                            (
                              context,
                              imageIndex,
                            ) {

                          return Image.network(

                            List<String>.from(
                              post.images,
                            )[imageIndex],

                            fit:
                                BoxFit.cover,

                            width:
                                double.infinity,
                          );
                        },
                      ),
                    ),

                    // COUNT
                    Positioned(

                      top: 12,

                      right: 12,

                      child: Container(

                        padding:
                            const EdgeInsets.symmetric(

                          horizontal: 10,

                          vertical: 5,
                        ),

                        decoration:
                            BoxDecoration(

                          color: Colors.black
                              .withOpacity(0.55),

                          borderRadius:
                              BorderRadius.circular(
                            18,
                          ),
                        ),

                        child: Text(

                          "${post.currentImageIndex + 1}/${post.images.length}",

                          style:
                              const TextStyle(

                            color:
                                Colors.white,

                            fontSize: 11,

                            fontWeight:
                                FontWeight.w600,
                          ),
                        ),
                      ),
                    ),

                    // DOTS
                    if (post.images.length >
                        1)

                      Positioned(

                        bottom: 12,

                        left: 0,

                        right: 0,

                        child: Row(

                          mainAxisAlignment:
                              MainAxisAlignment
                                  .center,

                          children:
                              List.generate(

                            post.images.length,

                            (dotIndex) {

                              final isSelected =
                                  dotIndex ==
                                      post.currentImageIndex;

                              return AnimatedContainer(

                                duration:
                                    const Duration(
                                  milliseconds:
                                      250,
                                ),

                                margin:
                                    const EdgeInsets.symmetric(
                                  horizontal: 3,
                                ),

                                height: 7,

                                width:
                                    isSelected
                                        ? 20
                                        : 7,

                                decoration:
                                    BoxDecoration(

                                  color: isSelected
                                      ? Colors.white
                                      : Colors.white
                                          .withOpacity(
                                      0.5,
                                    ),

                                  borderRadius:
                                      BorderRadius.circular(
                                    10,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),

          const SizedBox(
            height: 18,
          ),
// VIDEO
if (post.video.isNotEmpty)

  Padding(

    padding:
        const EdgeInsets.only(
      top: 16,
    ),

    child: ClipRRect(

      borderRadius:
          BorderRadius.circular(
        22,
      ),

      child: FeedVideoPlayer(
        postId: post.id,
        videoUrl: post.video,
        thumbnailUrl: post.thumbnail.isNotEmpty ? post.thumbnail : null,
      ),
    ),
  ),
          // ACTIONS
          Row(

            mainAxisAlignment:
                MainAxisAlignment
                    .spaceBetween,

            children: [

              GestureDetector(

  onTap: () async {

    final user =
        FirebaseAuth
            .instance
            .currentUser;

    if (user == null) {
      return;
    }

    final token =
        await user.getIdToken();

    setState(() {

      post.isLiked =
          !post.isLiked;

      if (post.isLiked) {

        post.likesCount++;

      } else {

        post.likesCount--;
      }
    });

    await controller
        .toggleLike(

      token: token!,

      postId: post.id,
    );
  },

  child: Row(

    children: [

      Icon(

        post.isLiked

            ? Icons.favorite

            : Icons.favorite_border,

        color: post.isLiked

            ? Colors.red

            : textLight,

        size: 20,
      ),

      const SizedBox(
        width: 6,
      ),

      Text(

        "${post.likesCount}",

        style:
            const TextStyle(

          color:
              textLight,

          fontSize: 13,

          fontWeight:
              FontWeight.w500,
        ),
      ),
    ],
  ),
),

             GestureDetector(

  onTap: () {

    openCommentsSheet(
      post,
    );
  },

  child: Row(

    children: [

      const Icon(

        Icons.mode_comment_outlined,

        color:
            textLight,

        size: 20,
      ),

      const SizedBox(
        width: 6,
      ),

      Text(

        "${post.commentsCount}",

        style:
            const TextStyle(

          color:
              textLight,

          fontSize: 13,

          fontWeight:
              FontWeight.w500,
        ),
      ),
    ],
  ),
),

              actionButton(
                icon:
                    Icons.share_outlined,
                label:
                    "Share",
              ),
            ],
          ),
        ],
      ),
    );
  }

  void openCommentsSheet(
  PostModel post,
) {

  final TextEditingController
      commentController =
          TextEditingController();

  showModalBottomSheet(

    context: context,

    isScrollControlled: true,

    backgroundColor:
        Colors.transparent,

    builder: (_) {

      return Container(

        height:
            MediaQuery.of(context)
                    .size
                    .height *
                0.75,

        padding:
            const EdgeInsets.only(
          top: 18,
          left: 18,
          right: 18,
          bottom: 24,
        ),

        decoration:
            const BoxDecoration(

          color: Colors.white,

          borderRadius:
              BorderRadius.vertical(
            top: Radius.circular(
              30,
            ),
          ),
        ),

        child: Column(

          children: [

            Container(

              width: 50,

              height: 5,

              decoration:
                  BoxDecoration(

                color:
                    Colors.grey.shade300,

                borderRadius:
                    BorderRadius.circular(
                  10,
                ),
              ),
            ),

            const SizedBox(
              height: 18,
            ),

            Row(

              children: [

                const Text(

                  "Comments",

                  style: TextStyle(

                    fontSize: 20,

                    fontWeight:
                        FontWeight.w700,

                    color:
                        textDark,
                  ),
                ),

                const Spacer(),

                Text(

                  "${post.commentsCount}",

                  style:
                      const TextStyle(

                    color:
                        textLight,

                    fontWeight:
                        FontWeight.w600,
                  ),
                ),
              ],
            ),

            const SizedBox(
              height: 20,
            ),

            Expanded(

              child: post.commentsCount ==
                      0

                  ? const Center(

                      child: Text(

                        "No comments yet",

                        style: TextStyle(

                          color:
                              textLight,

                          fontSize:
                              15,
                        ),
                      ),
                    )

                  : ListView.builder(

                     itemCount:
    post.comments.length,

                      itemBuilder:
                          (
                            context,
                            index,
                          ) {

                        return Container(

                          margin:
                              const EdgeInsets.only(
                            bottom: 16,
                          ),

                          child: Row(

                            crossAxisAlignment:
                                CrossAxisAlignment
                                    .start,

                            children: [

                             CircleAvatar(

  radius: 22,

  backgroundColor:
      primaryColor,

  backgroundImage:

      post.comments[index]
                  .userProfileImage
                  .isNotEmpty

          ? NetworkImage(

              post.comments[index]
                  .userProfileImage,
            )

          : null,

  child:
      post.comments[index]
                  .userProfileImage
                  .isEmpty

          ? const Icon(

              Icons.person,

              color:
                  Colors.white,
            )

          : null,
),

                              const SizedBox(
                                width: 12,
                              ),

                              Expanded(

                                child: Container(

                                  padding:
                                      const EdgeInsets.all(
                                    14,
                                  ),

                                  decoration:
                                      BoxDecoration(

                                    color:
                                        const Color(
                                      0xFFF4F5FA,
                                    ),

                                    borderRadius:
                                        BorderRadius.circular(
                                      18,
                                    ),
                                  ),

                                  child:
                                      Column(

  crossAxisAlignment:
      CrossAxisAlignment
          .start,

  children: [

    Text(

      post.comments[index]
          .username,

      style:
          const TextStyle(

        fontWeight:
            FontWeight.w700,

        color:
            textDark,
      ),
    ),

    const SizedBox(
      height: 6,
    ),

    Text(

      post.comments[index]
          .text,

      style:
          const TextStyle(

        color:
            textDark,

        height:
            1.5,
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

            Row(

              children: [

                Expanded(

                  child: Container(

                    padding:
                        const EdgeInsets.symmetric(
                      horizontal: 16,
                    ),

                    decoration:
                        BoxDecoration(

                      color:
                          const Color(
                        0xFFF4F5FA,
                      ),

                      borderRadius:
                          BorderRadius.circular(
                        18,
                      ),
                    ),

                    child: TextField(

                      controller:
                          commentController,

                      decoration:
                          const InputDecoration(

                        hintText:
                            "Write a comment...",

                        border:
                            InputBorder.none,
                      ),
                    ),
                  ),
                ),

                const SizedBox(
                  width: 12,
                ),

                GestureDetector(

                  onTap: () async {

                    if (commentController
                        .text
                        .trim()
                        .isEmpty) {

                      return;
                    }

                    final user =
                        FirebaseAuth
                            .instance
                            .currentUser;

                    if (user == null) {
                      return;
                    }

                    final token =
                        await user
                            .getIdToken();

                    await controller
                        .addComment(

                      token: token!,

                      postId: post.id,

                      text:
                          commentController
                              .text
                              .trim(),
                    );

                    setState(() {

                      post.comments.insert(

  0,

  CommentModel(

    username:
        currentUserUsername,

    userProfileImage:
        currentUserPhoto,

    text:
        commentController.text
            .trim(),

    createdAt:
        DateTime.now()
            .toString(),
  ),
);
                    });

                    Navigator.pop(
                      context,
                    );
                  },

                  child: Container(

                    padding:
                        const EdgeInsets.all(
                      14,
                    ),

                    decoration:
                        const BoxDecoration(

                      gradient:
                          LinearGradient(

                        colors: [

                          primaryColor,

                          secondaryPurple,
                        ],
                      ),

                      shape:
                          BoxShape.circle,
                    ),

                    child: const Icon(

                      Icons.send,

                      color:
                          Colors.white,
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
}

  Widget actionButton({

    required IconData icon,

    required String label,
  }) {

    return Row(

      children: [

        Icon(

          icon,

          color:
              textLight,

          size: 20,
        ),

        const SizedBox(
          width: 6,
        ),

        Text(

          label,

          style:
              const TextStyle(

            color:
                textLight,

            fontSize: 13,

            fontWeight:
                FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget buildBottomNavigation() {

    return SafeArea(

      child: Container(

        margin:
            const EdgeInsets.only(

          left: 18,

          right: 18,

          bottom: 16,
        ),

        padding:
            const EdgeInsets.symmetric(

          horizontal: 12,

          vertical: 12,
        ),

        decoration:
            BoxDecoration(

          color: Colors.white,

          borderRadius:
              BorderRadius.circular(30),

          boxShadow: [

            BoxShadow(

              color: Colors.black
                  .withOpacity(0.06),

              blurRadius: 18,

              offset:
                  const Offset(0, 6),
            ),
          ],
        ),

        child: Row(

          mainAxisAlignment:
              MainAxisAlignment
                  .spaceAround,

          children: [

            navItem(
              index: 0,
              icon:
                  Icons.home_filled,
              label:
                  "Home",
            ),

            navItem(
              index: 1,
              icon:
                  Icons.explore,
              label:
                  "Explore",
            ),

            GestureDetector(

              onTap:
                  openCreatePost,

              child: Container(

                height: 54,

                width: 54,

                decoration:
                    const BoxDecoration(

                  gradient:
                      LinearGradient(

                    colors: [

                      primaryColor,

                      secondaryPurple,
                    ],
                  ),

                  shape:
                      BoxShape.circle,
                ),

                child: const Icon(

                  Icons.add,

                  color:
                      Colors.white,

                  size: 28,
                ),
              ),
            ),

            navItem(
              index: 3,
              icon:
                  Icons.chat_bubble_outline,
              label:
                  "Chat",
            ),

            navItem(
              index: 4,
              icon:
                  Icons.person_outline,
              label:
                  "Profile",
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        const ProfileScreen(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget navItem({

    required int index,

    required IconData icon,

    required String label,

    VoidCallback? onTap,
  }) {

    final bool selected =
        currentBottomIndex ==
            index;

    return GestureDetector(

      onTap: onTap ??
          () {
            setState(() {
              currentBottomIndex =
                  index;
            });
          },

      child: Column(

        mainAxisSize:
            MainAxisSize.min,

        children: [

          Icon(

            icon,

            color: selected
                ? primaryColor
                : textLight,

            size: 24,
          ),

          const SizedBox(
            height: 4,
          ),

          Text(

            label,

            style: TextStyle(

              color: selected
                  ? primaryColor
                  : textLight,

              fontSize: 11,

              fontWeight:
                  FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}