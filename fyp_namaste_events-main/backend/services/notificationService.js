const { notificationModel } = require("../models/notification");

/**
 * Service for handling notifications
 */
const notificationService = {
  /**
   * Create a new notification
   * @param {Object} notificationData - The notification data
   * @returns {Promise<Object>} The created notification
   */
  createNotification: async (notificationData) => {
    try {
      const { userId, title, message, type, relatedId, onModel } = notificationData;
      
      if (!userId || !title || !message) {
        throw new Error("Missing required fields: userId, title, and message are required");
      }
      
      const notification = new notificationModel({
        userId,
        title,
        message,
        type: type || 'system',
        relatedId,
        onModel
      });
      
      return await notification.save();
    } catch (error) {
      console.error("Error in createNotification service:", error);
      throw error;
    }
  },
  
  /**
   * Create booking notification
   * @param {Object} booking - The booking object
   * @returns {Promise<Object>} The created notification
   */
  createBookingNotification: async (booking) => {
    try {
      // Notification for user
      const userNotification = {
        userId: booking.userId,
        title: "New Booking Created",
        message: `Your booking for ${booking.eventDetails.eventType} on ${new Date(booking.eventDetails.eventDate).toLocaleDateString()} has been created successfully.`,
        type: "booking",
        relatedId: booking._id,
        onModel: "Booking"
      };
      
      // Notification for vendor
      const vendorNotification = {
        userId: booking.vendorId,
        title: "New Booking Received",
        message: `You have received a new booking for ${booking.eventDetails.eventType} on ${new Date(booking.eventDetails.eventDate).toLocaleDateString()}.`,
        type: "booking",
        relatedId: booking._id,
        onModel: "Booking"
      };
      
      const [userNotif, vendorNotif] = await Promise.all([
        notificationModel.create(userNotification),
        notificationModel.create(vendorNotification)
      ]);
      
      return { userNotification: userNotif, vendorNotification: vendorNotif };
    } catch (error) {
      console.error("Error in createBookingNotification service:", error);
      throw error;
    }
  },
  
  /**
   * Create payment notification
   * @param {Object} payment - The payment object
   * @param {String} userId - The user ID
   * @returns {Promise<Object>} The created notification
   */
  createPaymentNotification: async (payment, userId) => {
    try {
      const notification = {
        userId,
        title: "Payment Update",
        message: `Your payment of Rs. ${payment.amount} has been ${payment.status}.`,
        type: "payment",
        relatedId: payment._id,
        onModel: "Booking"
      };
      
      return await notificationModel.create(notification);
    } catch (error) {
      console.error("Error in createPaymentNotification service:", error);
      throw error;
    }
  },
  
  /**
   * Get all notifications for a user
   * @param {String} userId - The user ID
   * @returns {Promise<Array>} Array of notifications
   */
  getUserNotifications: async (userId) => {
    try {
      return await notificationModel
        .find({ userId })
        .sort({ createdAt: -1 });
    } catch (error) {
      console.error("Error in getUserNotifications service:", error);
      throw error;
    }
  },
  
  /**
   * Mark notification as read
   * @param {String} notificationId - The notification ID
   * @param {String} userId - The user ID
   * @returns {Promise<Object>} The updated notification
   */
  markAsRead: async (notificationId, userId) => {
    try {
      const notification = await notificationModel.findOne({
        _id: notificationId,
        userId
      });
      
      if (!notification) {
        throw new Error("Notification not found or not authorized");
      }
      
      notification.isRead = true;
      return await notification.save();
    } catch (error) {
      console.error("Error in markAsRead service:", error);
      throw error;
    }
  },
  
  /**
   * Mark all notifications as read for a user
   * @param {String} userId - The user ID
   * @returns {Promise<Object>} Result of the update operation
   */
  markAllAsRead: async (userId) => {
    try {
      return await notificationModel.updateMany(
        { userId, isRead: false },
        { $set: { isRead: true } }
      );
    } catch (error) {
      console.error("Error in markAllAsRead service:", error);
      throw error;
    }
  },
  
  /**
   * Get unread notification count for a user
   * @param {String} userId - The user ID
   * @returns {Promise<Number>} Count of unread notifications
   */
  getUnreadCount: async (userId) => {
    try {
      return await notificationModel.countDocuments({
        userId,
        isRead: false
      });
    } catch (error) {
      console.error("Error in getUnreadCount service:", error);
      throw error;
    }
  }
};

module.exports = notificationService;