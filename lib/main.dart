import 'package:addalink/core/services/fcm_services.dart';
import 'package:addalink/features/splash/splash_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

import 'features/auth/auth_screen.dart';
import 'features/feed/post_detail_screen.dart';


// GLOBAL NAVIGATOR KEY — used by FcmService to push routes from anywhere
final GlobalKey<NavigatorState> navigatorKey =
    GlobalKey<NavigatorState>();

Future<void> main() async {

  WidgetsFlutterBinding.ensureInitialized();

  // INIT FIREBASE
  await Firebase.initializeApp();

  // REGISTER BACKGROUND MESSAGE HANDLER
  // Must be called before runApp
  FirebaseMessaging.onBackgroundMessage(
    firebaseMessagingBackgroundHandler,
  );

  runApp(const AddaLinkApp());
}

class AddaLinkApp extends StatefulWidget {

  const AddaLinkApp({super.key});

  @override
  State<AddaLinkApp> createState() =>
      _AddaLinkAppState();
}

class _AddaLinkAppState
    extends State<AddaLinkApp> {

  @override
  void initState() {
    super.initState();

    // INIT FCM AFTER FIRST FRAME
    WidgetsBinding.instance
        .addPostFrameCallback((_) {
      FcmService.init(navKey: navigatorKey);
    });
  }

  @override
  Widget build(BuildContext context) {

    return MaterialApp(

      title: "AddaLink",

      debugShowCheckedModeBanner: false,

      // GLOBAL NAVIGATOR KEY
      navigatorKey: navigatorKey,

      theme: ThemeData(
        fontFamily: "Inter",
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6C4DFF),
        ),
        useMaterial3: true,
      ),

      // ENTRY POINT
      home: const SplashScreen(),

      // NAMED ROUTES — used by FcmService._navigate()
      onGenerateRoute: (settings) {

        if (settings.name == "/post-detail") {

          final args = settings.arguments
              as Map<String, dynamic>? ?? {};

          return MaterialPageRoute(

            builder: (_) => PostDetailScreen(

              postId: args["postId"] ?? "",

              openComments:
                  args["openComments"] ?? false,
            ),
          );
        }

        return null;
      },
    );
  }
}