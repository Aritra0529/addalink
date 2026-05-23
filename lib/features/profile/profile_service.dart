import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

class ProfileService {
  static const String baseUrl =
      "http://10.104.108.80:5000/api/users";

  // GET PROFILE
  Future<Map<String, dynamic>> getProfile({
    required String firebaseToken,
  }) async {
    final response = await http.get(
      Uri.parse("$baseUrl/profile"),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $firebaseToken",
      },
    );

    return jsonDecode(response.body);
  }

  // UPDATE PROFILE
  Future<Map<String, dynamic>> updateProfile({
    required String firebaseToken,
    required Map<String, dynamic> data,
    File? profileImageFile,
  }) async {
    final uri = Uri.parse("$baseUrl/update-profile");

    final request = http.MultipartRequest("PUT", uri);

    request.headers["Authorization"] =
        "Bearer $firebaseToken";

    // TEXT FIELDS
    if (data["username"] != null) {
      request.fields["username"] =
          data["username"].toString();
    }

    if (data["bio"] != null) {
      request.fields["bio"] =
          data["bio"].toString();
    }

    if (data["phone"] != null) {
      request.fields["phone"] =
          data["phone"].toString();
    }

    if (data["interests"] != null) {
      final List interests = data["interests"];
      request.fields["interests"] =
          jsonEncode(interests);
    }

    if (data["location"] != null) {
      request.fields["location"] =
          jsonEncode(data["location"]);
    }

    // PROFILE IMAGE
    if (profileImageFile != null) {
      final multipartFile =
          await http.MultipartFile.fromPath(
        "profileImage",
        profileImageFile.path,
      );
      request.files.add(multipartFile);
    }

    final streamedResponse = await request.send();

    final responseBody =
        await streamedResponse.stream.bytesToString();

    return jsonDecode(responseBody);
  }

  // COMPLETE PROFILE (existing — preserved)
  Future<Map<String, dynamic>> completeProfile({
    required String firebaseToken,
    required Map<String, dynamic> data,
  }) async {
    final response = await http.post(
      Uri.parse("$baseUrl/complete-profile"),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $firebaseToken",
      },
      body: jsonEncode(data),
    );

    return jsonDecode(response.body);
  }
}