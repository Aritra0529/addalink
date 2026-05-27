import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';

import 'profile_service.dart';

class ProfileController {

  final ProfileService _service =
      ProfileService();

  // GET PROFILE — returns raw map (user + posts + stats)
  // Used by: HomeFeedScreen, CreatePostScreen, PostDetailScreen, NotificationScreen
  Future<Map<String, dynamic>> getProfile() async {

    final user =
        FirebaseAuth.instance.currentUser;

    if (user == null) {
      return {"success": false, "user": {}};
    }

    final token = await user.getIdToken();

    return await _service.getProfile(
      token: token!,
    );
  }

  // COMPLETE PROFILE — onboarding step after first Google login
  Future<Map<String, dynamic>> completeProfile({
    required String username,
    required String phone,
    required String bio,
    required List<String> interests,
    required Map<String, dynamic> location,
  }) async {

    final user =
        FirebaseAuth.instance.currentUser;

    if (user == null) {
      return {"success": false};
    }

    final token = await user.getIdToken();

    return await _service.completeProfile(
      token: token!,
      username: username,
      phone: phone,
      bio: bio,
      interests: interests,
      location: location,
    );
  }

  // UPDATE PROFILE — edit profile screen
  Future<Map<String, dynamic>> updateProfile({
    required String username,
    required String bio,
    required String phone,
    required List<String> interests,
    required Map<String, dynamic> location,
    File? photo,
  }) async {

    final user =
        FirebaseAuth.instance.currentUser;

    if (user == null) {
      return {"success": false};
    }

    final token = await user.getIdToken();

    return await _service.updateProfile(
      token: token!,
      username: username,
      bio: bio,
      phone: phone,
      interests: interests,
      location: location,
      photo: photo,
    );
  }

  // EDIT POST — profile screen (own posts only)
  Future<Map<String, dynamic>> editPost(
    String postId,
    String content,
  ) async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return {"success": false};
    }

    final token = await user.getIdToken();

    return await _service.editPost(
      token: token!,
      postId: postId,
      content: content,
    );
  }

  // DELETE POST — profile screen (own posts only)
  Future<Map<String, dynamic>> deletePost(String postId) async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return {"success": false};
    }

    final token = await user.getIdToken();

    return await _service.deletePost(
      token: token!,
      postId: postId,
    );
  }
}