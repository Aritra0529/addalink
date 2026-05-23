import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'notification_controller.dart';
import 'notification_model.dart';
import 'notification_tile.dart';

class NotificationScreen
    extends StatefulWidget {

  const NotificationScreen({
    super.key,
  });

  @override
  State<NotificationScreen> createState() =>
      _NotificationScreenState();
}

class _NotificationScreenState
    extends State<NotificationScreen> {

  final NotificationController _controller =
      NotificationController();

  List<NotificationModel> notifications = [];

  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAndMarkRead();
  }

  Future<void> _loadAndMarkRead() async {

    setState(() {
      isLoading = true;
    });

    try {

      final user =
          FirebaseAuth.instance.currentUser;

      if (user == null) return;

      final token = await user.getIdToken();

      // FETCH NOTIFICATIONS
      final fetched =
          await _controller.getNotifications(
        token: token!,
      );

      // AUTO MARK AS READ
      await _controller.markAsRead(
        token: token,
      );

      if (mounted) {
        setState(() {
          notifications = fetched;
        });
      }

    } catch (e) {
      print("Notification load error: $e");
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {

    return AnnotatedRegion<SystemUiOverlayStyle>(

      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),

      child: Scaffold(

        backgroundColor:
            const Color(0xFFF7F8FC),

        appBar: AppBar(

          backgroundColor:
              const Color(0xFFF7F8FC),

          elevation: 0,

          centerTitle: true,

          leading: IconButton(

            onPressed: () {
              Navigator.pop(context);
            },

            icon: const Icon(
              Icons.arrow_back_ios_new,
              color: Color(0xFF1B1D28),
              size: 20,
            ),
          ),

          title: const Text(

            "Notifications",

            style: TextStyle(
              color: Color(0xFF1B1D28),
              fontWeight: FontWeight.w700,
              fontSize: 17,
            ),
          ),
        ),

        body: RefreshIndicator(

          color: const Color(0xFF6C4DFF),

          onRefresh: _loadAndMarkRead,

          child: isLoading

              ? const Center(
                  child: CircularProgressIndicator(
                    color: Color(0xFF6C4DFF),
                  ),
                )

              : notifications.isEmpty

                  ? _buildEmptyState()

                  : ListView.builder(

                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 16,
                      ),

                      itemCount: notifications.length,

                      itemBuilder: (context, index) {

                        return NotificationTile(
                          notification:
                              notifications[index],
                        );
                      },
                    ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {

    return ListView(

      physics:
          const AlwaysScrollableScrollPhysics(),

      children: [

        SizedBox(
          height:
              MediaQuery.of(context).size.height *
              0.25,
        ),

        Center(

          child: Column(

            mainAxisAlignment:
                MainAxisAlignment.center,

            children: [

              Container(

                height: 88,

                width: 88,

                decoration: BoxDecoration(

                  color: const Color(0xFFEDE9FF),

                  borderRadius:
                      BorderRadius.circular(28),
                ),

                child: const Icon(

                  Icons.notifications_none,

                  size: 40,

                  color: Color(0xFF6C4DFF),
                ),
              ),

              const SizedBox(height: 20),

              const Text(

                "No Notifications Yet",

                style: TextStyle(

                  color: Color(0xFF1B1D28),

                  fontSize: 18,

                  fontWeight: FontWeight.w700,
                ),
              ),

              const SizedBox(height: 10),

              const Text(

                "When someone likes or comments\non your posts, it will show up here.",

                textAlign: TextAlign.center,

                style: TextStyle(

                  color: Color(0xFF70758A),

                  fontSize: 14,

                  height: 1.6,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}