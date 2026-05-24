import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'profile_controller.dart';
import '../feed/home_feed_screen.dart';

const Color _bg = Color(0xFF0F0F1A);
const Color _card = Color(0xFF1A1A2E);
const Color _primary = Color(0xFF6C4DFF);
const Color _secondary = Color(0xFF8E7CFF);
const Color _white = Colors.white;

class CompleteProfileScreen
    extends StatefulWidget {

  const CompleteProfileScreen({
    super.key,
  });

  @override
  State<CompleteProfileScreen> createState() =>
      _CompleteProfileScreenState();
}

class _CompleteProfileScreenState
    extends State<CompleteProfileScreen> {

  final ProfileController _controller =
      ProfileController();

  final TextEditingController _usernameCtrl =
      TextEditingController();

  final TextEditingController _phoneCtrl =
      TextEditingController();

  final TextEditingController _bioCtrl =
      TextEditingController();

  final List<String> _allInterests = [
    "Food",
    "Events",
    "Sports",
    "Music",
    "Tech",
    "Art",
    "Travel",
    "Fitness",
    "Education",
    "Shopping",
    "Nature",
    "Pets",
    "Books",
    "Movies",
    "Gaming",
  ];

  final List<String> _selectedInterests = [];

  bool _isSaving = false;

  int _currentStep = 0;

  @override
  void dispose() {
    _usernameCtrl.dispose();
    _phoneCtrl.dispose();
    _bioCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {

    if (_usernameCtrl.text.trim().isEmpty) {
      _showSnack("Please enter a username");
      return;
    }

    if (_selectedInterests.isEmpty) {
      _showSnack("Please select at least one interest");
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {

      final response =
          await _controller.completeProfile(
        username: _usernameCtrl.text.trim(),
        phone: _phoneCtrl.text.trim(),
        bio: _bioCtrl.text.trim(),
        interests: _selectedInterests,
        location: {"address": ""},
      );

      if (response["success"] == true) {

        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  const HomeFeedScreen(),
            ),
          );
        }

      } else {

        _showSnack(
          response["message"] ?? "Failed to save profile",
        );
      }

    } catch (e) {

      _showSnack("Something went wrong");

    } finally {

      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: _primary,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {

    return AnnotatedRegion<SystemUiOverlayStyle>(

      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),

      child: Scaffold(

        backgroundColor: _bg,

        body: Stack(

          children: [

            // TOP GLOW
            Positioned(
              top: -100,
              left: -60,
              child: Container(
                height: 240,
                width: 240,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _primary.withOpacity(0.2),
                ),
              ),
            ),

            SafeArea(

              child: SingleChildScrollView(

                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 20,
                ),

                child: Column(

                  crossAxisAlignment:
                      CrossAxisAlignment.start,

                  children: [

                    const SizedBox(height: 20),

                    // HEADER
                    const Text(

                      "Set Up Your Profile",

                      style: TextStyle(
                        color: _white,
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),

                    const SizedBox(height: 10),

                    const Text(

                      "Tell your locality about yourself. This takes just a minute.",

                      style: TextStyle(
                        color: Colors.white60,
                        fontSize: 15,
                        height: 1.6,
                      ),
                    ),

                    const SizedBox(height: 36),

                    // USERNAME
                    _sectionLabel("Username *"),

                    const SizedBox(height: 10),

                    _inputField(
                      controller: _usernameCtrl,
                      hint: "@yourname",
                      icon: Icons.alternate_email,
                    ),

                    const SizedBox(height: 22),

                    // PHONE
                    _sectionLabel("Phone Number"),

                    const SizedBox(height: 10),

                    _inputField(
                      controller: _phoneCtrl,
                      hint: "+91 98765 43210",
                      icon: Icons.phone_outlined,
                      keyboardType: TextInputType.phone,
                    ),

                    const SizedBox(height: 22),

                    // BIO
                    _sectionLabel("Bio"),

                    const SizedBox(height: 10),

                    _inputField(
                      controller: _bioCtrl,
                      hint: "Tell your neighbours something about you...",
                      icon: Icons.edit_outlined,
                      maxLines: 3,
                    ),

                    const SizedBox(height: 28),

                    // INTERESTS
                    _sectionLabel("Interests *"),

                    const SizedBox(height: 6),

                    const Text(
                      "Pick what matters to you in your locality",
                      style: TextStyle(
                        color: Colors.white38,
                        fontSize: 13,
                      ),
                    ),

                    const SizedBox(height: 14),

                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: _allInterests.map((interest) {

                        final selected =
                            _selectedInterests.contains(interest);

                        return GestureDetector(

                          onTap: () {
                            setState(() {
                              selected
                                  ? _selectedInterests
                                      .remove(interest)
                                  : _selectedInterests
                                      .add(interest);
                            });
                          },

                          child: AnimatedContainer(

                            duration:
                                const Duration(milliseconds: 200),

                            padding:
                                const EdgeInsets.symmetric(
                              horizontal: 18,
                              vertical: 10,
                            ),

                            decoration: BoxDecoration(

                              gradient: selected
                                  ? const LinearGradient(
                                      colors: [_primary, _secondary],
                                    )
                                  : null,

                              color: selected
                                  ? null
                                  : Colors.white
                                      .withOpacity(0.07),

                              borderRadius:
                                  BorderRadius.circular(20),

                              border: Border.all(
                                color: selected
                                    ? Colors.transparent
                                    : Colors.white
                                        .withOpacity(0.15),
                              ),
                            ),

                            child: Text(

                              interest,

                              style: TextStyle(
                                color: selected
                                    ? _white
                                    : Colors.white60,
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),

                    const SizedBox(height: 40),

                    // SUBMIT BUTTON
                    GestureDetector(

                      onTap: _isSaving ? null : _submit,

                      child: Container(

                        height: 60,

                        width: double.infinity,

                        decoration: BoxDecoration(

                          gradient: _isSaving
                              ? null
                              : const LinearGradient(
                                  colors: [_primary, _secondary],
                                ),

                          color: _isSaving
                              ? Colors.white12
                              : null,

                          borderRadius:
                              BorderRadius.circular(20),
                        ),

                        child: Center(

                          child: _isSaving

                              ? const SizedBox(

                                  height: 22,
                                  width: 22,

                                  child: CircularProgressIndicator(
                                    color: _white,
                                    strokeWidth: 2,
                                  ),
                                )

                              : const Text(

                                  "Continue to AddaLink →",

                                  style: TextStyle(
                                    color: _white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(String label) {

    return Text(

      label,

      style: const TextStyle(
        color: Colors.white70,
        fontSize: 14,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.3,
      ),
    );
  }

  Widget _inputField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
  }) {

    return Container(

      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 4,
      ),

      decoration: BoxDecoration(

        color: Colors.white.withOpacity(0.07),

        borderRadius: BorderRadius.circular(18),

        border: Border.all(
          color: Colors.white.withOpacity(0.1),
        ),
      ),

      child: Row(

        crossAxisAlignment: maxLines > 1
            ? CrossAxisAlignment.start
            : CrossAxisAlignment.center,

        children: [

          Padding(
            padding: EdgeInsets.only(
              top: maxLines > 1 ? 14 : 0,
            ),
            child: Icon(
              icon,
              color: Colors.white38,
              size: 20,
            ),
          ),

          const SizedBox(width: 12),

          Expanded(

            child: TextField(

              controller: controller,

              keyboardType: keyboardType,

              maxLines: maxLines,

              style: const TextStyle(
                color: _white,
                fontSize: 15,
              ),

              decoration: InputDecoration(

                hintText: hint,

                hintStyle: const TextStyle(
                  color: Colors.white30,
                  fontSize: 15,
                ),

                border: InputBorder.none,
              ),
            ),
          ),
        ],
      ),
    );
  }
}