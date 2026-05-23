import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';

import 'profile_service.dart';

class ProfileController {
  final ProfileService _service = ProfileService();

  // GET PROFILE
  Future<Map<String, dynamic>> getProfile() async {
    final user = FirebaseAuth.instance.currentUser;

    final firebaseToken =
        await user!.getIdToken() ?? "";

    return await _service.getProfile(
      firebaseToken: firebaseToken,
    );
  }

  // UPDATE PROFILE
  Future<Map<String, dynamic>> updateProfile({
    required String username,
    required String bio,
    required String phone,
    required List<String> interests,
    required Map<String, dynamic> location,
    File? profileImageFile,
  }) async {
    final user = FirebaseAuth.instance.currentUser;

    final firebaseToken =
        await user!.getIdToken() ?? "";

    final data = {
      "username": username,
      "bio": bio,
      "phone": phone,
      "interests": interests,
      "location": location,
    };

    return await _service.updateProfile(
      firebaseToken: firebaseToken,
      data: data,
      profileImageFile: profileImageFile,
    );
  }

  // COMPLETE PROFILE (existing — preserved)
  Future<Map<String, dynamic>> completeProfile({
    required String username,
    required String phone,
    required String bio,
    required List<String> interests,
    required Map<String, dynamic> location,
  }) async {
    final user = FirebaseAuth.instance.currentUser;

    final firebaseToken =
        await user!.getIdToken() ?? "";

    final data = {
      "username": username,
      "phone": phone,
      "bio": bio,
      "interests": interests,
      "location": location,
    };

    return await _service.completeProfile(
      firebaseToken: firebaseToken,
      data: data,
    );
  }
}