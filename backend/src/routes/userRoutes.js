const express = require("express");

const router = express.Router();

const multer = require("multer");

const {
    completeProfile,
    getCurrentUser,
    getProfile,
    updateProfile,
} = require("../controllers/userController");

const { protect } = require("../middleware/authMiddleware");

// ─── MULTER CONFIG (memory storage for cloudinary) ──────────────────────────────
const storage = multer.memoryStorage();

const path =
    require("path");

const fileFilter = (
    req,
    file,
    cb,
) => {

    console.log(
        "PROFILE IMAGE:",
        file.originalname
    );

    console.log(
        "PROFILE MIME:",
        file.mimetype
    );

    const allowedExtensions = [

        ".jpg",
        ".jpeg",
        ".png",
        ".webp",
        ".gif",
    ];

    const ext =
        path.extname(
            file.originalname
        ).toLowerCase();

    if (
        allowedExtensions.includes(
            ext
        )
    ) {

        cb(null, true);

    } else {

        cb(
            new Error(
                "Only image files are allowed"
            ),
            false
        );
    }
};

const upload = multer({
    storage: storage,
    fileFilter: fileFilter,
    limits: {
        fileSize: 5 * 1024 * 1024, // 5 MB limit
    },
});

// ─── ROUTES ─────────────────────────────────────────────────────────────────────

// COMPLETE PROFILE (existing — preserved)
router.post(
    "/complete-profile",
    protect,
    completeProfile
);

// GET CURRENT USER (existing — preserved)
router.get(
    "/me",
    protect,
    getCurrentUser
);

// GET PROFILE WITH POSTS & STATS
router.get(
    "/profile",
    protect,
    getProfile
);

// UPDATE PROFILE (with optional image upload)
router.put(
    "/update-profile",
    protect,
    upload.single("profileImage"),
    updateProfile
);

module.exports = router;