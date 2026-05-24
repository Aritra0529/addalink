class NotificationModel {

  final String id;

  final String senderName;

  final String senderPhoto;

  final String type;

  final String text;

  final bool isRead;

  final String createdAt;

  // POST REFERENCE — used to navigate to the post on tap
  final String postId;

  NotificationModel({

    required this.id,

    required this.senderName,

    required this.senderPhoto,

    required this.type,

    required this.text,

    required this.isRead,

    required this.createdAt,

    required this.postId,
  });

  factory NotificationModel.fromJson(
    Map<String, dynamic> json,
  ) {

    // post field arrives as populated object { _id: "..." } or raw string id
    String resolvedPostId = "";

    final rawPost = json["post"];

    if (rawPost is Map) {

      resolvedPostId =
          rawPost["_id"]?.toString() ?? "";

    } else if (rawPost is String) {

      resolvedPostId = rawPost;
    }

    return NotificationModel(

      id:
          json["_id"] ?? "",

      senderName:
          json["senderName"] ?? "",

      senderPhoto:
          json["senderPhoto"] ?? "",

      type:
          json["type"] ?? "",

      text:
          json["text"] ?? "",

      isRead:
          json["isRead"] ?? false,

      createdAt:
          json["createdAt"] ?? "",

      postId: resolvedPostId,
    );
  }
}