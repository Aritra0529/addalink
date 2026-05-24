import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;

class AuthService {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  final GoogleSignIn _googleSignIn = GoogleSignIn();

  static const String _baseUrl = "http://10.104.108.80:5000/api/auth";

  // CURRENT USER
  User? get currentUser => _firebaseAuth.currentUser;

  // GOOGLE SIGN IN
  Future<UserCredential?> signInWithGoogle() async {

  try {

    // FORCE ACCOUNT CHOOSER
    await _googleSignIn.disconnect();

    // OPEN GOOGLE ACCOUNT PICKER
    final GoogleSignInAccount? googleUser =
        await _googleSignIn.signIn();

    // USER CANCELLED LOGIN
    if (googleUser == null) {
      return null;
    }

    // GET AUTH DETAILS
    final GoogleSignInAuthentication googleAuth =
        await googleUser.authentication;

    // CREATE FIREBASE CREDENTIAL
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    // FIREBASE LOGIN
    UserCredential userCredential =
        await _firebaseAuth.signInWithCredential(
      credential,
    );

    return userCredential;

  } catch (e) {

    print("Google Sign In Error: $e");

    return null;
  }
}
  // BACKEND LOGIN — creates user in MongoDB and returns JWT
  Future<Map<String, dynamic>?>
    loginWithBackend(
  String firebaseToken,
) async {

  try {

    final response =
        await http.post(

      Uri.parse(
        "$_baseUrl/google-login",
      ),

      headers: {

        "Content-Type":
            "application/json",
      },

      body: jsonEncode({

        "firebaseToken":
            firebaseToken,
      }),
    );

    final data =
        jsonDecode(
      response.body,
    );

    if (data["success"] == true) {

      return data;
    }

    print(
      "Backend Login Error: ${data["message"]}",
    );

    return null;

  } catch (e) {

    print(
      "Backend Login Error: $e",
    );

    return null;
  }
}
  // LOGOUT
  Future<void> logout() async {
    try {
      await _googleSignIn.signOut();

      await _firebaseAuth.signOut();
    } catch (e) {
      print("Logout Error: $e");
    }
  }
}
