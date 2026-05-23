import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';

import 'profile_controller.dart';

// ─── DESIGN TOKENS ─────────────────────────────────────────────────────────────
const Color _bg = Color(0xFFF7F8FC);
const Color _primary = Color(0xFF6C4DFF);
const Color _secondary = Color(0xFF8D7BFF);
const Color _textDark = Color(0xFF1B1D28);
const Color _textLight = Color(0xFF70758A);
const Color _card = Colors.white;

class EditProfileScreen extends StatefulWidget {
  final Map<String, dynamic> user;

  const EditProfileScreen({
    super.key,
    required this.user,
  });

  @override
  State<EditProfileScreen> createState() =>
      _EditProfileScreenState();
}

class _EditProfileScreenState
    extends State<EditProfileScreen> {
  final ProfileController _controller =
      ProfileController();

  final TextEditingController _usernameCtrl =
      TextEditingController();

  final TextEditingController _bioCtrl =
      TextEditingController();

  final TextEditingController _phoneCtrl =
      TextEditingController();

  final _formKey = GlobalKey<FormState>();

  bool isLoading = false;

  File? pickedImage;

  String currentAddress = "";

  double latitude = 0;

  double longitude = 0;

  bool locationFetching = false;

  final List<String> _allInterests = [
    "Tech",
    "Gaming",
    "Travel",
    "Food",
    "Photography",
    "Music",
    "Movies",
    "Fitness",
    "Coding",
    "Art",
    "Cricket",
    "Startups",
    "Fashion",
    "Books",
    "Finance",
    "Nature",
    "Pets",
    "Comedy",
  ];

  List<String> _selectedInterests = [];

  @override
  void initState() {
    super.initState();
    _prefillData();
  }

  void _prefillData() {
    _usernameCtrl.text =
        widget.user["username"] ?? "";
    _bioCtrl.text =
        widget.user["bio"] ?? "";
    _phoneCtrl.text =
        widget.user["phone"] ?? "";

    final rawInterests =
        widget.user["interests"] as List?;
    if (rawInterests != null) {
      _selectedInterests = rawInterests
          .map((e) => e.toString())
          .toList();
    }

    final loc =
        widget.user["location"]
            as Map<String, dynamic>?;
    if (loc != null) {
      currentAddress =
          loc["address"] ?? "";
      latitude =
          (loc["latitude"] as num?)
                  ?.toDouble() ??
              0;
      longitude =
          (loc["longitude"] as num?)
                  ?.toDouble() ??
              0;
    }
  }

  @override
  void dispose() {
    _usernameCtrl.dispose();
    _bioCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();

    final XFile? picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );

    if (picked != null) {
      setState(() {
        pickedImage = File(picked.path);
      });
    }
  }

  Future<void> _pickImageFromCamera() async {
    final ImagePicker picker = ImagePicker();

    final XFile? picked = await picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 85,
    );

    if (picked != null) {
      setState(() {
        pickedImage = File(picked.path);
      });
    }
  }

  void _showImageSourceSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: _card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(24),
        ),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            vertical: 24,
            horizontal: 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                height: 4,
                width: 40,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                "Choose Profile Photo",
                style: TextStyle(
                  color: _textDark,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: _imageSourceOption(
                      icon: Icons.photo_library_outlined,
                      label: "Gallery",
                      onTap: () {
                        Navigator.pop(context);
                        _pickImage();
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _imageSourceOption(
                      icon: Icons.camera_alt_outlined,
                      label: "Camera",
                      onTap: () {
                        Navigator.pop(context);
                        _pickImageFromCamera();
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _imageSourceOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          vertical: 20,
        ),
        decoration: BoxDecoration(
          color: _primary.withOpacity(0.06),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: _primary.withOpacity(0.15),
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: _primary,
              size: 28,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                color: _primary,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _fetchLocation() async {
    setState(() {
      locationFetching = true;
    });

    try {
      bool serviceEnabled =
          await Geolocator.isLocationServiceEnabled();

      if (!serviceEnabled) {
        _showSnack(
          "Please enable location services",
        );
        setState(() {
          locationFetching = false;
        });
        return;
      }

      LocationPermission permission =
          await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission =
            await Geolocator.requestPermission();
      }

      if (permission ==
          LocationPermission.deniedForever) {
        _showSnack(
          "Location permission permanently denied",
        );
        setState(() {
          locationFetching = false;
        });
        return;
      }

      final Position position =
          await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      latitude = position.latitude;
      longitude = position.longitude;

      final List<Placemark> placemarks =
          await placemarkFromCoordinates(
        latitude,
        longitude,
      );

      final Placemark place = placemarks[0];

      setState(() {
        currentAddress =
            "${place.locality}, ${place.country}";
        locationFetching = false;
      });
    } catch (e) {
      _showSnack("Failed to get location");
      setState(() {
        locationFetching = false;
      });
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      final response = await _controller.updateProfile(
        username: _usernameCtrl.text.trim(),
        bio: _bioCtrl.text.trim(),
        phone: _phoneCtrl.text.trim(),
        interests: _selectedInterests,
        location: {
          "address": currentAddress,
          "latitude": latitude,
          "longitude": longitude,
          "googleMapsLink":
              "https://maps.google.com/?q=$latitude,$longitude",
        },
        profileImageFile: pickedImage,
      );

      if (response["success"] == true) {
        _showSnack("Profile updated successfully ✅");
        if (mounted) {
          Navigator.pop(context, true);
        }
      } else {
        _showSnack(
          response["message"] ?? "Update failed",
        );
      }
    } catch (e) {
      _showSnack(e.toString());
    }

    setState(() {
      isLoading = false;
    });
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: _primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final firebaseUser =
        FirebaseAuth.instance.currentUser;

    final String existingPhoto =
        widget.user["photo"] ?? "";

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: _bg,
        body: SafeArea(
          child: Form(
            key: _formKey,
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                // ─── APP BAR ──────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding:
                        const EdgeInsets.fromLTRB(
                      18,
                      16,
                      18,
                      0,
                    ),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: () =>
                              Navigator.pop(context),
                          child: Container(
                            height: 44,
                            width: 44,
                            decoration: BoxDecoration(
                              color: _card,
                              borderRadius:
                                  BorderRadius.circular(
                                      14),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black
                                      .withOpacity(0.05),
                                  blurRadius: 10,
                                  offset:
                                      const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.arrow_back_ios_new,
                              color: _textDark,
                              size: 18,
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        const Text(
                          "Edit Profile",
                          style: TextStyle(
                            color: _textDark,
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // ─── AVATAR PICKER ────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.only(
                      top: 28,
                      bottom: 8,
                    ),
                    child: Center(
                      child: GestureDetector(
                        onTap: _showImageSourceSheet,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: _primary
                                        .withOpacity(
                                            0.25),
                                    blurRadius: 20,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                              child: CircleAvatar(
                                radius: 56,
                                backgroundColor: _primary,
                                backgroundImage: pickedImage !=
                                        null
                                    ? FileImage(
                                        pickedImage!)
                                    : existingPhoto
                                            .isNotEmpty
                                        ? NetworkImage(
                                            existingPhoto)
                                        : null as ImageProvider?,
                                child: pickedImage ==
                                            null &&
                                        existingPhoto
                                            .isEmpty
                                    ? Text(
                                        (firebaseUser
                                                    ?.displayName
                                                    ?.isNotEmpty ==
                                                true)
                                            ? firebaseUser!
                                                .displayName![0]
                                                .toUpperCase()
                                            : "A",
                                        style:
                                            const TextStyle(
                                          color:
                                              Colors.white,
                                          fontSize: 34,
                                          fontWeight:
                                              FontWeight
                                                  .w700,
                                        ),
                                      )
                                    : null,
                              ),
                            ),
                            Positioned(
                              bottom: 4,
                              right: 4,
                              child: Container(
                                height: 34,
                                width: 34,
                                decoration: BoxDecoration(
                                  gradient:
                                      const LinearGradient(
                                    colors: [
                                      _primary,
                                      _secondary,
                                    ],
                                  ),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: _bg,
                                    width: 2.5,
                                  ),
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
                  ),
                ),

                SliverToBoxAdapter(
                  child: Center(
                    child: TextButton(
                      onPressed: _showImageSourceSheet,
                      child: const Text(
                        "Change Photo",
                        style: TextStyle(
                          color: _primary,
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ),
                ),

                // ─── FORM SECTION ─────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                    ),
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 8),

                        // USERNAME
                        _buildSectionLabel("Username"),
                        const SizedBox(height: 8),
                        _buildTextField(
                          controller: _usernameCtrl,
                          hint: "Enter your username",
                          icon: Icons.person_outline,
                          validator: (val) {
                            if (val == null ||
                                val.trim().isEmpty) {
                              return "Username is required";
                            }
                            if (val.trim().length < 3) {
                              return "At least 3 characters";
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: 20),

                        // BIO
                        _buildSectionLabel("Bio"),
                        const SizedBox(height: 8),
                        _buildTextField(
                          controller: _bioCtrl,
                          hint:
                              "Tell your community about yourself…",
                          icon:
                              Icons.edit_note_outlined,
                          maxLines: 4,
                          maxLength: 300,
                        ),

                        const SizedBox(height: 20),

                        // PHONE
                        _buildSectionLabel("Phone"),
                        const SizedBox(height: 8),
                        _buildTextField(
                          controller: _phoneCtrl,
                          hint: "Your phone number",
                          icon: Icons.phone_outlined,
                          keyboardType:
                              TextInputType.phone,
                        ),

                        const SizedBox(height: 28),

                        // LOCATION
                        _buildSectionLabel("Location"),
                        const SizedBox(height: 10),
                        GestureDetector(
                          onTap: _fetchLocation,
                          child: Container(
                            padding:
                                const EdgeInsets.all(
                                    16),
                            decoration: BoxDecoration(
                              color: _card,
                              borderRadius:
                                  BorderRadius.circular(
                                      18),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black
                                      .withOpacity(0.04),
                                  blurRadius: 14,
                                  offset:
                                      const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                Container(
                                  height: 46,
                                  width: 46,
                                  decoration:
                                      BoxDecoration(
                                    color: _primary
                                        .withOpacity(
                                            0.09),
                                    borderRadius:
                                        BorderRadius
                                            .circular(
                                                14),
                                  ),
                                  child:
                                      locationFetching
                                          ? const Padding(
                                              padding:
                                                  EdgeInsets
                                                      .all(
                                                          12),
                                              child:
                                                  CircularProgressIndicator(
                                                color:
                                                    _primary,
                                                strokeWidth:
                                                    2.5,
                                              ),
                                            )
                                          : const Icon(
                                              Icons
                                                  .location_on_outlined,
                                              color:
                                                  _primary,
                                              size: 22,
                                            ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment
                                            .start,
                                    children: [
                                      const Text(
                                        "Your Location",
                                        style: TextStyle(
                                          color: _textDark,
                                          fontSize: 14,
                                          fontWeight:
                                              FontWeight
                                                  .w600,
                                        ),
                                      ),
                                      const SizedBox(
                                          height: 3),
                                      Text(
                                        currentAddress
                                                .isEmpty
                                            ? "Tap to detect location"
                                            : currentAddress,
                                        style:
                                            const TextStyle(
                                          color:
                                              _textLight,
                                          fontSize: 13,
                                          height: 1.4,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const Icon(
                                  Icons
                                      .my_location_outlined,
                                  color: _textLight,
                                  size: 20,
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 28),

                        // INTERESTS
                        _buildSectionLabel("Interests"),
                        const SizedBox(height: 6),
                        Text(
                          "Select topics you care about",
                          style: TextStyle(
                            color:
                                _textLight.withOpacity(
                                    0.8),
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 14),
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: _allInterests
                              .map((interest) {
                            final bool isSelected =
                                _selectedInterests
                                    .contains(interest);

                            return GestureDetector(
                              onTap: () {
                                setState(() {
                                  if (isSelected) {
                                    _selectedInterests
                                        .remove(interest);
                                  } else {
                                    _selectedInterests
                                        .add(interest);
                                  }
                                });
                              },
                              child: AnimatedContainer(
                                duration: const Duration(
                                    milliseconds: 200),
                                padding:
                                    const EdgeInsets
                                        .symmetric(
                                  horizontal: 16,
                                  vertical: 9,
                                ),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? _primary
                                      : _card,
                                  borderRadius:
                                      BorderRadius
                                          .circular(30),
                                  border: Border.all(
                                    color: isSelected
                                        ? _primary
                                        : Colors.grey
                                            .shade200,
                                  ),
                                  boxShadow: isSelected
                                      ? [
                                          BoxShadow(
                                            color: _primary
                                                .withOpacity(
                                                    0.2),
                                            blurRadius:
                                                10,
                                            offset:
                                                const Offset(
                                                    0, 3),
                                          ),
                                        ]
                                      : [
                                          BoxShadow(
                                            color: Colors
                                                .black
                                                .withOpacity(
                                                    0.03),
                                            blurRadius: 6,
                                          ),
                                        ],
                                ),
                                child: Text(
                                  interest,
                                  style: TextStyle(
                                    color: isSelected
                                        ? Colors.white
                                        : _textDark,
                                    fontSize: 13,
                                    fontWeight:
                                        FontWeight.w500,
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),

                        const SizedBox(height: 36),

                        // SAVE BUTTON
                        GestureDetector(
                          onTap: isLoading
                              ? null
                              : _saveProfile,
                          child: Container(
                            height: 60,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              gradient:
                                  const LinearGradient(
                                colors: [
                                  _primary,
                                  _secondary,
                                ],
                              ),
                              borderRadius:
                                  BorderRadius.circular(
                                      18),
                              boxShadow: [
                                BoxShadow(
                                  color: _primary
                                      .withOpacity(0.3),
                                  blurRadius: 20,
                                  offset:
                                      const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: Center(
                              child: isLoading
                                  ? const SizedBox(
                                      height: 24,
                                      width: 24,
                                      child:
                                          CircularProgressIndicator(
                                        color:
                                            Colors.white,
                                        strokeWidth: 2.5,
                                      ),
                                    )
                                  : const Text(
                                      "Save Changes",
                                      style: TextStyle(
                                        color:
                                            Colors.white,
                                        fontSize: 17,
                                        fontWeight:
                                            FontWeight
                                                .w600,
                                        letterSpacing:
                                            0.3,
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
        ),
      ),
    );
  }

  Widget _buildSectionLabel(String label) {
    return Text(
      label,
      style: const TextStyle(
        color: _textDark,
        fontSize: 15,
        fontWeight: FontWeight.w700,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    int? maxLength,
    String? Function(String?)? validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        maxLength: maxLength,
        validator: validator,
        style: const TextStyle(
          color: _textDark,
          fontSize: 15,
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(
            color: _textLight.withOpacity(0.7),
            fontSize: 14,
          ),
          prefixIcon: Icon(
            icon,
            color: _primary.withOpacity(0.7),
            size: 22,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
          counterStyle: const TextStyle(
            color: _textLight,
            fontSize: 11,
          ),
        ),
      ),
    );
  }
}