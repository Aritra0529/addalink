import 'package:flutter/material.dart';

import 'notification_model.dart';

class NotificationTile
    extends StatelessWidget {

  final NotificationModel notification;

  const NotificationTile({

    super.key,

    required this.notification,
  });

  // FORMAT TIME AGO
  String _timeAgo(String isoString) {

    if (isoString.isEmpty) {
      return "";
    }

    try {

      final DateTime created =
          DateTime.parse(isoString).toLocal();

      final Duration diff =
          DateTime.now().difference(created);

      if (diff.inSeconds < 60) {
        return "${diff.inSeconds}s ago";
      } else if (diff.inMinutes < 60) {
        return "${diff.inMinutes}m ago";
      } else if (diff.inHours < 24) {
        return "${diff.inHours}h ago";
      } else if (diff.inDays < 7) {
        return "${diff.inDays}d ago";
      } else {
        return "${(diff.inDays / 7).floor()}w ago";
      }

    } catch (_) {
      return "";
    }
  }

  // ICON FOR TYPE
  IconData _typeIcon() {
    switch (notification.type) {
      case "like":
        return Icons.favorite;
      case "comment":
        return Icons.mode_comment;
      default:
        return Icons.notifications;
    }
  }

  // COLOR FOR TYPE
  Color _typeColor() {
    switch (notification.type) {
      case "like":
        return const Color(0xFFFF4D6D);
      case "comment":
        return const Color(0xFF6C4DFF);
      default:
        return const Color(0xFF6C4DFF);
    }
  }

  @override
  Widget build(BuildContext context) {

    return Container(

      margin: const EdgeInsets.only(
        bottom: 12,
      ),

      padding: const EdgeInsets.all(14),

      decoration: BoxDecoration(

        color: notification.isRead
            ? Colors.white
            : const Color(0xFFF0EDFF),

        borderRadius: BorderRadius.circular(20),

        border: Border.all(
          color: notification.isRead
              ? const Color(0xFFE8EAF2)
              : const Color(0xFFD0C8FF),
        ),

        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),

      child: Row(

        crossAxisAlignment:
            CrossAxisAlignment.center,

        children: [

          // AVATAR WITH TYPE BADGE
          Stack(

            children: [

              CircleAvatar(

                radius: 24,

                backgroundColor:
                    const Color(0xFF6C4DFF),

                backgroundImage:
                    notification.senderPhoto.isNotEmpty
                        ? NetworkImage(
                            notification.senderPhoto,
                          )
                        : null,

                child: notification.senderPhoto.isEmpty
                    ? const Icon(
                        Icons.person,
                        color: Colors.white,
                        size: 22,
                      )
                    : null,
              ),

              Positioned(

                bottom: 0,

                right: 0,

                child: Container(

                  padding: const EdgeInsets.all(3),

                  decoration: BoxDecoration(
                    color: _typeColor(),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white,
                      width: 1.5,
                    ),
                  ),

                  child: Icon(
                    _typeIcon(),
                    color: Colors.white,
                    size: 9,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(width: 14),

          // TEXT
          Expanded(

            child: Column(

              crossAxisAlignment:
                  CrossAxisAlignment.start,

              children: [

                RichText(

                  text: TextSpan(

                    children: [

                      TextSpan(

                        text: notification.senderName.isNotEmpty
                            ? notification.senderName
                            : "Someone",

                        style: const TextStyle(

                          color: Color(0xFF1B1D28),

                          fontWeight: FontWeight.w700,

                          fontSize: 14,
                        ),
                      ),

                      const TextSpan(text: " "),

                      TextSpan(

                        text: notification.text.isNotEmpty
                            ? notification.text
                            : notification.type == "like"
                                ? "liked your post"
                                : "commented on your post",

                        style: const TextStyle(

                          color: Color(0xFF70758A),

                          fontWeight: FontWeight.w400,

                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 5),

                Text(

                  _timeAgo(notification.createdAt),

                  style: const TextStyle(

                    color: Color(0xFF70758A),

                    fontSize: 12,

                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 10),

          // UNREAD DOT
          if (!notification.isRead)

            Container(

              width: 9,

              height: 9,

              decoration: const BoxDecoration(

                color: Color(0xFF6C4DFF),

                shape: BoxShape.circle,
              ),
            ),
        ],
      ),
    );
  }
}