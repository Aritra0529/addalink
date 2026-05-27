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

        let thumbnailUrl = "";

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

                            file.originalname
                        );

                        // Stream buffer directly — memoryStorage gives buffer, not path
                        const result = await new Promise(
                            (resolve, reject) => {

                                const stream =
                                    cloudinary.uploader.upload_stream(

                                        {
                                            folder: "addalink/posts/images",
                                            quality: "auto",
                                            fetch_format: "auto",
                                        },

                                        (error, result) => {
                                            if (error) reject(error);
                                            else resolve(result);
                                        }
                                    );

                                stream.end(file.buffer);
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

            // Stream buffer directly to Cloudinary to avoid ECONNRESET
            // that occurs when uploading large buffers via uploader.upload()
            const result = await new Promise(
                (resolve, reject) => {

                    const stream =
                        cloudinary.uploader.upload_stream(

                            {
                                resource_type: "video",
                                folder: "addalink/posts/videos",
                            },

                            (error, result) => {
                                if (error) reject(error);
                                else resolve(result);
                            }
                        );

                    stream.end(videoFile.buffer);
                }
            );

            videoUrl =
                result.secure_url;

            // Derive thumbnail using Cloudinary URL transformation —
            // no eager/webhook needed, URL is available immediately.
            thumbnailUrl = videoUrl
                .replace(
                    "/upload/",
                    "/upload/w_720,h_405,c_fill,g_auto,q_auto,so_0/",
                )
                .replace(
                    /\.[^.]+$/,
                    ".jpg",
                );
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

               userProfileImage: user.photo || "",

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

                thumbnail:
                    thumbnailUrl,

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

// EDIT POST (TEXT ONLY)
const editPost =
async (req, res) => {

    try {

        const { postId } =
            req.params;

        const { content } =
            req.body;

        const userId =
            req.user._id;

        // FIND POST
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

        // VERIFY OWNERSHIP
        if (

            String(post.user) !==
            String(userId)

        ) {

            return res.status(403).json({

                success: false,

                message:
                    "Unauthorized: You can only edit your own posts",
            });
        }

        // VERIFY POST NOT DELETED
        if (post.isDeleted) {

            return res.status(404).json({

                success: false,

                message:
                    "Cannot edit a deleted post",
            });
        }

        // UPDATE CONTENT AND MARK AS EDITED
        post.content = content || "";
        post.isEdited = true;

        await post.save();

        return res.status(200).json({

            success: true,

            message:
                "Post updated successfully",

            post: post,
        });

    } catch (error) {

        console.log(error);

        return res.status(500).json({

            success: false,

            message:
                "Failed to edit post",
        });
    }
};

// SOFT DELETE POST
const deletePost =
async (req, res) => {

    try {

        const { postId } =
            req.params;

        const userId =
            req.user._id;

        // FIND POST
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

        // VERIFY OWNERSHIP
        if (

            String(post.user) !==
            String(userId)

        ) {

            return res.status(403).json({

                success: false,

                message:
                    "Unauthorized: You can only delete your own posts",
            });
        }

        // SOFT DELETE
        post.isDeleted = true;

        await post.save();

        return res.status(200).json({

            success: true,

            message:
                "Post deleted successfully",

            postId: postId,
        });

    } catch (error) {

        console.log(error);

        return res.status(500).json({

            success: false,

            message:
                "Failed to delete post",
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

                    senderPhoto: req.user.photo || "",

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

           userProfileImage: req.user.photo || "",

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

                senderPhoto: req.user.photo || "",

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

        const page =
            parseInt(req.query.page) || 1;

        const limit =
            parseInt(req.query.limit) || 10;

        const skip =
            (page - 1) * limit;

        const totalPosts =
            await Post.countDocuments({
                isDeleted: false,
            });

        const totalPages =
            Math.ceil(totalPosts / limit);

        const posts =
            await Post.find({

                isDeleted: false,
            })

            .sort({

                createdAt: -1,
            })

            .skip(skip)

            .limit(limit);

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

                    thumbnail:
                        post.thumbnail || "",

                    postType:
                        post.postType,

                    createdAt:
                        post.createdAt,

                    isEdited:
                        post.isEdited,

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

            currentPage:
                page,

            totalPages:
                totalPages,

            hasMore:
                page < totalPages,
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

            thumbnail:
                post.thumbnail || "",

            postType:
                post.postType,

            createdAt:
                post.createdAt,

            isEdited:
                post.isEdited,

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

    editPost,

    deletePost,

    toggleLikePost,

    addComment,

    getFeedPosts,

    getPostById,
};