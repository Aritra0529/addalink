const express = require("express");

const router = express.Router();

const {

    createPost,
    getFeedPosts,
    toggleLikePost,
    addComment,
} = require("../controllers/postController");

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

router.put(
  "/like/:postId",
  protect,
  toggleLikePost,
);

router.post(
  "/comment/:postId",
  protect,
  addComment,
);

// GET FEED
router.get(

    "/feed",

    protect,

    getFeedPosts
);

module.exports = router;