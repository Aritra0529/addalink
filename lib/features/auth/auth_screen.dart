import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'auth_service.dart';
import '../feed/home_feed_screen.dart';
import '../profile/complete_profile_screen.dart';

class AuthScreen extends StatelessWidget {
  AuthScreen({super.key});

  final AuthService _authService = AuthService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF0F0F1A),
              Color(0xFF151528),
              Color(0xFF1E1B3A),
            ],
          ),
        ),

        child: Stack(
          children: [
            // TOP GLOW
            Positioned(
              top: -120,
              left: -80,
              child: Container(
                height: 250,
                width: 250,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(
                    0xFF6C4DFF,
                  ).withOpacity(0.25),
                ),
              ),
            ),

            // BOTTOM GLOW
            Positioned(
              bottom: -100,
              right: -60,
              child: Container(
                height: 220,
                width: 220,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.purpleAccent
                      .withOpacity(0.18),
                ),
              ),
            ),

            SafeArea(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(
                  horizontal: 24,
                ),

                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,

                  children: [
                    const SizedBox(height: 40),

                    // WELCOME TEXT
                    const Text(
                      "Welcome to",
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 22,
                        fontWeight:
                            FontWeight.w400,
                      ),
                    ),

                    const SizedBox(height: 8),

                    // APP NAME
                    const Text(
                      "AddaLink 👋",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 42,
                        fontWeight:
                            FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),

                    const SizedBox(height: 18),

                    // SUBTITLE
                    const Text(
                      "Connect with your nearby community, discover local places, explore events, and experience your locality smarter with AI.",
                      style: TextStyle(
                        color: Colors.white60,
                        fontSize: 16,
                        height: 1.6,
                      ),
                    ),

                    const Spacer(),

                    // CENTER LOGO
                    Center(
                      child: Container(
                        height: 160,
                        width: 160,

                        decoration: BoxDecoration(
                          borderRadius:
                              BorderRadius.circular(
                            40,
                          ),

                          gradient:
                              const LinearGradient(
                            colors: [
                              Color(0xFF6C4DFF),
                              Color(0xFF8E7CFF),
                            ],
                          ),

                          boxShadow: [
                            BoxShadow(
                              color: const Color(
                                0xFF6C4DFF,
                              ).withOpacity(
                                0.45,
                              ),

                              blurRadius: 40,
                              spreadRadius: 5,
                            ),
                          ],
                        ),

                        child: Padding(
                          padding:
                              const EdgeInsets.all(
                            25,
                          ),

                          child: Image.asset(
                            "assets/images/logo.png",
                          ),
                        ),
                      ),
                    ),

                    const Spacer(),

                    // AUTH CARD
                    Container(
                      padding:
                          const EdgeInsets.all(
                        22,
                      ),

                      decoration: BoxDecoration(
                        color: Colors.white
                            .withOpacity(
                          0.06,
                        ),

                        borderRadius:
                            BorderRadius.circular(
                          28,
                        ),

                        border: Border.all(
                          color: Colors.white
                              .withOpacity(
                            0.08,
                          ),
                        ),
                      ),

                      child: Column(
                        children: [
                          // GOOGLE BUTTON
                          GestureDetector(
                            onTap: () async {

                              // STEP 1 — FIREBASE SIGN IN
                              final UserCredential?
                                  userCredential =
                                  await _authService
                                      .signInWithGoogle();

                              if (userCredential ==
                                  null) {

                                ScaffoldMessenger.of(
                                  context,
                                ).showSnackBar(

                                  const SnackBar(
                                    content: Text(
                                      "Google Sign In Failed",
                                    ),
                                  ),
                                );

                                return;
                              }

                              // STEP 2 — GET FIREBASE TOKEN
                              final String?
                                  firebaseToken =
                                  await userCredential
                                      .user!
                                      .getIdToken();

                              if (firebaseToken ==
                                  null) {

                                ScaffoldMessenger.of(
                                  context,
                                ).showSnackBar(

                                  const SnackBar(
                                    content: Text(
                                      "Failed to get auth token",
                                    ),
                                  ),
                                );

                                return;
                              }

                              // STEP 3 — BACKEND LOGIN
                              final response =
                                  await _authService
                                      .loginWithBackend(
                                firebaseToken,
                              );

                              if (response ==
                                  null) {

                                ScaffoldMessenger.of(
                                  context,
                                ).showSnackBar(

                                  const SnackBar(
                                    content: Text(
                                      "Backend Authentication Failed",
                                    ),
                                  ),
                                );

                                return;
                              }

                              // STEP 4 — CHECK PROFILE STATUS
                              final bool
                                  isProfileComplete =

                                  response["user"]
                                          [
                                          "isProfileComplete"] ??

                                      false;

                              // STEP 5 — NAVIGATION
                              if (isProfileComplete) {

                                Navigator.pushReplacement(

                                  context,

                                  MaterialPageRoute(

                                    builder: (_) =>
                                        const HomeFeedScreen(),
                                  ),
                                );

                              } else {

                                Navigator.pushReplacement(

                                  context,

                                  MaterialPageRoute(

                                    builder: (_) =>

                                        const CompleteProfileScreen(),
                                  ),
                                );
                              }
                            },

                            child: Container(
                              height: 62,
                              width: double.infinity,

                              decoration: BoxDecoration(
                                borderRadius:
                                    BorderRadius.circular(
                                  18,
                                ),

                                gradient:
                                    const LinearGradient(
                                  colors: [
                                    Color(0xFF6C4DFF),
                                    Color(0xFF8E7CFF),
                                  ],
                                ),
                              ),

                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment
                                        .center,

                                children: [
                                  Image.asset(
                                    "assets/images/google.png",
                                    height: 24,
                                  ),

                                  const SizedBox(
                                    width: 14,
                                  ),

                                  const Text(
                                    "Continue with Google",

                                    style: TextStyle(
                                      color:
                                          Colors.white,

                                      fontSize: 17,

                                      fontWeight:
                                          FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(height: 18),

                          // TERMS TEXT
                          const Text(
                            "By continuing, you agree to our Terms & Privacy Policy",

                            textAlign:
                                TextAlign.center,

                            style: TextStyle(
                              color: Colors.white54,
                              fontSize: 13,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}