import 'package:flutter/foundation.dart';
import 'package:video_player/video_player.dart';

/// Centralized service for managing video playback across the feed.
/// Ensures only one video plays at a time and handles visibility-based pause/resume.
/// 
/// Architecture:
/// - SingletonPattern: Only one instance manages all feed videos
/// - ActiveVideoTracking: Tracks which video is currently active
/// - VisibilityManagement: Pauses videos when they scroll offscreen
/// - ControllerPooling: Lazy initializes and aggressively disposes controllers
/// - MemoryOptimization: Prevents memory leaks during scrolling
class VideoManagerService with ChangeNotifier {
  static final VideoManagerService _instance =
      VideoManagerService._internal();

  factory VideoManagerService() {
    return _instance;
  }

  VideoManagerService._internal();

  // Track the currently active video controller
  VideoPlayerController? _activeController;
  String? _activeVideoId;

  // Pool of controllers keyed by post ID
  final Map<String, VideoPlayerController> _controllerPool = {};

  // Track initialized videos to prevent re-initialization
  final Set<String> _initializedVideos = {};

  // Visibility state: tracks which videos are currently visible
  final Map<String, bool> _videoVisibility = {};

  // Getter for active video ID
  String? get activeVideoId => _activeVideoId;

  // Getter for active controller
  VideoPlayerController? get activeController => _activeController;

  /// Register a video as visible on screen
  /// Automatically pauses other videos and plays this one if it's initialized
  void setVideoVisible(String videoId, {required bool isVisible}) {
    _videoVisibility[videoId] = isVisible;

    if (isVisible) {
      // Pause previous active video if different
      if (_activeVideoId != videoId && _activeController != null) {
        _pauseVideo(_activeVideoId);
      }

      // Set this as active and play if initialized
      _activeVideoId = videoId;
      _activeController = _controllerPool[videoId];

      if (_activeController != null && _activeController!.value.isInitialized) {
        _playVideo(videoId);
      }
    } else {
      // Pause if this was the active video
      if (_activeVideoId == videoId) {
        _pauseVideo(videoId);
        _activeVideoId = null;
        _activeController = null;
      }
    }

    notifyListeners();
  }

  /// Initialize a video controller lazily (only when needed)
  /// Returns existing controller if already initialized
  Future<VideoPlayerController?> initializeVideo(
    String videoId,
    String videoUrl,
  ) async {
    // Return cached controller if already initialized
    if (_controllerPool.containsKey(videoId)) {
      return _controllerPool[videoId];
    }

    // Prevent duplicate initialization
    if (_initializedVideos.contains(videoId)) {
      return _controllerPool[videoId];
    }

    _initializedVideos.add(videoId);

    try {
      final controller = VideoPlayerController.networkUrl(
        Uri.parse(videoUrl),
      );

      // Initialize with muted for better UX and performance
      await controller.initialize();
      controller.setVolume(0);

      _controllerPool[videoId] = controller;

      // Auto-play if this is the currently visible video
      if (_videoVisibility[videoId] == true && _activeVideoId == videoId) {
        _playVideo(videoId);
      }

      return controller;
    } catch (e) {
      _initializedVideos.remove(videoId);
      print('Failed to initialize video $videoId: $e');
      return null;
    }
  }

  /// Play a specific video (if it's the active one)
  void _playVideo(String? videoId) {
    if (videoId == null) return;

    final controller = _controllerPool[videoId];
    if (controller != null && 
        controller.value.isInitialized && 
        !controller.value.isPlaying) {
      controller.play();
    }
  }

  /// Pause a specific video
  void _pauseVideo(String? videoId) {
    if (videoId == null) return;

    final controller = _controllerPool[videoId];
    if (controller != null && 
        controller.value.isInitialized && 
        controller.value.isPlaying) {
      controller.pause();
    }
  }

  /// Toggle play/pause for a specific video
  /// Can be called by UI when user taps play/pause button
  void togglePlayPause(String videoId) {
    final controller = _controllerPool[videoId];
    if (controller != null && controller.value.isInitialized) {
      if (controller.value.isPlaying) {
        controller.pause();
      } else {
        // Ensure this is the only playing video
        if (_activeVideoId != videoId && _activeController != null) {
          _pauseVideo(_activeVideoId);
        }
        _activeVideoId = videoId;
        _activeController = controller;
        controller.play();
      }
      notifyListeners();
    }
  }

  /// Unmute a video (user interaction)
  void unmuteVideo(String videoId) {
    final controller = _controllerPool[videoId];
    if (controller != null) {
      controller.setVolume(1.0);
    }
  }

  /// Check if a video is currently playing
  bool isVideoPlaying(String videoId) {
    final controller = _controllerPool[videoId];
    return controller != null && 
           controller.value.isInitialized && 
           controller.value.isPlaying;
  }

  /// Dispose a specific video controller
  /// Called when post is removed from feed or scrolled far away
  void disposeVideo(String videoId) {
    final controller = _controllerPool.remove(videoId);
    if (controller != null) {
      if (controller.value.isPlaying) {
        controller.pause();
      }
      controller.dispose();
    }

    _initializedVideos.remove(videoId);
    _videoVisibility.remove(videoId);

    // Clear active controller if it's the disposed one
    if (_activeVideoId == videoId) {
      _activeVideoId = null;
      _activeController = null;
    }

    notifyListeners();
  }

  /// Dispose all video controllers
  /// Called when leaving the feed screen
  void disposeAll() {
    for (var controller in _controllerPool.values) {
      if (controller.value.isPlaying) {
        controller.pause();
      }
      controller.dispose();
    }
    _controllerPool.clear();
    _initializedVideos.clear();
    _videoVisibility.clear();
    _activeVideoId = null;
    _activeController = null;

    notifyListeners();
  }

  /// Pause active video (e.g., when app goes to background)
  void pauseActive() {
    if (_activeVideoId != null) {
      _pauseVideo(_activeVideoId);
    }
  }

  /// Resume active video (e.g., when app comes to foreground)
  void resumeActive() {
    if (_activeVideoId != null && 
        _videoVisibility[_activeVideoId] == true) {
      _playVideo(_activeVideoId);
    }
  }

  /// Get total number of managed controllers (for debugging)
  int get controllerCount => _controllerPool.length;

  /// Get visibility state for a video
  bool isVideoVisible(String videoId) {
    return _videoVisibility[videoId] ?? false;
  }
}