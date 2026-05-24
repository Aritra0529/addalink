import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

class ProfileService {

  static const String _baseUrl =
      "http://10.104.108.80:5000/api/users";

  // GET PROFILE (own profile + posts + stats)
  Future<Map<String, dynamic>> getProfile({
    required String token,
  }) async {

    final response = await http.get(

      Uri.parse("$_baseUrl/profile"),

      headers: {
        "Authorization": "Bearer $token",
      },
    );

    return jsonDecode(response.body);
  }

  // COMPLETE PROFILE (onboarding)
  Future<Map<String, dynamic>> completeProfile({
    required String token,
    required String username,
    required String phone,
    required String bio,
    required List<String> interests,
    required Map<String, dynamic> location,
  }) async {

    final response = await http.post(

      Uri.parse("$_baseUrl/complete-profile"),

      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },

      body: jsonEncode({
        "username": username,
        "phone": phone,
        "bio": bio,
        "interests": interests,
        "location": location,
      }),
    );

    return jsonDecode(response.body);
  }

  // UPDATE PROFILE (multipart — supports photo upload)
  Future<Map<String, dynamic>> updateProfile({
    required String token,
    required String username,
    required String bio,
    required String phone,
    required List<String> interests,
    required Map<String, dynamic> location,
    File? photo,
  }) async {

    final request = http.MultipartRequest(
      "PUT",
      Uri.parse("$_baseUrl/update-profile"),
    );

    request.headers["Authorization"] =
        "Bearer $token";

    request.fields["username"] = username;
    request.fields["bio"] = bio;
    request.fields["phone"] = phone;
    request.fields["interests"] =
        jsonEncode(interests);
    request.fields["location"] =
        jsonEncode(location);

    if (photo != null) {
      request.files.add(
        await http.MultipartFile.fromPath(
          "photo",
          photo.path,
        ),
      );
    }

    final streamed = await request.send();
    final response =
        await http.Response.fromStream(streamed);

    return jsonDecode(response.body);
  }
}