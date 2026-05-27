import 'notification_model.dart';
import 'notification_service.dart';

class NotificationController {
  final NotificationService _service = NotificationService();

  // ── FETCH NOTIFICATIONS (page 1 — full refresh) ───────────────────────────
  /// Returns the first page of notifications.
  /// Also returns the server-side unreadCount in [result].unreadCount
  /// so the caller doesn't need a second network call.
  Future<NotificationFetchResult> getNotifications({
    required String token,
  }) async {
    final response = await _service.getNotifications(
      token: token,
      page:  1,
      limit: 20,
    );

    if (response["success"] == true) {
      final List items       = response["notifications"] as List? ?? [];
      final int  unreadCount = (response["unreadCount"] as int?) ?? 0;
      final bool hasMore     = (response["hasMore"] as bool?) ?? false;

      return NotificationFetchResult(
        notifications: items
            .map((e) => NotificationModel.fromJson(e as Map<String, dynamic>))
            .toList(),
        unreadCount: unreadCount,
        hasMore:     hasMore,
      );
    }

    return NotificationFetchResult.empty();
  }

  // ── GET UNREAD COUNT (badge only) ─────────────────────────────────────────
  /// Lightweight — does NOT fetch the full notification list.
  Future<int> getUnreadCount({required String token}) async {
    return _service.getUnreadCount(token: token);
  }

  // ── MARK ALL AS READ ──────────────────────────────────────────────────────
  Future<void> markAllAsRead({required String token}) async {
    await _service.markAllAsRead(token: token);
  }

  // ── MARK ONE AS READ ──────────────────────────────────────────────────────
  Future<void> markOneAsRead({
    required String token,
    required String notificationId,
  }) async {
    await _service.markOneAsRead(
      token:          token,
      notificationId: notificationId,
    );
  }
}

// ─── RESULT WRAPPER ──────────────────────────────────────────────────────────
class NotificationFetchResult {
  final List<NotificationModel> notifications;
  final int  unreadCount;
  final bool hasMore;

  const NotificationFetchResult({
    required this.notifications,
    required this.unreadCount,
    required this.hasMore,
  });

  factory NotificationFetchResult.empty() => const NotificationFetchResult(
    notifications: [],
    unreadCount:   0,
    hasMore:       false,
  );
}
