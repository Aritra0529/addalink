const Post = require("../models/Post");

const Notification =
require(
    "../models/Notification"
);

const {

    sendPushNotification,

} = require(
    "../utils/fcmHelper"
);

const cloudinary =
require(
    "../config/cloudinary"
);

// CREATE POST
const createPost =
async (req, res) => {

    try {

        console.log("BODY:");
        console.log(req.body);

        console.log("FILES:");
        console.log(req.files);

        const user =
            req.user;

        const {

            content,
            interests,
            location,

        } = req.body;

        let imageUrls = [];

        let videoUrl = "";

        // UPLOAD IMAGES
        if (

            req.files &&
            req.files.images

        ) {

            console.log(

                "IMAGES RECEIVED:",

                req.files.images.length
            );

            const uploadPromises =

                req.files.images.map(

                    async (file) => {

                        console.log(

                            "UPLOADING IMAGE:",

                            file.path
                        );

                        const result =

                            await cloudinary
                                .uploader
                                .upload(

                                    file.path,

                                    {

                                        folder:
                                            "addalink/posts/images",

                                        quality:
                                            "auto",

                                        fetch_format:
                                            "auto",
                                    }
                                );

                        console.log(

                            "UPLOAD SUCCESS:",

                            result.secure_url
                        );

                        return result
                            .secure_url;
                    }
                );

            imageUrls =
                await Promise.all(
                    uploadPromises
                );

            console.log(
                "ALL IMAGES UPLOADED"
            );
        }

        // UPLOAD VIDEO
        if (

            req.files &&
            req.files.video

        ) {

            const videoFile =
                req.files.video[0];

            const result =

                await cloudinary
                    .uploader
                    .upload(

                        videoFile.path,

                        {

                            resource_type:
                                "video",

                            folder:
                                "addalink/posts/videos",
                        }
                    );

            videoUrl =
                result.secure_url;
        }

        // DETERMINE POST TYPE
        let postType =
            "text";

        if (
            imageUrls.length > 0
        ) {

            postType =
                "image";
        }

        if (videoUrl) {

            postType =
                "video";
        }

        // CREATE POST
        const newPost =
            await Post.create({

                user:
                    user._id,

                username:
                    user.username,

                userProfileImage:

                    user.photo ||

                    user.profileImage ||

                    "",

                content:
                    content || "",

                interests:
                    interests || [],

                location:
                    location || {},

                images:
                    imageUrls,

                video:
                    videoUrl,

                postType,
            });

        return res.status(201).json({

            success: true,

            message:
                "Post created successfully",

            post:
                newPost,
        });

    } catch (error) {

        console.log(error);

        return res.status(500).json({

            success: false,

            message:
                "Failed to create post",
        });
    }
};

// TOGGLE LIKE
const toggleLikePost =
async (req, res) => {

    try {

        const userId =
            req.user.id;

        const { postId } =
            req.params;

        const post =
            await Post.findById(
                postId,
            );

        if (!post) {

            return res.status(404).json({

                success: false,

                message:
                    "Post not found",
            });
        }

        const alreadyLiked =

            post.likes.includes(
                userId,
            );

        // UNLIKE
        if (alreadyLiked) {

            post.likes =
                post.likes.filter(

                    (id) =>

                        id.toString() !==
                        userId,
                );

        } else {

            // LIKE
            post.likes.push(
                userId,
            );

            // CREATE NOTIFICATION
            if (

                String(post.user) !==
                String(userId)

            ) {

                await Notification.create({

                    recipient:
                        post.user,

                    sender:
                        req.user._id,

                    senderName:
                        req.user.username,

                    senderPhoto:

                        req.user.photo ||

                        req.user.profileImage ||

                        "",

                    type:
                        "like",

                    post:
                        post._id,

                    text:
                        "liked your post",
                });

                // SEND FCM PUSH
                sendPushNotification(
                    post.user,
                    {
                        title:
                            req.user.username ||
                            "Someone",
                        body:
                            "liked your post",
                        data: {
                            type: "like",
                            postId:
                                post._id.toString(),
                        },
                    }
                );
            }
        }

        await post.save();

        return res.status(200).json({

            success: true,

            liked:
                !alreadyLiked,

            likesCount:
                post.likes.length,
        });

    } catch (e) {

        console.log(e);

        return res.status(500).json({

            success: false,

            message:
                "Like failed",
        });
    }
};

// ADD COMMENT
const addComment =
async (req, res) => {

    try {

        const { postId } =
            req.params;

        const { text } =
            req.body;

        const post =
            await Post.findById(
                postId,
            );

        if (!post) {

            return res.status(404).json({

                success: false,

                message:
                    "Post not found",
            });
        }

        // ADD COMMENT
        post.comments.unshift({

            user:
                req.user._id,

            username:
                req.user.username,

            userProfileImage:

                req.user.photo ||

                req.user.profileImage ||

                "",

            text,
        });

        await post.save();

        // CREATE COMMENT NOTIFICATION
        if (

            String(post.user) !==
            String(req.user._id)

        ) {

            await Notification.create({

                recipient:
                    post.user,

                sender:
                    req.user._id,

                senderName:
                    req.user.username,

                senderPhoto:

                    req.user.photo ||

                    req.user.profileImage ||

                    "",

                type:
                    "comment",

                post:
                    post._id,

                text:
                    "commented on your post",
            });

            // SEND FCM PUSH
            sendPushNotification(
                post.user,
                {
                    title:
                        req.user.username ||
                        "Someone",
                    body:
                        "commented on your post",
                    data: {
                        type: "comment",
                        postId:
                            post._id.toString(),
                    },
                }
            );
        }

        return res.status(200).json({

            success: true,

            comments:
                post.comments,
        });

    } catch (e) {

        console.log(e);

        return res.status(500).json({

            success: false,

            message:
                "Failed to add comment",
        });
    }
};

// GET FEED POSTS
const getFeedPosts =
async (req, res) => {

    try {

        const posts =
            await Post.find({

                isDeleted: false,
            })

            .sort({

                createdAt: -1,
            });

        const formattedPosts =
            posts.map((post) => {

                return {

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

                    likesCount:
                        post.likes.length,

                    isLiked:

                        post.likes.some(

                            (id) =>

                                id.toString() ===

                                req.user._id.toString()
                        ),

                    comments:
                        post.comments || [],
                };
            });

        return res.status(200).json({

            success: true,

            posts:
                formattedPosts,
        });

    } catch (error) {

        console.log(error);

        return res.status(500).json({

            success: false,

            message:
                "Failed to fetch feed",
        });
    }
};

// GET SINGLE POST BY ID
const getPostById =
async (req, res) => {

    try {

        const { postId } =
            req.params;

        const post =
            await Post.findById(
                postId,
            );

        if (!post || post.isDeleted) {

            return res.status(404).json({

                success: false,

                message:
                    "Post not found",
            });
        }

        const formatted = {

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

            likesCount:
                post.likes.length,

            isLiked:
                post.likes.some(
                    (id) =>
                        id.toString() ===
                        req.user._id.toString()
                ),

            comments:
                post.comments || [],
        };

        return res.status(200).json({

            success: true,

            post: formatted,
        });

    } catch (error) {

        console.log(error);

        return res.status(500).json({

            success: false,

            message:
                "Failed to fetch post",
        });
    }
};

module.exports = {

    createPost,

    toggleLikePost,

    addComment,

    getFeedPosts,

    getPostById,
};