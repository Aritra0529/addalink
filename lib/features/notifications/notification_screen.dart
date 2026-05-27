import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'notification_controller.dart';
import 'notification_model.dart';
import 'notification_tile.dart';
import '../feed/post_detail_screen.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen>
    with WidgetsBindingObserver {

  final NotificationController _controller = NotificationController();

  List<NotificationModel> _notifications = [];
  bool _isLoading  = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadAndMarkRead();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // Refresh when user returns to this screen from background
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _loadAndMarkRead();
    }
  }

  // ── LOAD + MARK ALL READ ───────────────────────────────────────────────────
  Future<void> _loadAndMarkRead() async {
    if (mounted) setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final token = await user.getIdToken();
      if (token == null) return;

      // Fetch notifications (includes unreadCount in response)
      final result = await _controller.getNotifications(token: token);

      // Auto-mark ALL as read (same behaviour as before)
      if (result.unreadCount > 0) {
        await _controller.markAllAsRead(token: token);
      }

      if (mounted) {
        setState(() {
          // Mark all as read locally so badge clears instantly without refetch
          _notifications = result.notifications
              .map((n) => n.copyWithRead())
              .toList();
        });
      }
    } catch (e) {
      debugPrint('[NotificationScreen] load error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ── HANDLE TAP ────────────────────────────────────────────────────────────
  Future<void> _onTap(NotificationModel n) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;
      final token = await user.getIdToken();
      if (token == null) return;

      // Mark this one as read on the server (no-op if already read)
      if (!n.isRead) {
        _controller.markOneAsRead(token: token, notificationId: n.id);
      }

      if (!mounted) return;

      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PostDetailScreen(
            postId:       n.postId,
            openComments: n.type == "comment",
          ),
        ),
      );
    } catch (e) {
      debugPrint('[NotificationScreen] tap error: $e');
    }
  }

  // ── BUILD ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor:        Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFFF7F8FC),
        appBar: AppBar(
          backgroundColor: const Color(0xFFF7F8FC),
          elevation:    0,
          centerTitle:  true,
          leading: IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(
              Icons.arrow_back_ios_new,
              color: Color(0xFF1B1D28),
              size: 20,
            ),
          ),
          title: const Text(
            "Notifications",
            style: TextStyle(
              color:      Color(0xFF1B1D28),
              fontWeight: FontWeight.w700,
              fontSize:   17,
            ),
          ),
        ),
        body: RefreshIndicator(
          color:     const Color(0xFF6C4DFF),
          onRefresh: _loadAndMarkRead,
          child: _isLoading
              ? const Center(
                  child: CircularProgressIndicator(color: Color(0xFF6C4DFF)),
                )
              : _notifications.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical:   16,
                      ),
                      itemCount: _notifications.length,
                      itemBuilder: (context, index) {
                        final n = _notifications[index];
                        return NotificationTile(
                          notification: n,
                          onTap: () => _onTap(n),
                        );
                      },
                    ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(
          height: MediaQuery.of(context).size.height * 0.25,
        ),
        Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                height: 88,
                width:  88,
                decoration: BoxDecoration(
                  color:        const Color(0xFFEDE9FF),
                  borderRadius: BorderRadius.circular(28),
                ),
                child: const Icon(
                  Icons.notifications_none,
                  size:  40,
                  color: Color(0xFF6C4DFF),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                "No Notifications Yet",
                style: TextStyle(
                  color:      Color(0xFF1B1D28),
                  fontSize:   18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                "When someone likes or comments\non your posts, it will show up here.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color:    Color(0xFF70758A),
                  fontSize: 14,
                  height:   1.6,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
