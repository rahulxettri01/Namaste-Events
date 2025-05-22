const express = require("express");
const router = express.Router();
const { notificationModel } = require("../models/notification");
const VerifyJWT = require("../middleware/VerifyJWT");

// Create a new notification
router.post("/create", async (req, res) => {
  try {
    const { userId, title, message, type, relatedId, onModel } = req.body;

    if (!userId || !title || !message) {
      return res.status(400).json({
        success: false,
        message: "Missing required fields: userId, title, and message are required"
      });
    }

    const notification = new notificationModel({
      userId,
      title,
      message,
      type: type || 'system',
      relatedId,
      onModel
    });

    const savedNotification = await notification.save();
    
    res.status(201).json({
      success: true,
      message: "Notification created successfully",
      data: savedNotification
    });
  } catch (error) {
    console.error("Error creating notification:", error);
    res.status(500).json({
      success: false,
      message: "Failed to create notification",
      error: error.message
    });
  }
});

// Get all notifications for a user
router.get("/user/:userId", async (req, res) => {
  try {
    const userId = req.params.userId;
    
    const notifications = await notificationModel
      .find({ userId })
      .sort({ createdAt: -1 });
    
    res.status(200).json({
      success: true,
      notifications: notifications.map(notification => ({
        id: notification._id,
        title: notification.title,
        body: notification.message,
        type: notification.type,
        isRead: notification.isRead,
        metadata: {
          relatedId: notification.relatedId,
          onModel: notification.onModel
        },
        createdAt: notification.createdAt
      }))
    });
  } catch (error) {
    console.error("Error fetching notifications:", error);
    res.status(500).json({
      success: false,
      message: "Failed to fetch notifications",
      error: error.message
    });
  }
});

// Get notifications for a vendor
router.get("/vendor/:vendorId", async (req, res) => {
  try {
    const vendorId = req.params.vendorId;
    
    const notifications = await notificationModel
      .find({ userId: vendorId })
      .sort({ createdAt: -1 });
    
    res.status(200).json({
      success: true,
      notifications: notifications.map(notification => ({
        id: notification._id,
        title: notification.title,
        body: notification.message,
        type: notification.type,
        isRead: notification.isRead,
        metadata: {
          relatedId: notification.relatedId,
          onModel: notification.onModel
        },
        createdAt: notification.createdAt
      }))
    });
  } catch (error) {
    console.error("Error fetching notifications:", error);
    res.status(500).json({
      success: false,
      message: "Failed to fetch notifications",
      error: error.message
    });
  }
});

// Mark notification as read
router.put("/read/:id", VerifyJWT, async (req, res) => {
  try {
    const notificationId = req.params.id;
    
    const notification = await notificationModel.findById(notificationId);
    
    if (!notification) {
      return res.status(404).json({
        success: false,
        message: "Notification not found"
      });
    }
    
    notification.isRead = true;
    await notification.save();
    
    res.status(200).json({
      success: true,
      message: "Notification marked as read"
    });
  } catch (error) {
    console.error("Error marking notification as read:", error);
    res.status(500).json({
      success: false,
      message: "Failed to mark notification as read",
      error: error.message
    });
  }
});

// Mark all notifications as read for a user
router.put("/read-all/:userId", async (req, res) => {
  try {
    const userId = req.params.userId;
    
    const result = await notificationModel.updateMany(
      { userId, isRead: false },
      { $set: { isRead: true } }
    );
    
    res.status(200).json({
      success: true,
      message: "All notifications marked as read",
      count: result.modifiedCount
    });
  } catch (error) {
    console.error("Error marking all notifications as read:", error);
    res.status(500).json({
      success: false,
      message: "Failed to mark all notifications as read",
      error: error.message
    });
  }
});

// Get unread notification count for a user
router.get("/unread-count/:userId", async (req, res) => {
  try {
    const userId = req.params.userId;
    
    const count = await notificationModel.countDocuments({
      userId,
      isRead: false
    });
    
    res.status(200).json({
      success: true,
      count
    });
  } catch (error) {
    console.error("Error counting unread notifications:", error);
    res.status(500).json({
      success: false,
      message: "Failed to count unread notifications",
      error: error.message
    });
  }
});

module.exports = router;