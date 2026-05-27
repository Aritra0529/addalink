import 'dart:async';

import 'package:addalink/core/services/video_manager_service.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:visibility_detector/visibility_detector.dart';

import 'video_thumbnail.dart';

class FeedVideoPlayer extends StatefulWidget {
  final String postId;
  final String videoUrl;
  final String? thumbnailUrl;
  final VoidCallback? onStateChange;
  final double height;
  final double? aspectRatio;
  final bool showThumbnailWhileLoading;
  final bool autoplay;

  const FeedVideoPlayer({
    super.key,
    required this.postId,
    required this.videoUrl,
    this.thumbnailUrl,
    this.onStateChange,
    this.height = 240,
    this.aspectRatio,
    this.showThumbnailWhileLoading = true,
    this.autoplay = true,
  });

  @override
  State<FeedVideoPlayer> createState() => _FeedVideoPlayerState();
}

class _FeedVideoPlayerState extends State<FeedVideoPlayer>
    with WidgetsBindingObserver {
  late final VideoManagerService _videoManager;
  late final String _videoId;

  VideoPlayerController? _controller;
  bool _isInitialized = false;
  bool _isVisible = false;
  bool _isInitializing = false;

  // Controls visibility — auto-hides after 3 s of no interaction
  bool _showControls = true;
  Timer? _hideTimer;

  // Seek state — while dragging we show the dragged position, not the real one
  bool _isSeeking = false;
  double _seekValue = 0;

  // Mute state mirrored locally so the icon updates instantly
  bool _isMuted = true;

  @override
  void initState() {
    super.initState();
    _videoManager = VideoManagerService();
    _videoId = widget.postId;
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    _controller?.removeListener(_onControllerUpdate);
    _videoManager.setVideoVisible(_videoId, isVisible: false);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _videoManager.pauseActive();
    } else if (state == AppLifecycleState.resumed) {
      if (_isVisible) _videoManager.resumeActive();
    }
  }

  // ─── Controller listener ───────────────────────────────────────────────────

  void _onControllerUpdate() {
    if (mounted) setState(() {});
  }

  // ─── Initialization ────────────────────────────────────────────────────────

  Future<void> _initializeVideo() async {
    if (_isInitializing || _isInitialized) return;
    _isInitializing = true;

    try {
      final controller = await _videoManager.initializeVideo(
        _videoId,
        widget.videoUrl,
      );

      if (mounted && controller != null) {
        // Attach listener so every tick (position, isPlaying, volume) rebuilds
        controller.addListener(_onControllerUpdate);

        setState(() {
          _controller = controller;
          _isInitialized = true;
          _isInitializing = false;
          _isMuted = controller.value.volume == 0;
        });

        widget.onStateChange?.call();

        if (_isVisible && widget.autoplay) {
          _videoManager.setVideoVisible(_videoId, isVisible: true);
        }
      }
    } catch (e) {
      if (mounted) setState(() => _isInitializing = false);
      debugPrint('FeedVideoPlayer init error: $e');
    }
  }

  // ─── Visibility ────────────────────────────────────────────────────────────

  void _onVisibilityChanged(VisibilityInfo info) {
    final isVisible = info.visibleFraction > 0.5;

    if (isVisible && !_isVisible) {
      _isVisible = true;
      if (!_isInitialized) {
        _initializeVideo();
      } else {
        _videoManager.setVideoVisible(_videoId, isVisible: true);
      }
    } else if (!isVisible && _isVisible) {
      _isVisible = false;
      _videoManager.setVideoVisible(_videoId, isVisible: false);
    }
  }

  // ─── Controls interaction ──────────────────────────────────────────────────

  /// Tap anywhere on the video: show controls (or hide if already visible)
  void _onVideoTap() {
    setState(() => _showControls = !_showControls);
    if (_showControls) _startHideTimer();
  }

  /// Play / pause
  void _togglePlayPause() {
    if (!_isInitialized) return;
    _videoManager.togglePlayPause(_videoId);
    _resetHideTimer();
  }

  /// Toggle mute / unmute
  void _toggleMute() {
    if (_controller == null) return;
    final newMuted = !_isMuted;
    _controller!.setVolume(newMuted ? 0 : 1.0);
    setState(() => _isMuted = newMuted);
    _resetHideTimer();
  }

  // ─── Seek ──────────────────────────────────────────────────────────────────

  void _onSeekStart(double value) {
    _hideTimer?.cancel();
    setState(() {
      _isSeeking = true;
      _seekValue = value;
    });
  }

  void _onSeekUpdate(double value) {
    setState(() => _seekValue = value);
  }

  void _onSeekEnd(double value) {
    final duration = _controller?.value.duration ?? Duration.zero;
    final position = Duration(
      milliseconds: (value * duration.inMilliseconds).round(),
    );
    _controller?.seekTo(position);
    setState(() => _isSeeking = false);
    _resetHideTimer();
  }

  // ─── Auto-hide timer ───────────────────────────────────────────────────────

  void _startHideTimer() {
    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) setState(() => _showControls = false);
    });
  }

  void _resetHideTimer() {
    setState(() => _showControls = true);
    _startHideTimer();
  }

  // ─── Helpers ───────────────────────────────────────────────────────────────

  String _formatDuration(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  // ─── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return VisibilityDetector(
      key: Key('video-$_videoId'),
      onVisibilityChanged: _onVisibilityChanged,
      child: _buildContent(),
    );
  }

  Widget _buildContent() {
    if (_isInitialized && _controller != null) {
      return _buildPlayer();
    }
    if (widget.showThumbnailWhileLoading && widget.thumbnailUrl != null) {
      return _buildThumbnailLoader();
    }
    return _buildLoadingState();
  }

  // ─── Fully built player ────────────────────────────────────────────────────

  Widget _buildPlayer() {
    final ctrl = _controller!;
    final duration = ctrl.value.duration;
    final position = _isSeeking
        ? Duration(milliseconds: (_seekValue * duration.inMilliseconds).round())
        : ctrl.value.position;
    final progress =
        duration.inMilliseconds > 0 ? position.inMilliseconds / duration.inMilliseconds : 0.0;
    final isPlaying = ctrl.value.isPlaying;
    final isBuffering = ctrl.value.isBuffering;

    return GestureDetector(
      onTap: _onVideoTap,
      behavior: HitTestBehavior.opaque,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(0),
        child: AspectRatio(
          aspectRatio: widget.aspectRatio ?? ctrl.value.aspectRatio,
          child: Stack(
            fit: StackFit.expand,
            children: [

              // ── Video frame ──────────────────────────────────────────────
              VideoPlayer(ctrl),

              // ── Buffering spinner ────────────────────────────────────────
              if (isBuffering)
                const Center(
                  child: SizedBox(
                    width: 36,
                    height: 36,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2.5,
                    ),
                  ),
                ),

              // ── Controls overlay (fades in/out) ──────────────────────────
              AnimatedOpacity(
                opacity: _showControls ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 200),
                child: IgnorePointer(
                  ignoring: !_showControls,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [

                      // Gradient scrim — bottom only so top stays clean
                      _buildScrim(),

                      // ── Centre play/pause ──────────────────────────────
                      Center(
                        child: GestureDetector(
                          onTap: _togglePlayPause,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.55),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                              color: Colors.white,
                              size: 30,
                            ),
                          ),
                        ),
                      ),

                      // ── Bottom bar: timeline + time + speaker ──────────
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 0,
                        child: _buildBottomBar(
                          progress: progress.clamp(0.0, 1.0),
                          position: position,
                          duration: duration,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildScrim() {
    return Positioned.fill(
      child: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            stops: [0.55, 1.0],
            colors: [
              Colors.transparent,
              Colors.black54,
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomBar({
    required double progress,
    required Duration position,
    required Duration duration,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 0, 10, 6),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [

          // ── Seek bar ──────────────────────────────────────────────────
          SizedBox(
            height: 24,
            child: SliderTheme(
              data: SliderTheme.of(context).copyWith(
                trackHeight: 2.5,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
                activeTrackColor: Colors.white,
                inactiveTrackColor: Colors.white30,
                thumbColor: Colors.white,
                overlayColor: Colors.white24,
              ),
              child: Slider(
                value: progress.clamp(0.0, 1.0),
                onChangeStart: _onSeekStart,
                onChanged: _onSeekUpdate,
                onChangeEnd: _onSeekEnd,
              ),
            ),
          ),

          // ── Time + speaker row ─────────────────────────────────────────
          Row(
            children: [

              // Current position
              Text(
                _formatDuration(position),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),

              const Text(
                ' / ',
                style: TextStyle(color: Colors.white54, fontSize: 11),
              ),

              // Total duration
              Text(
                _formatDuration(duration),
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 11,
                ),
              ),

              const Spacer(),

              // Speaker toggle — tap to mute/unmute
              GestureDetector(
                onTap: _toggleMute,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.45),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _isMuted ? Icons.volume_off_rounded : Icons.volume_up_rounded,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── Thumbnail loader (before init) ───────────────────────────────────────

  Widget _buildThumbnailLoader() {
    return Stack(
      alignment: Alignment.center,
      children: [
        VideoThumbnail(
          thumbnailUrl: widget.thumbnailUrl!,
          height: widget.height,
          showPlayIcon: !_isInitializing,
        ),
        if (_isInitializing)
          const SizedBox(
            width: 36,
            height: 36,
            child: CircularProgressIndicator(
              color: Colors.white,
              strokeWidth: 2.5,
            ),
          ),
      ],
    );
  }

  // ─── Fallback loading state ────────────────────────────────────────────────

  Widget _buildLoadingState() {
    return Container(
      height: widget.height,
      color: Colors.black12,
      child: const Center(
        child: SizedBox(
          width: 36,
          height: 36,
          child: CircularProgressIndicator(
            color: Colors.white,
            strokeWidth: 2.5,
          ),
        ),
      ),
    );
  }
}