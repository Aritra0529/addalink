import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

class FeedService {
  static const String baseUrl = "http://10.104.108.80:5000/api/posts";

  Future<Map<String, dynamic>> createPost({
    required String token,

    required String content,

    required List<File> images,

    required File? video,

    required Map<String, dynamic> location,
  }) async {
    final request = http.MultipartRequest("POST", Uri.parse("$baseUrl/create"));

    // HEADERS
    request.headers.addAll({"Authorization": "Bearer $token"});

    // TEXT DATA
    request.fields["content"] = content;

    request.fields["location"] = jsonEncode(location);

    // IMAGE FILES
    if (images.isNotEmpty) {
      for (File image in images) {
        print("ADDING IMAGE: ${image.path}");

        request.files.add(
          await http.MultipartFile.fromPath("images", image.path),
        );
      }
    }

    // VIDEO FILE
    if (video != null) {
      print("ADDING VIDEO: ${video.path}");

      request.files.add(await http.MultipartFile.fromPath("video", video.path));
    }

    print("SENDING REQUEST...");

    final streamedResponse = await request.send();

    final response = await http.Response.fromStream(streamedResponse);

    print("STATUS CODE: ${response.statusCode}");

    print("RESPONSE: ${response.body}");

    return jsonDecode(response.body);
  }

  // GET FEED
  Future<Map<String, dynamic>> getFeed({required String token}) async {
    final response = await http.get(
      Uri.parse("$baseUrl/feed"),

      headers: {"Authorization": "Bearer $token"},
    );

    print("FEED RESPONSE: ${response.body}");

    return jsonDecode(response.body);
  }

  Future<Map<String, dynamic>> toggleLike({
    required String token,

    required String postId,
  }) async {
    final response = await http.put(
      Uri.parse("$baseUrl/like/$postId"),

      headers: {"Authorization": "Bearer $token"},
    );

    return jsonDecode(response.body);
  }

  Future<Map<String, dynamic>> addComment({
    required String token,

    required String postId,

    required String text,
  }) async {
    final response = await http.post(
      Uri.parse("$baseUrl/comment/$postId"),

      headers: {
        "Authorization": "Bearer $token",

        "Content-Type": "application/json",
      },

      body: jsonEncode({"text": text}),
    );

    return jsonDecode(response.body);
  }
}
