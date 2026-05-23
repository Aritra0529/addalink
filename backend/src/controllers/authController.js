const admin = require("../config/firebase");

const User = require("../models/User");

const generateToken = require(
    "../utils/generateToken"
);

// GOOGLE LOGIN
const googleLogin = async (
    req,
    res
) => {

    try {

        const { firebaseToken } =
            req.body;

        // VERIFY TOKEN
        const decodedToken =
            await admin
                .auth()
                .verifyIdToken(
                    firebaseToken
                );

        // CHECK USER
        let user =
            await User.findOne({
                firebaseUid:
                    decodedToken.uid,
            });

        // CREATE USER IF NOT EXISTS
        if (!user) {

            user = await User.create({

                firebaseUid:
                    decodedToken.uid,

                name:
                    decodedToken.name ||
                    "",

                email:
                    decodedToken.email ||
                    "",

                photo:
                    decodedToken.picture ||
                    "",
            });
        }

        // GENERATE JWT
        const token =
            generateToken(
                user._id
            );

        return res.status(200).json({

            success: true,

            token,

            user,
        });

    } catch (error) {

        console.log(
            "Google Login Error:",
            error.message
        );

        return res.status(500).json({

            success: false,

            message:
                "Authentication Failed",
        });
    }
};

module.exports = {
    googleLogin,
};