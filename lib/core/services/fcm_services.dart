import 'dart:convert';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';

// ─── BACKGROUND MESSAGE HANDLER ─────────────────────────────────────────────
// Must be a top-level function — not inside a class
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(
  RemoteMessage message,
) async {
  // Firebase is already initialised in the app — no extra init needed here
  print("FCM Background: ${message.messageId}");
}

// ─── FCM SERVICE ────────────────────────────────────────────────────────────
class FcmService {

  static const String _baseUrl =
      "http://10.104.108.80:5000/api/users";

  static const String _channelId =
      "addalink_notifications";

  static const String _channelName =
      "AddaLink Notifications";

  // Local notifications plugin (for foreground display)
  static final FlutterLocalNotificationsPlugin
      _localNotifications =
          FlutterLocalNotificationsPlugin();

  // Navigation key — set this from main.dart so FCM can push routes
  static GlobalKey<NavigatorState>? navigatorKey;

  // ── INIT ──────────────────────────────────────────────────────────────────
  static Future<void> init({
    required GlobalKey<NavigatorState> navKey,
  }) async {

    navigatorKey = navKey;

    final messaging = FirebaseMessaging.instance;

    // REQUEST PERMISSION (iOS + Android 13+)
    await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // ANDROID NOTIFICATION CHANNEL
    const AndroidNotificationChannel channel =
        AndroidNotificationChannel(
      _channelId,
      _channelName,
      description:
          "Likes, comments and community updates",
      importance: Importance.high,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    // INIT LOCAL NOTIFICATIONS
    const InitializationSettings initSettings =
        InitializationSettings(
      android: AndroidInitializationSettings(
        "@mipmap/ic_launcher",
      ),
      iOS: DarwinInitializationSettings(),
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (details) {
        // User tapped a local notification (foreground)
        _handleNotificationTap(details.payload);
      },
    );

    // FOREGROUND MESSAGES — show as local notification
    FirebaseMessaging.onMessage.listen((message) {
      _showLocalNotification(message);
    });

    // BACKGROUND TAP — app was in background, user tapped notification
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      _routeFromMessage(message);
    });

    // TERMINATED TAP — app was closed, user tapped notification
    final RemoteMessage? initialMessage =
        await messaging.getInitialMessage();

    if (initialMessage != null) {
      // Delay to let the widget tree build first
      Future.delayed(const Duration(milliseconds: 500), () {
        _routeFromMessage(initialMessage);
      });
    }

    // GET + SAVE TOKEN
    await saveTokenToBackend();

    // TOKEN REFRESH
    messaging.onTokenRefresh.listen((newToken) async {
      await _sendTokenToBackend(newToken);
    });
  }

  // ── SAVE TOKEN TO BACKEND ─────────────────────────────────────────────────
  static Future<void> saveTokenToBackend() async {

    try {

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final fcmToken =
          await FirebaseMessaging.instance.getToken();
      if (fcmToken == null) return;

      final idToken = await user.getIdToken();

      await _sendTokenToBackend(fcmToken, idToken: idToken);

    } catch (e) {
      print("FCM save token error: $e");
    }
  }

  static Future<void> _sendTokenToBackend(
    String fcmToken, {
    String? idToken,
  }) async {

    try {

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final token = idToken ?? await user.getIdToken();

      await http.post(
        Uri.parse("$_baseUrl/fcm-token"),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
        body: jsonEncode({"fcmToken": fcmToken}),
      );

    } catch (e) {
      print("FCM send token error: $e");
    }
  }

  // ── SHOW LOCAL NOTIFICATION (foreground) ─────────────────────────────────
  static void _showLocalNotification(RemoteMessage message) {

    final notification = message.notification;
    if (notification == null) return;

    final data = message.data;

    _localNotifications.show(
      message.hashCode,
      notification.title,
      notification.body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          importance: Importance.high,
          priority: Priority.high,
          icon: "@mipmap/ic_launcher",
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      // Pass data as JSON payload so tap handler can route
      payload: jsonEncode(data),
    );
  }

  // ── HANDLE LOCAL NOTIFICATION TAP ────────────────────────────────────────
  static void _handleNotificationTap(String? payload) {

    if (payload == null) return;

    try {
      final data = jsonDecode(payload) as Map<String, dynamic>;
      _navigate(data);
    } catch (_) {}
  }

  // ── ROUTE FROM FCM MESSAGE ────────────────────────────────────────────────
  static void _routeFromMessage(RemoteMessage message) {
    _navigate(message.data);
  }

  // ── CORE NAVIGATION LOGIC ─────────────────────────────────────────────────
  // Reads type + postId from FCM data and pushes PostDetailScreen
  static void _navigate(Map<String, dynamic> data) {

    final String postId = data["postId"] ?? "";
    final String type = data["type"] ?? "";

    if (postId.isEmpty) return;

    final context =
        navigatorKey?.currentContext;
    if (context == null) return;

    // Avoid circular import — use dynamic route string approach
    // PostDetailScreen is imported where navigatorKey is used (main.dart)
    navigatorKey?.currentState?.pushNamed(
      "/post-detail",
      arguments: {
        "postId": postId,
        "openComments": type == "comment",
      },
    );
  }
}