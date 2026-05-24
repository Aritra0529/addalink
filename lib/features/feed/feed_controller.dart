import 'dart:io';

import 'feed_service.dart';
import 'post_model.dart';

class FeedController {

  final FeedService _service =
      FeedService();

  Future<Map<String, dynamic>>
      createPost({

    required String token,

    required String content,

    required List<File> images,

    required File? video,

    required Map<String, dynamic>
        location,
  }) async {

    return await _service
        .createPost(

      token: token,

      content: content,

      images: images,

      video: video,

      location: location,
    );
  }
  Future<List<PostModel>>
    getFeedPosts({

  required String token,
}) async {

  final response =
      await _service.getFeed(
    token: token,
  );

  if (response["success"] ==
      true) {

    final List posts =
        response["posts"];

    return posts
        .map(
          (e) =>
              PostModel.fromJson(e),
        )
        .toList();
  }

  return [];
}
Future<Map<String, dynamic>>
    toggleLike({

  required String token,

  required String postId,
}) async {

  return await _service
      .toggleLike(

    token: token,

    postId: postId,
  );
}

Future<Map<String, dynamic>>
    addComment({

  required String token,

  required String postId,

  required String text,
}) async {

  return await _service
      .addComment(

    token: token,

    postId: postId,

    text: text,
  );
}

// GET SINGLE POST BY ID
Future<PostModel?> getPostById({

  required String token,

  required String postId,
}) async {

  final response =
      await _service.getPostById(

    token: token,

    postId: postId,
  );

  if (response["success"] == true) {

    return PostModel.fromJson(
      response["post"],
    );
  }

  return null;
}
}