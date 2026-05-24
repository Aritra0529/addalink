const admin =
    require("../config/firebase");

const User =
    require("../models/User");

/**
 * Send a push notification to a user.
 *
 * @param {string} recipientUserId  - MongoDB _id of the recipient
 * @param {object} payload
 * @param {string} payload.title    - Notification title
 * @param {string} payload.body     - Notification body
 * @param {object} payload.data     - Extra key-value data (all strings)
 */
const sendPushNotification =
async (
    recipientUserId,
    { title, body, data = {} }
) => {

    try {

        // GET RECIPIENT FCM TOKEN
        const recipient =
            await User.findById(
                recipientUserId,
            ).select(
                "fcmToken"
            );

        if (
            !recipient ||
            !recipient.fcmToken
        ) {
            return;
        }

        const message = {

            token:
                recipient.fcmToken,

            notification: {
                title,
                body,
            },

            // ANDROID CONFIG
            android: {
                priority: "high",
                notification: {
                    sound: "default",
                    channelId:
                        "addalink_notifications",
                },
            },

            // APNS (iOS) CONFIG
            apns: {
                payload: {
                    aps: {
                        sound: "default",
                        badge: 1,
                    },
                },
            },

            // EXTRA DATA — available in Flutter onMessageOpenedApp
            data: {
                ...data,
                click_action:
                    "FLUTTER_NOTIFICATION_CLICK",
            },
        };

        await admin
            .messaging()
            .send(message);

    } catch (error) {

        // TOKEN EXPIRED / INVALID — clear it
        if (
            error.code ===
                "messaging/registration-token-not-registered" ||
            error.code ===
                "messaging/invalid-registration-token"
        ) {

            await User.findByIdAndUpdate(
                recipientUserId,
                { fcmToken: "" }
            );
        }

        console.log(
            "FCM Error:",
            error.message
        );
    }
};

module.exports = {
    sendPushNotification,
};