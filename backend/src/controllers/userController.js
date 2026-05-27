const cloudinary = require("cloudinary").v2;
const streamifier = require("streamifier");

const User = require("../models/User");
const Post = require("../models/Post");
const Notification = require("../models/Notification");

const generateToken = require("../utils/generateToken");

// ─── HELPER: upload buffer to cloudinary ────────────────────────────────────────
const uploadToCloudinary = (buffer) => {
    return new Promise((resolve, reject) => {
        const uploadStream = cloudinary.uploader.upload_stream(
            {
                folder: "addalink/profiles",
                transformation: [
                    { width: 400, height: 400, crop: "fill", gravity: "face" },
                    { quality: "auto:good" },
                ],
            },
            (error, result) => {
                if (error) return reject(error);
                resolve(result);
            }
        );
        streamifier.createReadStream(buffer).pipe(uploadStream);
    });
};

// ─── COMPLETE PROFILE ───────────────────────────────────────────────────────────
const completeProfile = async (req, res) => {
    try {
        const {
            username,
            phone,
            bio,
            interests,
            location,
        } = req.body;

        const currentUser = req.user;

        currentUser.username = username;
        currentUser.phone = phone;
        currentUser.bio = bio;
        currentUser.interests = interests;
        currentUser.location = location;
        currentUser.isProfileComplete = true;

        await currentUser.save();

        const token = generateToken(currentUser._id);

        return res.status(200).json({
            success: true,
            message: "Profile completed successfully",
            token,
            user: currentUser,
        });
    } catch (error) {
        console.log("Complete Profile Error:", error.message);
        return res.status(500).json({
            success: false,
            message: "Server Error",
        });
    }
};

// ─── GET CURRENT USER ───────────────────────────────────────────────────────────
const getCurrentUser = async (req, res) => {
    try {
        return res.status(200).json({
            success: true,
            user: req.user,
        });
    } catch (error) {
        console.log("Get User Error:", error.message);
        return res.status(500).json({
            success: false,
            message: "Server Error",
        });
    }
};

// ─── GET PROFILE ────────────────────────────────────────────────────────────────
const getProfile = async (req, res) => {
    try {
        const currentUser = req.user;

        // FETCH USER POSTS
        const posts = await Post.find({
            user: currentUser._id,
            isDeleted: false,
        })
            .sort({ createdAt: -1 })
            .lean();

        // COMPUTE AGGREGATE STATS
       let totalLikes = 0;

let totalComments = 0;

for (const post of posts) {

    totalLikes +=
        (post.likes || []).length;

    totalComments +=
        (post.comments || []).length;
}

        return res.status(200).json({
            success: true,
            user: currentUser,
            posts: posts.map(
    (post) => ({

        _id:
            post._id,

        username:
            post.username,

        userProfileImage:
            post.userProfileImage,

        content:
            post.content,

        images:
            post.images || [],

        video:
            post.video || "",

        postType:
            post.postType,

        createdAt:
            post.createdAt,

        isEdited:
            post.isEdited || false,

        likesCount:
            (post.likes || [])
                .length,

        comments:
            post.comments || [],

        isLiked:
            (post.likes || [])
                .some(

                    (id) =>

                        id.toString() ===
                        currentUser._id.toString()
                ),
    })
),
            totalLikes: totalLikes,
            totalComments: totalComments,
            postsCount: posts.length,
        });
    } catch (error) {
        console.log(error);
        return res.status(500).json({
            success: false,
            message: "Server Error",
        });
    }
};

// ─── UPDATE PROFILE ─────────────────────────────────────────────────────────────
const updateProfile = async (req, res) => {
    try {
        const currentUser = req.user;
        if (!currentUser) {

    return res.status(401).json({

        success: false,

        message:
            "Unauthorized",
    });
}

        const {
            username,
            bio,
            phone,
        } = req.body;

        // PARSE INTERESTS (sent as JSON string from multipart)
        let interests = [];
        if (req.body.interests) {
            try {
                interests = JSON.parse(req.body.interests);
            } catch (_) {
                interests = [];
            }
        }

        // PARSE LOCATION (sent as JSON string from multipart)
        let location = currentUser.location;
        if (req.body.location) {
            try {
                location = JSON.parse(req.body.location);
            } catch (_) {
                location = currentUser.location;
            }
        }

        // VALIDATE USERNAME UNIQUENESS (if changed)
        if (
            username &&
            username.trim() !== "" &&
            username.trim() !== currentUser.username
        ) {
            const exists = await User.findOne({
                username: username.trim(),
                _id: { $ne: currentUser._id },
            });

            if (exists) {
                return res.status(409).json({
                    success: false,
                    message: "Username already taken",
                });
            }

            currentUser.username = username.trim();
        }

        if (bio !== undefined) {
            currentUser.bio = bio;
        }

        if (phone !== undefined) {
            currentUser.phone = phone;
        }

        if (interests && interests.length >= 0) {
            currentUser.interests = interests;
        }

        if (location) {
            currentUser.location = location;
        }

        // HANDLE PROFILE IMAGE UPLOAD
if (req.file && req.file.buffer) {
            const cloudinaryResult =
                await uploadToCloudinary(req.file.buffer);

            currentUser.photo = cloudinaryResult.secure_url;

            // sync post-level avatar
            await Post.updateMany(
                { user: currentUser._id },
                { $set: { userProfileImage: currentUser.photo } }
            );

           // sync avatar inside every comment this user made on any post
            await Post.updateMany(
                { "comments.user": currentUser._id },
                {
                    $set: {
                        "comments.$[c].userProfileImage": currentUser.photo,
                    },
                },
                {
                    arrayFilters: [{ "c.user": currentUser._id }],
                }
            );

            // sync avatar in all notifications this user sent
            await Notification.updateMany(
                { sender: currentUser._id },
                { $set: { senderPhoto: currentUser.photo } }
            );
        }
        

        await currentUser.save();

        return res.status(200).json({
            success: true,
            message: "Profile updated successfully",
            user: currentUser,
        });
    } catch (error) {
        console.log("Update Profile Error:", error.message);
        return res.status(500).json({
            success: false,
            message: "Server Error",
        });
    }
};

// ─── SAVE FCM TOKEN ─────────────────────────────────────────────────────────────
const saveFcmToken = async (req, res) => {
    try {
        const { fcmToken } = req.body;

        if (!fcmToken) {
            return res.status(400).json({
                success: false,
                message: "fcmToken required",
            });
        }

        req.user.fcmToken = fcmToken;
        await req.user.save();

        return res.status(200).json({
            success: true,
        });
    } catch (error) {
        console.log("Save FCM Token Error:", error.message);
        return res.status(500).json({
            success: false,
            message: "Server Error",
        });
    }
};

// ─── EXPORTS ────────────────────────────────────────────────────────────────────
module.exports = {
    completeProfile,
    getCurrentUser,
    getProfile,
    updateProfile,
    saveFcmToken,
};