import NotificationModel from '../model/Notification.js';
import mongoose from 'mongoose';
import BookingModel from '../model/Booking.js';
import BookingNotificationMail from '../mails/notification/bookingNotification.js';

// Helper function to validate ObjectId
const isValidObjectId = (id) => mongoose.Types.ObjectId.isValid(id);

// Get notifications for a customer
export const getCustomerNotifications = async (req, res) => {
    try {
        const { customerId } = req.params;
        console.log('[getCustomerNotifications] Fetching notifications for customerId:', customerId);

        if (!mongoose.Types.ObjectId.isValid(customerId)) {
            console.error('[getCustomerNotifications] Invalid customer ID:', customerId);
            return res.status(400).json({ error: 'Invalid customer ID' });
        }

        const notifications = await NotificationModel.find({
            recipientId: customerId,
            recipientModel: 'Customer',
        }).sort({ createdAt: -1 });

        console.log('[getCustomerNotifications] Fetched notifications:', notifications);
        return res.status(200).json({ notifications });
    } catch (error) {
        console.error('[getCustomerNotifications] Error fetching notifications:', error);
        return res.status(500).json({ error: 'Error fetching notifications' });
    }
};

// Get notifications for an artist
export const getArtistNotifications = async (req, res) => {
    try {
        const { artistId } = req.params;
        console.log('[getArtistNotifications] Fetching notifications for artistId:', artistId);

        if (!mongoose.Types.ObjectId.isValid(artistId)) {
            console.error('[getArtistNotifications] Invalid artist ID:', artistId);
            return res.status(400).json({ error: 'Invalid artist ID' });
        }

        const notifications = await NotificationModel.find({
            recipientId: artistId,
            recipientModel: 'Artist',
        }).sort({ createdAt: -1 });

        console.log('[getArtistNotifications] Fetched notifications:', notifications);
        return res.status(200).json({ notifications });
    } catch (error) {
        console.error('[getArtistNotifications] Error fetching notifications:', error);
        return res.status(500).json({ error: 'Error fetching notifications' });
    }
};

// Get unread notification count for a customer
export const getCustomerUnreadCount = async (req, res) => {
    try {
        const { customerId } = req.params;
        console.log('[getCustomerUnreadCount] Fetching unread count for customerId:', customerId);

        if (!mongoose.Types.ObjectId.isValid(customerId)) {
            console.error('[getCustomerUnreadCount] Invalid customer ID:', customerId);
            return res.status(400).json({ error: 'Invalid customer ID' });
        }

        const count = await NotificationModel.countDocuments({
            recipientId: new mongoose.Types.ObjectId(customerId),
            recipientModel: 'Customer',
            isRead: false,
        });

        console.log('[getCustomerUnreadCount] Unread count:', count);
        return res.status(200).json({ unreadCount: count });
    } catch (error) {
        console.error('[getCustomerUnreadCount] Error fetching unread notification count:', error);
        return res.status(500).json({ error: 'Error fetching unread count' });
    }
};

// Get unread notification count for an artist
export const getArtistUnreadCount = async (req, res) => {
    try {
        const { artistId } = req.params;
        console.log('[getArtistUnreadCount] Fetching unread count for artistId:', artistId);

        if (!mongoose.Types.ObjectId.isValid(artistId)) {
            console.error('[getArtistUnreadCount] Invalid artist ID:', artistId);
            return res.status(400).json({ error: 'Invalid artist ID' });
        }

        const count = await NotificationModel.countDocuments({
            recipientId: new mongoose.Types.ObjectId(artistId),
            recipientModel: 'Artist',
            isRead: false,
        });

        console.log('[getArtistUnreadCount] Unread count:', count);
        return res.status(200).json({ unreadCount: count });
    } catch (error) {
        console.error('[getArtistUnreadCount] Error fetching unread notification count:', error);
        return res.status(500).json({ error: 'Error fetching unread count' });
    }
};

// Mark notification as read (works for both)
export const markAsRead = async (req, res) => {
    try {
        const { notificationId } = req.params;
        console.log('[markAsRead] Marking notification as read. notificationId:', notificationId);

        if (!isValidObjectId(notificationId)) {
            console.error('[markAsRead] Invalid notification ID:', notificationId);
            return res.status(400).json({ error: 'Invalid notification ID' });
        }

        const notification = await NotificationModel.findByIdAndUpdate(
            notificationId,
            { isRead: true },
            { new: true }
        );

        if (!notification) {
            console.error('[markAsRead] Notification not found:', notificationId);
            return res.status(404).json({ error: 'Notification not found' });
        }

        console.log('[markAsRead] Notification marked as read:', notification);
        return res.status(200).json({ message: 'Notification marked as read', notification });
    } catch (error) {
        console.error('[markAsRead] Error marking notification as read:', error);
        return res.status(500).json({ error: 'Error marking notification as read' });
    }
};

// Mark all notifications as read for a customer
export const markAllCustomerAsRead = async (req, res) => {
    try {
        const { customerId } = req.params;
        console.log('[markAllCustomerAsRead] Marking all notifications as read for customerId:', customerId);

        if (!isValidObjectId(customerId)) {
            console.error('[markAllCustomerAsRead] Invalid customer ID:', customerId);
            return res.status(400).json({ error: 'Invalid customer ID' });
        }

        const result = await NotificationModel.updateMany(
            { recipientId: customerId, recipientModel: 'Customer' },
            { isRead: true }
        );

        console.log('[markAllCustomerAsRead] Update result:', result);
        return res.status(200).json({ message: 'All customer notifications marked as read' });
    } catch (error) {
        console.error('[markAllCustomerAsRead] Error marking all notifications as read:', error);
        return res.status(500).json({ error: 'Error marking all notifications as read' });
    }
};

// Mark all notifications as read for an artist
export const markAllArtistAsRead = async (req, res) => {
    try {
        const { artistId } = req.params;
        console.log('[markAllArtistAsRead] Marking all notifications as read for artistId:', artistId);

        if (!isValidObjectId(artistId)) {
            console.error('[markAllArtistAsRead] Invalid artist ID:', artistId);
            return res.status(400).json({ error: 'Invalid artist ID' });
        }

        const result = await NotificationModel.updateMany(
            { recipientId: artistId, recipientModel: 'Artist' },
            { isRead: true }
        );

        console.log('[markAllArtistAsRead] Update result:', result);
        return res.status(200).json({ message: 'All artist notifications marked as read' });
    } catch (error) {
        console.error('[markAllArtistAsRead] Error marking all notifications as read:', error);
        return res.status(500).json({ error: 'Error marking all notifications as read' });
    }
};

// Add this function if not present
export const scheduleReminderNotifications = async (bookingId) => {
    console.log('[scheduleReminderNotifications] Called with bookingId:', bookingId);
    // Implement your logic here or copy from your previous implementation
};

export const sendBookingNotification = async (bookingId) => {
    try {
        console.log('[sendBookingNotification] Called with bookingId:', bookingId);
        const booking = await BookingModel.findById(bookingId)
            .populate('customerID')
            .populate('artistID')
            .populate('serviceID');

        if (!booking) {
            console.error('[sendBookingNotification] Booking not found:', bookingId);
            return false;
        }

        // Notification for artist
        console.log('[sendBookingNotification] Creating notification for artist:', booking.artistID._id);
        await createNotification(
            booking.artistID._id,
            'Artist',
            'New Booking',
            `You have a new booking for ${booking.serviceID.name} from ${booking.customerID.name}`,
            'booking',
            { model: 'Booking', id: booking._id }
        );

        // Notification for customer
        console.log('[sendBookingNotification] Creating notification for customer:', booking.customerID._id);
        await createNotification(
            booking.customerID._id,
            'Customer',
            'Booking Confirmed',
            `Your booking for ${booking.serviceID.name} has been confirmed`,
            'booking',
            { model: 'Booking', id: booking._id }
        );

        // Send email notifications
        if (booking.artistID.email) {
            console.log('[sendBookingNotification] Sending email to artist:', booking.artistID.email);
            const artistMail = new BookingNotificationMail({
                to: booking.artistID.email
            }, {
                user: booking.artistID,
                booking: booking,
                message: `You have a new booking for ${booking.serviceID.name} from ${booking.customerID.name}`
            });
            artistMail.send();
        }

        if (booking.customerID.email) {
            console.log('[sendBookingNotification] Sending email to customer:', booking.customerID.email);
            const customerMail = new BookingNotificationMail({
                to: booking.customerID.email
            }, {
                user: booking.customerID,
                booking: booking,
                message: `Your booking for ${booking.serviceID.name} has been confirmed`
            });
            customerMail.send();
        }

        return true;
    } catch (error) {
        console.error('[sendBookingNotification] Error sending booking notification:', error);
        return false;
    }
};
// Add this export for createNotification
export const createNotification = async (recipientId, recipientModel, title, message, type, relatedTo = {}) => {
    try {
        console.log('[createNotification] Creating notification for recipientId:', recipientId, 'recipientModel:', recipientModel, 'title:', title);
        const notification = new NotificationModel({
            recipientId,
            recipientModel,
            title,
            message,
            type,
            relatedTo
        });
        await notification.save();
        console.log('[createNotification] Notification saved:', notification);
        return notification;
    } catch (error) {
        console.error('[createNotification] Error creating notification:', error);
        return null;
    }
};
