const express =
    require("express");

const router =
    express.Router();

const {

    createPost,

    toggleLikePost,

    addComment,

    getFeedPosts,

    getPostById,

} = require(

    "../controllers/postController"
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

// CREATE POST
router.post(

    "/create",

    protect,

    upload.fields([

        {
            name: "images",
            maxCount: 4,
        },

        {
            name: "video",
            maxCount: 1,
        },
    ]),

    createPost
);

// GET FEED
router.get(

    "/feed",

    protect,

    getFeedPosts
);

// GET SINGLE POST BY ID
router.get(

    "/:postId",

    protect,

    getPostById
);

// TOGGLE LIKE
router.put(

    "/like/:postId",

    protect,

    toggleLikePost
);

// ADD COMMENT
router.post(

    "/comment/:postId",

    protect,

    addComment
);

module.exports =
    router;