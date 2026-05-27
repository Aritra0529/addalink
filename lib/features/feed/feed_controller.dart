import 'dart:io';

import 'feed_service.dart';
import 'post_model.dart';

class FeedController {

  final FeedService _service =
      FeedService();

  // PAGINATION STATE
  int currentPage = 1;
  bool hasMore = true;
  bool isLoadingMore = false;
  List<PostModel> cachedPosts = [];

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
  bool refresh = false,
}) async {

  // PREVENT DUPLICATE CALLS
  if (isLoadingMore) return cachedPosts;

  // RESET ON REFRESH
  if (refresh) {
    currentPage = 1;
    hasMore = true;
    cachedPosts = [];
  }

  // NOTHING MORE TO LOAD
  if (!hasMore) return cachedPosts;

  isLoadingMore = true;

  try {
    final response =
        await _service.getFeed(
      token: token,
      page: currentPage,
    );

    if (response["success"] == true) {

      final List posts =
          response["posts"];

      final newPosts = posts
          .map(
            (e) =>
                PostModel.fromJson(e),
          )
          .toList();

      cachedPosts.addAll(newPosts);

      hasMore =
          response["hasMore"] == true;

      currentPage += 1;
    }
  } finally {
    isLoadingMore = false;
  }

  return cachedPosts;
}

Future<Map<String, dynamic>>
    editPost({

  required String token,

  required String postId,

  required String content,
}) async {

  return await _service
      .editPost(

    token: token,

    postId: postId,

    content: content,
  );
}

Future<Map<String, dynamic>>
    deletePost({

  required String token,

  required String postId,
}) async {

  return await _service
      .deletePost(

    token: token,

    postId: postId,
  );
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