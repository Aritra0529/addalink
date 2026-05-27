import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import 'profile_controller.dart';

const Color _bg = Color(0xFFF7F8FC);
const Color _primary = Color(0xFF6C4DFF);
const Color _secondary = Color(0xFF8D7BFF);
const Color _dark = Color(0xFF1B1D28);
const Color _light = Color(0xFF70758A);
const Color _card = Colors.white;
const Color _border = Color(0xFFE8EAF2);

class EditProfileScreen extends StatefulWidget {

  final Map<String, dynamic> userData;

  const EditProfileScreen({

    super.key,

    required this.userData,
  });

  @override
  State<EditProfileScreen> createState() =>
      _EditProfileScreenState();
}

class _EditProfileScreenState
    extends State<EditProfileScreen> {

  final ProfileController _controller =
      ProfileController();

  final ImagePicker _picker = ImagePicker();

  late final TextEditingController _usernameCtrl;
  late final TextEditingController _bioCtrl;
  late final TextEditingController _phoneCtrl;

  File? _newPhoto;

  List<String> _selectedInterests = [];

  Map<String, dynamic> _location = {};

  bool _isSaving = false;

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

  @override
  void initState() {

    super.initState();

    _usernameCtrl = TextEditingController(
      text: widget.userData["username"] ?? "",
    );

    _bioCtrl = TextEditingController(
      text: widget.userData["bio"] ?? "",
    );

    _phoneCtrl = TextEditingController(
      text: widget.userData["phone"] ?? "",
    );

    _selectedInterests = List<String>.from(
      widget.userData["interests"] ?? [],
    );

    final loc = widget.userData["location"];
    if (loc is Map) {
      _location = Map<String, dynamic>.from(loc);
    }
  }

  @override
  void dispose() {
    _usernameCtrl.dispose();
    _bioCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {

    final XFile? picked = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );

    if (picked != null) {
      setState(() {
        _newPhoto = File(picked.path);
      });
    }
  }

  Future<void> _save() async {

    if (_usernameCtrl.text.trim().isEmpty) {
      _showSnack("Username cannot be empty");
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {

      final response =
          await _controller.updateProfile(
        username: _usernameCtrl.text.trim(),
        bio: _bioCtrl.text.trim(),
        phone: _phoneCtrl.text.trim(),
        interests: _selectedInterests,
        location: _location,
        photo: _newPhoto,
      );

      if (response["success"] == true) {

        _showSnack("Profile updated ✓");

        if (mounted) {
          Navigator.pop(context, response["user"]);
        }

      } else {

        _showSnack(
          response["message"] ?? "Update failed",
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

    final existingPhoto =
        widget.userData["photo"] ?? "";

    return AnnotatedRegion<SystemUiOverlayStyle>(

      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),

      child: Scaffold(

        backgroundColor: _bg,

        appBar: AppBar(

          backgroundColor: _bg,

          elevation: 0,

          centerTitle: true,

          leading: IconButton(

            onPressed: () => Navigator.pop(context),

            icon: const Icon(
              Icons.arrow_back_ios_new,
              color: _dark,
              size: 20,
            ),
          ),

          title: const Text(

            "Edit Profile",

            style: TextStyle(
              color: _dark,
              fontWeight: FontWeight.w700,
              fontSize: 17,
            ),
          ),

          actions: [

            Padding(

              padding: const EdgeInsets.only(right: 14),

              child: GestureDetector(

                onTap: _isSaving ? null : _save,

                child: AnimatedContainer(

                  duration:
                      const Duration(milliseconds: 200),

                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 10,
                  ),

                  decoration: BoxDecoration(

                    gradient: _isSaving
                        ? null
                        : const LinearGradient(
                            colors: [_primary, _secondary],
                          ),

                    color: _isSaving
                        ? Colors.grey.shade300
                        : null,

                    borderRadius:
                        BorderRadius.circular(16),
                  ),

                  child: _isSaving

                      ? const SizedBox(
                          height: 16,
                          width: 16,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )

                      : const Text(

                          "Save",

                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),

        body: SingleChildScrollView(

          padding: const EdgeInsets.all(18),

          child: Column(

            crossAxisAlignment:
                CrossAxisAlignment.start,

            children: [

              // AVATAR PICKER
              Center(

                child: GestureDetector(

                  onTap: _pickPhoto,

                  child: Stack(

                    children: [

                      CircleAvatar(

                        radius: 52,

                        backgroundColor: _primary,

                        backgroundImage: _newPhoto != null
                            ? FileImage(_newPhoto!)
                            : existingPhoto.isNotEmpty
                                ? NetworkImage(existingPhoto)
                                    as ImageProvider
                                : null,

                        child: (_newPhoto == null &&
                                existingPhoto.isEmpty)
                            ? const Icon(
                                Icons.person,
                                color: Colors.white,
                                size: 46,
                              )
                            : null,
                      ),

                      Positioned(

                        bottom: 2,

                        right: 2,

                        child: Container(

                          padding:
                              const EdgeInsets.all(7),

                          decoration: const BoxDecoration(

                            color: _primary,

                            shape: BoxShape.circle,
                          ),

                          child: const Icon(
                            Icons.camera_alt,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 28),

              // USERNAME
              _label("Username"),
              const SizedBox(height: 8),
              _field(
                controller: _usernameCtrl,
                hint: "yourname",
                icon: Icons.alternate_email,
              ),

              const SizedBox(height: 20),

              // BIO
              _label("Bio"),
              const SizedBox(height: 8),
              _field(
                controller: _bioCtrl,
                hint: "Something about you...",
                icon: Icons.edit_outlined,
                maxLines: 3,
              ),

              const SizedBox(height: 20),

              // PHONE
              _label("Phone"),
              const SizedBox(height: 8),
              _field(
                controller: _phoneCtrl,
                hint: "+91 98765 43210",
                icon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
              ),

              const SizedBox(height: 26),

              // INTERESTS
              _label("Interests"),
              const SizedBox(height: 12),

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
                            ? _selectedInterests.remove(interest)
                            : _selectedInterests.add(interest);
                      });
                    },

                    child: AnimatedContainer(

                      duration:
                          const Duration(milliseconds: 180),

                      padding:
                          const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 9,
                      ),

                      decoration: BoxDecoration(

                        gradient: selected
                            ? const LinearGradient(
                                colors: [_primary, _secondary],
                              )
                            : null,

                        color:
                            selected ? null : _card,

                        borderRadius:
                            BorderRadius.circular(18),

                        border: Border.all(
                          color: selected
                              ? Colors.transparent
                              : _border,
                        ),
                      ),

                      child: Text(

                        interest,

                        style: TextStyle(
                          color: selected
                              ? Colors.white
                              : _light,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _label(String text) {

    return Text(

      text,

      style: const TextStyle(
        color: _dark,
        fontSize: 14,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _field({
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

        color: _card,

        borderRadius: BorderRadius.circular(18),

        border: Border.all(color: _border),

        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
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
            child: Icon(icon, color: _light, size: 20),
          ),

          const SizedBox(width: 12),

          Expanded(

            child: TextField(

              controller: controller,

              keyboardType: keyboardType,

              maxLines: maxLines,

              style: const TextStyle(
                color: _dark,
                fontSize: 15,
              ),

              decoration: InputDecoration(

                hintText: hint,

                hintStyle: const TextStyle(
                  color: _light,
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