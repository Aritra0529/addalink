const mongoose = require("mongoose");

const postSchema = new mongoose.Schema(

    {

        user: {

            type: mongoose.Schema.Types.ObjectId,

            ref: "User",

            required: true,
        },

        username: {

            type: String,

            required: true,
        },

        userProfileImage: {

            type: String,

            default: "",
        },

        content: {

            type: String,

            trim: true,

            maxlength: 1500,
        },

        postType: {

            type: String,

            enum: [

                "text",
                "image",
                "video",
            ],

            default: "text",
        },

        images: [

            {
                type: String,
            },
        ],

        video: {

            type: String,

            default: "",
        },

        interests: [

            {
                type: String,
            },
        ],

        location: {

            address: {

                type: String,

                default: "",
            },

            latitude: {

                type: Number,

                default: 0,
            },

            longitude: {

                type: Number,

                default: 0,
            },
        },

        likes: [

            {
                type: mongoose.Schema.Types.ObjectId,

                ref: "User",
            },
        ],

        comments: [

    {

        user: {

            type:
                mongoose.Schema.Types
                    .ObjectId,

            ref: "User",
        },

        username: {

            type: String,
        },

        userProfileImage: {

            type: String,

            default: "",
        },

        text: {

            type: String,

            required: true,
        },

        createdAt: {

            type: Date,

            default: Date.now,
        },
    },
],

        sharesCount: {

            type: Number,

            default: 0,
        },

        viewsCount: {

            type: Number,

            default: 0,
        },

        isEdited: {

            type: Boolean,

            default: false,
        },

        isDeleted: {

            type: Boolean,

            default: false,
        },

    },

    {
        timestamps: true,
    }
);

module.exports = mongoose.model(
    "Post",
    postSchema
);