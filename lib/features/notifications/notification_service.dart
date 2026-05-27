import 'dart:convert';
import 'package:http/http.dart' as http;

class NotificationService {
  static const String _baseUrl = "http://10.182.129.80:5000/api/notifications";

  // ── GET NOTIFICATIONS (paginated) ─────────────────────────────────────────
  /// Returns the raw decoded response map.
  /// Supports optional [page] and [limit] for pagination.
  Future<Map<String, dynamic>> getNotifications({
    required String token,
    int page  = 1,
    int limit = 20,
  }) async {
    try {
      final uri = Uri.parse("$_baseUrl?page=$page&limit=$limit");
      final response = await http
          .get(uri, headers: {"Authorization": "Bearer $token"})
          .timeout(const Duration(seconds: 10));

      return jsonDecode(response.body) as Map<String, dynamic>;
    } catch (e) {
      return {"success": false, "notifications": [], "unreadCount": 0};
    }
  }

  // ── GET UNREAD COUNT (lightweight badge poll) ──────────────────────────────
  /// Returns unread count without fetching the full list.
  Future<int> getUnreadCount({required String token}) async {
    try {
      final uri = Uri.parse("$_baseUrl/unread-count");
      final response = await http
          .get(uri, headers: {"Authorization": "Bearer $token"})
          .timeout(const Duration(seconds: 8));

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return (data["unreadCount"] as int?) ?? 0;
    } catch (e) {
      return 0;
    }
  }

  // ── MARK ALL AS READ ──────────────────────────────────────────────────────
  Future<void> markAllAsRead({required String token}) async {
    try {
      await http
          .put(
            Uri.parse("$_baseUrl/read"),
            headers: {"Authorization": "Bearer $token"},
          )
          .timeout(const Duration(seconds: 8));
    } catch (_) {}
  }

  // ── MARK ONE AS READ ──────────────────────────────────────────────────────
  Future<void> markOneAsRead({
    required String token,
    required String notificationId,
  }) async {
    try {
      await http
          .put(
            Uri.parse("$_baseUrl/$notificationId/read"),
            headers: {"Authorization": "Bearer $token"},
          )
          .timeout(const Duration(seconds: 8));
    } catch (_) {}
  }
}
