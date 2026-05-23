const Notification =
require(
    "../models/Notification"
);

const getNotifications =
async (req, res) => {

    try {

        const notifications =

            await Notification.find({

                recipient:
                    req.user._id,
            })

            .sort({
                createdAt: -1,
            });

        return res.status(200).json({

            success: true,

            notifications,
        });

    } catch (e) {

        console.log(e);

        return res.status(500).json({

            success: false,

            message:
                "Failed to fetch notifications",
        });
    }
};

const markNotificationsAsRead =
async (req, res) => {

    try {

        await Notification.updateMany(

            {
                recipient:
                    req.user._id,

                isRead: false,
            },

            {
                isRead: true,
            }
        );

        return res.status(200).json({

            success: true,
        });

    } catch (e) {

        console.log(e);

        return res.status(500).json({

            success: false,
        });
    }
};

module.exports = {

    getNotifications,

    markNotificationsAsRead,
};