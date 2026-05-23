import 'dart:convert';

import 'package:http/http.dart' as http;

class NotificationService {

  static const String _baseUrl =
      "http://10.104.108.80:5000/api/notifications";

  // GET NOTIFICATIONS
  Future<Map<String, dynamic>> getNotifications({
    required String token,
  }) async {

    final response = await http.get(

      Uri.parse(_baseUrl),

      headers: {
        "Authorization": "Bearer $token",
      },
    );

    return jsonDecode(response.body);
  }

  // MARK ALL AS READ
  Future<void> markAsRead({
    required String token,
  }) async {

    await http.put(

      Uri.parse("$_baseUrl/read"),

      headers: {
        "Authorization": "Bearer $token",
      },
    );
  }
}