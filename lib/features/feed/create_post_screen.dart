import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';

import 'feed_controller.dart';
import 'package:addalink/features/profile/profile_controller.dart';

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

const Color borderColor =
    Color(0xFFE8EAF2);

class CreatePostScreen
    extends StatefulWidget {

  const CreatePostScreen({
    super.key,
  });

  @override
  State<CreatePostScreen>
      createState() =>
          _CreatePostScreenState();
}

class _CreatePostScreenState
    extends State<CreatePostScreen> {

  final TextEditingController
      contentController =
          TextEditingController();

  final ImagePicker picker =
      ImagePicker();

  final FeedController
      controller =
          FeedController();

  List<File> selectedImages =
      [];

  File? selectedVideo;

  VideoPlayerController?
      videoController;

  bool isPosting = false;

  String selectedType =
      "Update";

  String currentUserPhoto = "";

  String currentUserUsername = "";

  @override
  void initState() {
    super.initState();
    _loadCurrentUserProfile();
  }

  Future<void> _loadCurrentUserProfile() async {
    try {
      final profileResponse =
          await ProfileController().getProfile();
      if (mounted) {
        setState(() {
          currentUserPhoto =
              profileResponse["user"]["photo"] ?? "";
          currentUserUsername =
              profileResponse["user"]["username"] ?? "";
        });
      }
    } catch (_) {}
  }

  Future<void> pickImages() async {

    if (selectedVideo != null) {

      showMessage(
        "Remove video first",
      );

      return;
    }

    final List<XFile> images =
        await picker.pickMultiImage();

    if (images.isEmpty) {
      return;
    }

    if (images.length > 4) {

      showMessage(
        "Maximum 4 images allowed",
      );

      return;
    }

    setState(() {

      selectedImages =
          images
              .map(
                (e) =>
                    File(e.path),
              )
              .toList();
    });
  }

  Future<void> pickVideo() async {

    if (selectedImages
        .isNotEmpty) {

      showMessage(
        "Remove images first",
      );

      return;
    }

    final XFile? video =
        await picker.pickVideo(
      source:
          ImageSource.gallery,
    );

    if (video == null) {
      return;
    }

    selectedVideo =
        File(video.path);

    videoController =
        VideoPlayerController.file(
      selectedVideo!,
    );

    await videoController!
        .initialize();

    setState(() {});
  }

  Future<void> createPost() async {

    if (contentController.text
            .trim()
            .isEmpty &&
        selectedImages
            .isEmpty &&
        selectedVideo ==
            null) {

      showMessage(
        "Post cannot be empty",
      );

      return;
    }

    setState(() {
      isPosting = true;
    });

    try {

      final user =
          FirebaseAuth
              .instance
              .currentUser;

      if (user == null) {

        showMessage(
          "User not logged in",
        );

        return;
      }

      final token =
          await user.getIdToken();

      final response =
          await controller
              .createPost(

        token: token!,

        content:
            contentController
                .text
                .trim(),

        images:
            selectedImages,

        video:
            selectedVideo,

        location: {
          "address":
              "Kolkata",
        },
      );

      if (response[
              "success"] ==
          true) {

        showMessage(
          "Community update shared 🚀",
        );

        if (mounted) {

          Navigator.pop(
            context,
            true,
          );
        }

      } else {

        showMessage(
          response["message"],
        );
      }

    } catch (e) {

      showMessage(
        e.toString(),
      );
    }

    if (mounted) {

      setState(() {
        isPosting = false;
      });
    }
  }

  void showMessage(
    String message,
  ) {

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(

      SnackBar(

        content: Text(
          message,
        ),

        backgroundColor:
            textDark,

        behavior:
            SnackBarBehavior
                .floating,
      ),
    );
  }

  @override
  void dispose() {

    videoController
        ?.dispose();

    contentController
        .dispose();

    super.dispose();
  }

  @override
  Widget build(
    BuildContext context,
  ) {

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

        appBar: AppBar(

          backgroundColor:
              backgroundColor,

          elevation: 0,

          centerTitle: true,

          leading: IconButton(

            onPressed: () {

              Navigator.pop(
                context,
              );
            },

            icon: const Icon(

              Icons.close,

              color:
                  textDark,
            ),
          ),

          title: const Text(

            "Community Update",

            style: TextStyle(

              color:
                  textDark,

              fontWeight:
                  FontWeight.w700,

              fontSize: 17,
            ),
          ),

          actions: [

            Padding(

              padding:
                  const EdgeInsets.only(
                right: 14,
              ),

              child:
                  GestureDetector(

                onTap:
                    isPosting
                        ? null
                        : createPost,

                child:
                    AnimatedContainer(

                  duration:
                      const Duration(
                    milliseconds:
                        250,
                  ),

                  padding:
                      const EdgeInsets.symmetric(

                    horizontal: 18,

                    vertical: 10,
                  ),

                  decoration:
                      BoxDecoration(

                    gradient:
                        isPosting
                            ? null
                            : const LinearGradient(

                                colors: [

                                  primaryColor,

                                  secondaryPurple,
                                ],
                              ),

                    color:
                        isPosting
                            ? Colors
                                .grey
                            : null,

                    borderRadius:
                        BorderRadius.circular(
                      18,
                    ),
                  ),

                  child:
                      isPosting

                          ? const SizedBox(

                              height: 16,

                              width: 16,

                              child:
                                  CircularProgressIndicator(

                                color:
                                    Colors.white,

                                strokeWidth:
                                    2,
                              ),
                            )

                          : const Text(

                              "Share",

                              style:
                                  TextStyle(

                                color:
                                    Colors.white,

                                fontWeight:
                                    FontWeight.w700,
                              ),
                            ),
                ),
              ),
            ),
          ],
        ),

        body:
            SingleChildScrollView(

          padding:
              const EdgeInsets.all(
            18,
          ),

          child: Column(

            crossAxisAlignment:
                CrossAxisAlignment
                    .start,

            children: [

              // PROFILE + FIELD
              Container(

                padding:
                    const EdgeInsets.all(
                  18,
                ),

                decoration:
                    BoxDecoration(

                  color:
                      cardColor,

                  borderRadius:
                      BorderRadius.circular(
                    28,
                  ),

                  boxShadow: [

                    BoxShadow(

                      color: Colors.black
                          .withOpacity(
                        0.04,
                      ),

                      blurRadius: 18,

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

                      crossAxisAlignment:
                          CrossAxisAlignment
                              .start,

                      children: [

                        CircleAvatar(

                          radius: 24,

                          backgroundImage:
                              currentUserPhoto
                                      .isNotEmpty
                                  ? NetworkImage(
                                      currentUserPhoto,
                                    )
                                  : null,

                          backgroundColor:
                              primaryColor,

                          child: currentUserPhoto
                                  .isEmpty
                              ? const Icon(
                                  Icons.person,
                                  color: Colors.white,
                                )
                              : null,
                        ),

                        const SizedBox(
                          width: 14,
                        ),

                        Expanded(

                          child: Column(

                            crossAxisAlignment:
                                CrossAxisAlignment
                                    .start,

                            children: [

                              Text(

                                currentUserUsername
                                        .isNotEmpty
                                    ? currentUserUsername
                                    : "AddaLink User",

                                style:
                                    const TextStyle(

                                  color:
                                      textDark,

                                  fontWeight:
                                      FontWeight
                                          .w700,

                                  fontSize:
                                      15,
                                ),
                              ),

                              const SizedBox(
                                height: 4,
                              ),

                              const Text(

                                "Salt Lake, Kolkata",

                                style:
                                    TextStyle(

                                  color:
                                      textLight,

                                  fontSize:
                                      13,
                                ),
                              ),

                              const SizedBox(
                                height: 18,
                              ),

                              TextField(

                                controller:
                                    contentController,

                                minLines: 5,

                                maxLines:
                                    null,

                                style:
                                    const TextStyle(

                                  color:
                                      textDark,

                                  fontSize:
                                      15,

                                  height:
                                      1.6,
                                ),

                                decoration:
                                    const InputDecoration(

                                  hintText:
                                      "Share something useful with your locality...",

                                  hintStyle:
                                      TextStyle(

                                    color:
                                        textLight,

                                    fontSize:
                                        15,
                                  ),

                                  border:
                                      InputBorder.none,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(
                      height: 20,
                    ),

                    // POST TYPES
                    SizedBox(

                      height: 42,

                      child: ListView(

                        scrollDirection:
                            Axis.horizontal,

                        children: [

                          postTypeChip(
                            "Update",
                          ),

                          postTypeChip(
                            "Alert",
                          ),

                          postTypeChip(
                            "Event",
                          ),

                          postTypeChip(
                            "Poll",
                          ),

                          postTypeChip(
                            "Marketplace",
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(
                height: 20,
              ),

              // IMAGE PREVIEW
              if (selectedImages
                  .isNotEmpty)

                Container(

                  padding:
                      const EdgeInsets.all(
                    14,
                  ),

                  decoration:
                      BoxDecoration(

                    color:
                        cardColor,

                    borderRadius:
                        BorderRadius.circular(
                      24,
                    ),
                  ),

                  child: SizedBox(

                    height: 110,

                    child:
                        ListView.separated(

                      scrollDirection:
                          Axis.horizontal,

                      itemCount:
                          selectedImages
                              .length,

                      separatorBuilder:
                          (
                            _,
                            __,
                          ) =>
                              const SizedBox(
                        width: 10,
                      ),

                      itemBuilder:
                          (
                            _,
                            index,
                          ) {

                        return Stack(

                          children: [

                            ClipRRect(

                              borderRadius:
                                  BorderRadius.circular(
                                16,
                              ),

                              child:
                                  Image.file(

                                selectedImages[
                                    index],

                                width:
                                    110,

                                height:
                                    110,

                                fit:
                                    BoxFit.cover,
                              ),
                            ),

                            Positioned(

                              top: 6,

                              right: 6,

                              child:
                                  GestureDetector(

                                onTap: () {

                                  setState(() {

                                    selectedImages
                                        .removeAt(
                                      index,
                                    );
                                  });
                                },

                                child:
                                    Container(

                                  padding:
                                      const EdgeInsets.all(
                                    5,
                                  ),

                                  decoration:
                                      BoxDecoration(

                                    color: Colors
                                        .black
                                        .withOpacity(
                                      0.5,
                                    ),

                                    shape:
                                        BoxShape.circle,
                                  ),

                                  child:
                                      const Icon(

                                    Icons.close,

                                    color:
                                        Colors.white,

                                    size:
                                        14,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ),

              // VIDEO PREVIEW
              if (selectedVideo !=
                      null &&
                  videoController !=
                      null)

                Container(

                  padding:
                      const EdgeInsets.all(
                    14,
                  ),

                  decoration:
                      BoxDecoration(

                    color:
                        cardColor,

                    borderRadius:
                        BorderRadius.circular(
                      24,
                    ),
                  ),

                  child: Stack(

                    children: [

                      ClipRRect(

                        borderRadius:
                            BorderRadius.circular(
                          18,
                        ),

                        child:
                            AspectRatio(

                          aspectRatio:
                              videoController!
                                  .value
                                  .aspectRatio,

                          child:
                              VideoPlayer(
                            videoController!,
                          ),
                        ),
                      ),

                      Positioned(

                        top: 10,

                        right: 10,

                        child:
                            GestureDetector(

                          onTap: () {

                            videoController
                                ?.dispose();

                            setState(() {

                              selectedVideo =
                                  null;

                              videoController =
                                  null;
                            });
                          },

                          child:
                              Container(

                            padding:
                                const EdgeInsets.all(
                              6,
                            ),

                            decoration:
                                BoxDecoration(

                              color: Colors
                                  .black
                                  .withOpacity(
                                0.6,
                              ),

                              shape:
                                  BoxShape.circle,
                            ),

                            child:
                                const Icon(

                              Icons.close,

                              color:
                                  Colors.white,

                              size:
                                  16,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              const SizedBox(
                height: 22,
              ),

              // ACTIONS
              Container(

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
                ),

                child: Row(

                  mainAxisAlignment:
                      MainAxisAlignment
                          .spaceAround,

                  children: [

                    mediaButton(

                      icon:
                          Icons.image_outlined,

                      label:
                          "Photos",

                      onTap:
                          pickImages,

                      active:
                          selectedImages
                              .isNotEmpty,
                    ),

                    mediaButton(

                      icon:
                          Icons.videocam_outlined,

                      label:
                          "Video",

                      onTap:
                          pickVideo,

                      active:
                          selectedVideo !=
                              null,
                    ),

                    mediaButton(

                      icon:
                          Icons.location_on_outlined,

                      label:
                          "Location",

                      onTap: () {},

                      active:
                          false,
                    ),
                  ],
                ),
              ),

              const SizedBox(
                height: 40,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget postTypeChip(
    String title,
  ) {

    final bool selected =
        selectedType ==
            title;

    return GestureDetector(

      onTap: () {

        setState(() {

          selectedType =
              title;
        });
      },

      child: Container(

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

          border: Border.all(
            color: selected
                ? primaryColor
                : borderColor,
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
      ),
    );
  }

  Widget mediaButton({

    required IconData icon,

    required String label,

    required VoidCallback onTap,

    required bool active,
  }) {

    return GestureDetector(

      onTap: () {

        HapticFeedback
            .selectionClick();

        onTap();
      },

      child: AnimatedContainer(

        duration:
            const Duration(
          milliseconds: 250,
        ),

        padding:
            const EdgeInsets.symmetric(

          horizontal: 16,

          vertical: 12,
        ),

        decoration:
            BoxDecoration(

          color: active
              ? primaryColor
                  .withOpacity(
                0.12,
              )
              : const Color(
                  0xFFF4F5FA,
                ),

          borderRadius:
              BorderRadius.circular(
            18,
          ),

          border: Border.all(

            color: active
                ? primaryColor
                    .withOpacity(
                  0.3,
                )
                : borderColor,
          ),
        ),

        child: Row(

          children: [

            Icon(

              icon,

              color: active
                  ? primaryColor
                  : textLight,

              size: 20,
            ),

            const SizedBox(
              width: 7,
            ),

            Text(

              label,

              style: TextStyle(

                color: active
                    ? primaryColor
                    : textLight,

                fontWeight:
                    FontWeight.w600,

                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}