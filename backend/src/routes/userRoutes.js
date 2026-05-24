const express =
    require("express");

const router =
    express.Router();

const {

    completeProfile,

    getCurrentUser,

    getProfile,

    updateProfile,

    saveFcmToken,

} = require(

    "../controllers/userController"
);

const {

    protect,

} = require(

    "../middleware/authMiddleware"
);

const upload =
    require(

        "../middleware/uploadMiddleware"
    );

// GET CURRENT USER
router.get(

    "/me",

    protect,

    getCurrentUser
);

// GET PROFILE (with posts + stats)
router.get(

    "/profile",

    protect,

    getProfile
);

// COMPLETE PROFILE (onboarding)
router.post(

    "/complete-profile",

    protect,

    completeProfile
);

// UPDATE PROFILE (with optional photo)
router.put(

    "/update-profile",

    protect,

    upload.single("photo"),

    updateProfile
);

// SAVE FCM TOKEN
router.post(

    "/fcm-token",

    protect,

    saveFcmToken
);

module.exports =
    router;