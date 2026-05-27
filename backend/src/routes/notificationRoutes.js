const express = require("express");
const router = express.Router();

const {
    getNotifications,
    markNotificationsAsRead,
    getUnreadCount,
} = require("../controllers/notificationController");

const { protect } = require("../middleware/authMiddleware");

// ✅ All routes after imports
router.get("/unread-count", protect, getUnreadCount);
router.get("/", protect, getNotifications);
router.put("/read", protect, markNotificationsAsRead);

module.exports = router;