import 'notification_model.dart';
import 'notification_service.dart';

class NotificationController {

  final NotificationService _service =
      NotificationService();

  // FETCH NOTIFICATIONS
  Future<List<NotificationModel>> getNotifications({
    required String token,
  }) async {

    final response =
        await _service.getNotifications(
      token: token,
    );

    if (response["success"] == true) {

      final List items =
          response["notifications"];

      return items
          .map(
            (e) =>
                NotificationModel.fromJson(e),
          )
          .toList();
    }

    return [];
  }

  // MARK ALL AS READ
  Future<void> markAsRead({
    required String token,
  }) async {

    await _service.markAsRead(
      token: token,
    );
  }
}