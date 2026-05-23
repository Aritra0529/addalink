import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

import 'profile_controller.dart';
import '../feed/home_feed_screen.dart';

class CompleteProfileScreen extends StatefulWidget {


const CompleteProfileScreen({
  super.key,
});

  @override
  State<CompleteProfileScreen> createState() =>
      _CompleteProfileScreenState();
}

class _CompleteProfileScreenState
    extends State<CompleteProfileScreen> {

  final TextEditingController usernameController =
      TextEditingController();

  final TextEditingController phoneController =
      TextEditingController();

  final TextEditingController bioController =
      TextEditingController();

  final User? user =
      FirebaseAuth.instance.currentUser;

  final ProfileController controller =
      ProfileController();

  bool isLoading = false;

  String currentAddress = "";

  double latitude = 0;

  double longitude = 0;

  final List<String> interests = [

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
  ];

  final List<String> selectedInterests =
      [];

  // LOCATION FUNCTION
  Future<void> getLocation() async {

    bool serviceEnabled;

    LocationPermission permission;

    serviceEnabled =
        await Geolocator
            .isLocationServiceEnabled();

    if (!serviceEnabled) {

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(

        const SnackBar(
          content: Text(
            "Please enable location services",
          ),
        ),
      );

      return;
    }

    permission =
        await Geolocator
            .checkPermission();

    if (permission ==
        LocationPermission.denied) {

      permission =
          await Geolocator
              .requestPermission();
    }

    if (permission ==
        LocationPermission.deniedForever) {

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(

        const SnackBar(
          content: Text(
            "Location permission permanently denied",
          ),
        ),
      );

      return;
    }

    Position position =
        await Geolocator
            .getCurrentPosition(
      desiredAccuracy:
          LocationAccuracy.high,
    );

    latitude = position.latitude;

    longitude = position.longitude;

    List<Placemark> placemarks =
        await placemarkFromCoordinates(
      latitude,
      longitude,
    );

    Placemark place = placemarks[0];

    currentAddress =
        "${place.locality}, ${place.country}";

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor:
          const Color(0xFF0F0F1A),

      body: SafeArea(
        child: SingleChildScrollView(

          padding:
              const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 20,
          ),

          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,

            children: [

              const SizedBox(height: 10),

              // TITLE
              const Text(
                "Complete Your Profile 👋",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight:
                      FontWeight.bold,
                ),
              ),

              const SizedBox(height: 12),

              // SUBTITLE
              const Text(
                "Help AddaLink personalize your nearby community experience.",
                style: TextStyle(
                  color: Colors.white60,
                  fontSize: 16,
                  height: 1.5,
                ),
              ),

              const SizedBox(height: 35),

              // PROFILE IMAGE
              Center(
                child: CircleAvatar(
                  radius: 55,

                  backgroundColor:
                      const Color(
                    0xFF6C4DFF,
                  ),

                  backgroundImage:
                      user?.photoURL !=
                              null
                          ? NetworkImage(
                              user!
                                  .photoURL!,
                            )
                          : null,
                ),
              ),

              const SizedBox(height: 18),

              // USER NAME
              Center(
                child: Text(
                  user?.displayName ??
                      "AddaLink User",

                  style:
                      const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight:
                        FontWeight.w600,
                  ),
                ),
              ),

              const SizedBox(height: 8),

              // EMAIL
              Center(
                child: Text(
                  user?.email ?? "",

                  style:
                      const TextStyle(
                    color: Colors.white54,
                    fontSize: 14,
                  ),
                ),
              ),

              const SizedBox(height: 40),

              // USERNAME
              buildTextField(
                controller:
                    usernameController,

                hint:
                    "Choose a username",

                icon:
                    Icons.person_outline,
              ),

              const SizedBox(height: 20),

              // PHONE
              buildTextField(
                controller:
                    phoneController,

                hint:
                    "Phone number",

                icon:
                    Icons.phone_outlined,

                keyboardType:
                    TextInputType.phone,
              ),

              const SizedBox(height: 20),

              // BIO
              buildTextField(
                controller:
                    bioController,

                hint:
                    "Tell people about yourself...",

                icon:
                    Icons.edit_note_outlined,

                maxLines: 4,
              ),

              const SizedBox(height: 35),

              // INTEREST TITLE
              const Text(
                "Your Interests ✨",

                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight:
                      FontWeight.bold,
                ),
              ),

              const SizedBox(height: 10),

              const Text(
                "Select interests to personalize your feed and nearby recommendations.",

                style: TextStyle(
                  color: Colors.white54,
                  fontSize: 14,
                  height: 1.5,
                ),
              ),

              const SizedBox(height: 22),

              // INTEREST CHIPS
              Wrap(
                spacing: 12,
                runSpacing: 12,

                children:
                    interests.map((
                  interest,
                ) {

                  final bool isSelected =
                      selectedInterests
                          .contains(
                    interest,
                  );

                  return GestureDetector(

                    onTap: () {

                      setState(() {

                        if (isSelected) {

                          selectedInterests
                              .remove(
                            interest,
                          );

                        } else {

                          selectedInterests
                              .add(
                            interest,
                          );
                        }
                      });
                    },

                    child:
                        AnimatedContainer(

                      duration:
                          const Duration(
                        milliseconds:
                            250,
                      ),

                      padding:
                          const EdgeInsets
                              .symmetric(
                        horizontal: 18,
                        vertical: 14,
                      ),

                      decoration:
                          BoxDecoration(

                        gradient:
                            isSelected
                                ? const LinearGradient(
                                    colors: [

                                      Color(
                                        0xFF6C4DFF,
                                      ),

                                      Color(
                                        0xFF8E7CFF,
                                      ),
                                    ],
                                  )
                                : null,

                        color:
                            isSelected
                                ? null
                                : Colors
                                    .white
                                    .withOpacity(
                                    0.05,
                                  ),

                        borderRadius:
                            BorderRadius
                                .circular(
                          18,
                        ),

                        border:
                            Border.all(
                          color:
                              isSelected
                                  ? Colors
                                      .transparent
                                  : Colors
                                      .white
                                      .withOpacity(
                                      0.08,
                                    ),
                        ),
                      ),

                      child: Text(
                        interest,

                        style:
                            TextStyle(
                          color:
                              isSelected
                                  ? Colors
                                      .white
                                  : Colors
                                      .white70,

                          fontSize: 14,

                          fontWeight:
                              FontWeight
                                  .w600,
                        ),
                      ),
                    ),
                  );

                }).toList(),
              ),

              const SizedBox(height: 35),

              // LOCATION CARD
              GestureDetector(

                onTap: () async {

                  await getLocation();
                },

                child: Container(

                  padding:
                      const EdgeInsets
                          .all(18),

                  decoration:
                      BoxDecoration(

                    color: Colors.white
                        .withOpacity(
                      0.05,
                    ),

                    borderRadius:
                        BorderRadius
                            .circular(
                      22,
                    ),

                    border:
                        Border.all(
                      color: Colors
                          .white
                          .withOpacity(
                        0.08,
                      ),
                    ),
                  ),

                  child: Row(
                    children: [

                      Container(
                        padding:
                            const EdgeInsets
                                .all(12),

                        decoration:
                            BoxDecoration(

                          color:
                              const Color(
                            0xFF6C4DFF,
                          ).withOpacity(
                            0.18,
                          ),

                          borderRadius:
                              BorderRadius
                                  .circular(
                            14,
                          ),
                        ),

                        child:
                            const Icon(
                          Icons
                              .location_on_outlined,

                          color: Color(
                            0xFF8E7CFF,
                          ),
                        ),
                      ),

                      const SizedBox(
                        width: 16,
                      ),

                      Expanded(
                        child: Column(

                          crossAxisAlignment:
                              CrossAxisAlignment
                                  .start,

                          children: [

                            const Text(
                              "Your Location",

                              style:
                                  TextStyle(
                                color: Colors
                                    .white,

                                fontSize: 16,

                                fontWeight:
                                    FontWeight
                                        .w600,
                              ),
                            ),

                            const SizedBox(
                              height: 4,
                            ),

                            Text(

                              currentAddress
                                      .isEmpty
                                  ? "Tap to fetch your location"
                                  : currentAddress,

                              style:
                                  const TextStyle(
                                color: Colors
                                    .white54,

                                fontSize: 13,

                                height: 1.5,
                              ),
                            ),

                          ],
                        ),
                      ),

                    ],
                  ),
                ),
              ),

              const SizedBox(height: 45),

              // CONTINUE BUTTON
              GestureDetector(

                onTap: () async {

                  if (usernameController
                      .text
                      .trim()
                      .isEmpty) {

                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(

                      const SnackBar(
                        content: Text(
                          "Username is required",
                        ),
                      ),
                    );

                    return;
                  }

                  setState(() {
                    isLoading = true;
                  });

                  try {

                    await getLocation();

                final response =
    await controller
        .completeProfile(

  username:
      usernameController
          .text
          .trim(),

  phone:
      phoneController
          .text
          .trim(),

  bio:
      bioController
          .text
          .trim(),

  interests:
      selectedInterests,

  location: {

    "address":
        currentAddress,

    "latitude":
        latitude,

    "longitude":
        longitude,

    "googleMapsLink":
        "https://maps.google.com/?q=$latitude,$longitude",
  },
);

                    print(response);

                    if (response[
                            "success"] ==
                        true) {

                      ScaffoldMessenger
                          .of(context)
                          .showSnackBar(

                        const SnackBar(
                          content: Text(
                            "Profile Completed 🚀",
                          ),
                        ),
                      );

                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              const HomeFeedScreen(),
                        ),
                      );
                    }

                  } catch (e) {

                    print(e);

                    ScaffoldMessenger
                        .of(context)
                        .showSnackBar(

                      SnackBar(
                        content: Text(
                          e.toString(),
                        ),
                      ),
                    );
                  }

                  setState(() {
                    isLoading = false;
                  });
                },

                child: Container(

                  height: 62,

                  width: double.infinity,

                  decoration:
                      BoxDecoration(

                    borderRadius:
                        BorderRadius
                            .circular(
                      18,
                    ),

                    gradient:
                        const LinearGradient(
                      colors: [

                        Color(
                          0xFF6C4DFF,
                        ),

                        Color(
                          0xFF8E7CFF,
                        ),
                      ],
                    ),

                    boxShadow: [

                      BoxShadow(
                        color:
                            const Color(
                          0xFF6C4DFF,
                        ).withOpacity(
                          0.35,
                        ),

                        blurRadius: 25,

                        spreadRadius: 2,
                      ),
                    ],
                  ),

                  child: Center(

                    child: isLoading

                        ? const CircularProgressIndicator(
                            color:
                                Colors
                                    .white,
                          )

                        : const Text(
                            "Continue",

                            style:
                                TextStyle(
                              color:
                                  Colors
                                      .white,

                              fontSize:
                                  18,

                              fontWeight:
                                  FontWeight
                                      .w600,
                            ),
                          ),
                  ),
                ),
              ),

              const SizedBox(height: 30),

            ],
          ),
        ),
      ),
    );
  }

  Widget buildTextField({

    required TextEditingController
        controller,

    required String hint,

    required IconData icon,

    TextInputType keyboardType =
        TextInputType.text,

    int maxLines = 1,
  }) {

    return Container(

      decoration: BoxDecoration(

        color: Colors.white
            .withOpacity(0.05),

        borderRadius:
            BorderRadius.circular(
          20,
        ),

        border: Border.all(
          color: Colors.white
              .withOpacity(0.08),
        ),
      ),

      child: TextField(

        controller: controller,

        keyboardType: keyboardType,

        maxLines: maxLines,

        style: const TextStyle(
          color: Colors.white,
        ),

        decoration: InputDecoration(

          hintText: hint,

          hintStyle:
              const TextStyle(
            color: Colors.white38,
          ),

          prefixIcon: Icon(
            icon,
            color: Colors.white54,
          ),

          border: InputBorder.none,

          contentPadding:
              const EdgeInsets
                  .symmetric(
            horizontal: 20,
            vertical: 18,
          ),
        ),
      ),
    );
  }
}