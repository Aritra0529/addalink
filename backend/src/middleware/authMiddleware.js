const admin =
    require("../config/firebase");

const User =
    require("../models/User");

const protect =
    async (
        req,
        res,
        next
    ) => {

    try {

        let token;

        // GET TOKEN
        if (

            req.headers.authorization &&

            req.headers.authorization.startsWith(
                "Bearer"
            )
        ) {

            token =
                req.headers.authorization.split(
                    " "
                )[1];
        }

        // NO TOKEN
        if (!token) {

            return res.status(401).json({

                success: false,

                message:
                    "No token provided",
            });
        }

        // VERIFY FIREBASE TOKEN
        const decodedToken =
            await admin
                .auth()
                .verifyIdToken(
                    token
                );

        // FIND USER
        const user =
            await User.findOne({

                firebaseUid:
                    decodedToken.uid,
            });

        if (!user) {

            return res.status(404).json({

                success: false,

                message:
                    "User not found",
            });
        }

        // ATTACH USER
        req.user = user;

        next();

    } catch (error) {

        console.log(
            "Auth Middleware Error:",
            error.message
        );

        return res.status(401).json({

            success: false,

            message:
                "Unauthorized",
        });
    }
};

module.exports = {
    protect,
};