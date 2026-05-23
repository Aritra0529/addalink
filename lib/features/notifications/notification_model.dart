class NotificationModel {

  final String id;

  final String senderName;

  final String senderPhoto;

  final String type;

  final String text;

  final bool isRead;

  final String createdAt;

  NotificationModel({

    required this.id,

    required this.senderName,

    required this.senderPhoto,

    required this.type,

    required this.text,

    required this.isRead,

    required this.createdAt,
  });

  factory NotificationModel.fromJson(
    Map<String, dynamic> json,
  ) {

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
    );
  }
}