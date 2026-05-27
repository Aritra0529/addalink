class CommentModel {

  final String username;

  final String userProfileImage;

  final String text;

  final String createdAt;

  CommentModel({

    required this.username,

    required this.userProfileImage,

    required this.text,

    required this.createdAt,
  });

  factory CommentModel.fromJson(
    Map<String, dynamic> json,
  ) {

    return CommentModel(

      username:
          json["username"] ?? "",

      userProfileImage:
          json["userProfileImage"] ?? "",

      text:
          json["text"] ?? "",

      createdAt:
          json["createdAt"] ?? "",
    );
  }
}

class PostModel {

  final String id;

  final String username;

  final String userProfileImage;

  final String content;

  final List<dynamic> images;

  final String video;

  final String postType;

  final String createdAt;

  final List<CommentModel> comments;

  int likesCount;

  int commentsCount;

  bool isLiked;

  bool isEdited;

  int currentImageIndex = 0;

  PostModel({

    required this.id,

    required this.username,

    required this.userProfileImage,

    required this.content,

    required this.images,

    required this.video,

    required this.postType,

    required this.createdAt,

    required this.likesCount,

    required this.isLiked,

    required this.isEdited,

    required this.commentsCount,

    required this.comments,
  });

  factory PostModel.fromJson(
    Map<String, dynamic> json,
  ) {

    return PostModel(

      id: json["_id"] ?? "",

      username:
          json["username"] ?? "",

      userProfileImage:
          json["userProfileImage"] ??
              "",

      content:
          json["content"] ?? "",

      images:
          json["images"] ?? [],

      video:
          json["video"] ?? "",

      postType:
          json["postType"] ?? "",

      createdAt:
          json["createdAt"] ?? "",

      likesCount:
          json["likesCount"] ?? 0,

      isLiked:
          json["isLiked"] ?? false,

      isEdited:
          json["isEdited"] ?? false,

      comments:
    (json["comments"] as List?)

        ?.map(
          (e) =>
              CommentModel
                  .fromJson(e),
        )

        .toList()

        ?? [],

commentsCount:
    (json["comments"] ?? [])
        .length,
    );
  }
}