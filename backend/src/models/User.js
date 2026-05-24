const mongoose = require("mongoose");

const userSchema = new mongoose.Schema(
    {

        firebaseUid: {
            type: String,
            required: true,
            unique: true,
        },

        name: {
            type: String,
            required: true,
            trim: true,
        },

        email: {
            type: String,
            required: true,
            unique: true,
            lowercase: true,
        },

        photo: {
            type: String,
            default: "",
        },

        username: {
            type: String,
            default: "",
            trim: true,
        },

        phone: {
            type: String,
            default: "",
        },

        bio: {
            type: String,
            default: "",
            maxlength: 300,
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

            googleMapsLink: {
                type: String,
                default: "",
            },
        },

        reputation: {
            type: Number,
            default: 0,
        },

        badges: [
            {
                type: String,
            },
        ],

        isProfileComplete: {
            type: Boolean,
            default: false,
        },

        isVerified: {
            type: Boolean,
            default: false,
        },

        fcmToken: {
            type: String,
            default: "",
        },

    },
    {
        timestamps: true,
    }
);

// GEO INDEX
userSchema.index({
    "location.latitude": 1,
    "location.longitude": 1,
});

module.exports = mongoose.model(
    "User",
    userSchema
);