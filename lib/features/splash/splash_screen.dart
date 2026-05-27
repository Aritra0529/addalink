import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';

import 'package:flutter/material.dart';

import 'package:http/http.dart' as http;

import '../auth/auth_screen.dart';

import '../feed/home_feed_screen.dart';

import '../profile/complete_profile_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();

    checkUser();
  }

  Future<void> checkUser() async {
    await Future.delayed(const Duration(seconds: 4));

    final firebaseUser = FirebaseAuth.instance.currentUser;

    // USER NOT LOGGED IN
    if (firebaseUser == null) {
      navigateTo(AuthScreen());

      return;
    }

    try {
      final firebaseToken = await firebaseUser.getIdToken() ?? "";

      final response = await http.get(
        Uri.parse("http://10.182.129.80:5000/api/users/me"),

        headers: {"Authorization": "Bearer $firebaseToken"},
      );

      final data = jsonDecode(response.body);

      // SUCCESS
      if (data["success"] == true) {
        final user = data["user"];

        // PROFILE COMPLETE
        if (user["isProfileComplete"] == true) {
          navigateTo(const HomeFeedScreen());
        } else {
          navigateTo(const CompleteProfileScreen());
        }
      } else {
        navigateTo(AuthScreen());
      }
    } catch (e) {
      print(e);

      navigateTo(AuthScreen());
    }
  }

  void navigateTo(Widget screen) {
    Navigator.pushReplacement(
      context,

      MaterialPageRoute(builder: (_) => screen),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1A),

      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,

            children: [
              // LOGO CONTAINER
              Container(
                height: 140,
                width: 140,

                decoration: BoxDecoration(
                  color: const Color(0xFF1B1B2F),

                  borderRadius: BorderRadius.circular(35),

                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF6C4DFF).withOpacity(0.5),

                      blurRadius: 30,

                      spreadRadius: 5,
                    ),
                  ],
                ),

                child: Padding(
                  padding: const EdgeInsets.all(20),

                  child: Image.asset(
                    "assets/images/logo.png",

                    fit: BoxFit.contain,
                  ),
                ),
              ),

              const SizedBox(height: 35),

              // APP NAME
              const Text(
                "AddaLink",

                style: TextStyle(
                  color: Colors.white,

                  fontSize: 36,

                  fontWeight: FontWeight.bold,

                  letterSpacing: 1,
                ),
              ),

              const SizedBox(height: 12),

              // TAGLINE
              const Text(
                "AI Powered Hyperlocal Community",

                style: TextStyle(
                  color: Colors.white70,

                  fontSize: 15,

                  letterSpacing: 0.6,
                ),
              ),

              const SizedBox(height: 60),

              // LOADER
              const CircularProgressIndicator(
                color: Color(0xFF6C4DFF),

                strokeWidth: 3,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
