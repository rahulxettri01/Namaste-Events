const express = require("express");
const router = express.Router();
const { bookingModel } = require("../models/booking");
const VerifyJWT = require("../middleware/VerifyJWT");
const notificationService = require("../services/notificationService");

// Create a new booking
router.post("/create", VerifyJWT, async (req, res) => {
	try {
		console.log("in api/booking/create");
		console.log("user ko: ", req.user);
		console.log("body ko: ", req.body);

		const booking = new bookingModel({
			userId: req.user.id,
			vendorId: req.body.vendorId,
			eventDetails: {
				eventType: req.body.eventType || "",
				eventDate: new Date(req.body.startDate),
				guestCount: req.body.guestCount,
				requirements: req.body.requirements || "",
				venue: req.body.venue || "",
			},
			bookingStatus: "confirmed",
			paymentStatus: "completed",
			totalAmount: req.body.totalAmount,
		});

		const savedBooking = await booking.save();

		// Create notifications for both user and vendor
		try {
			await notificationService.createBookingNotification(savedBooking);
		} catch (notifError) {
			console.error("Error creating booking notifications:", notifError);
			// Continue with the response even if notification creation fails
		}

		res.status(201).json(savedBooking);
	} catch (error) {
		res.status(500).json({ error: error.message });
	}
});

// Get all bookings for a user
router.get("/user-bookings", VerifyJWT, async (req, res) => {
	try {
		const bookings = await bookingModel
			.find({ userId: req.user.id })
			.populate("vendorId", "businessName email phone");
		res.json(bookings);
	} catch (error) {
		res.status(500).json({ error: error.message });
	}
});

// Get all bookings for a vendor
router.get("/vendor-bookings", VerifyJWT, async (req, res) => {
	try {
		const bookings = await bookingModel
			.find({ vendorId: req.user.id })
			.populate("userId", "name email");
		res.json(bookings);
	} catch (error) {
		res.status(500).json({ error: error.message });
	}
});

// Update booking status
router.put("/update-status/:bookingId", VerifyJWT, async (req, res) => {
	try {
		const booking = await bookingModel.findById(req.params.bookingId);
		if (!booking) {
			return res.status(404).json({ message: "Booking not found" });
		}

		// Check if user is authorized (either the vendor or the user who made the booking)
		if (
			booking.userId.toString() !== req.user.id &&
			booking.vendorId.toString() !== req.user.id
		) {
			return res.status(403).json({ message: "Not authorized" });
		}

		const oldStatus = booking.bookingStatus;
		booking.bookingStatus = req.body.status;
		booking.updatedAt = Date.now();
		const updatedBooking = await booking.save();

		// Create notification for status change
		try {
			// Notification for the user
			await notificationService.createNotification({
				userId: booking.userId,
				title: "Booking Status Updated",
				message: `Your booking status has been updated from ${oldStatus} to ${updatedBooking.bookingStatus}.`,
				type: "booking",
				relatedId: booking._id,
				onModel: "Booking",
			});

			// If the update was made by the user, also notify the vendor
			if (req.user.id === booking.userId.toString()) {
				await notificationService.createNotification({
					userId: booking.vendorId,
					title: "Booking Status Updated",
					message: `A booking status has been updated from ${oldStatus} to ${updatedBooking.bookingStatus}.`,
					type: "booking",
					relatedId: booking._id,
					onModel: "Booking",
				});
			}
		} catch (notifError) {
			console.error("Error creating status update notification:", notifError);
			// Continue with the response even if notification creation fails
		}

		res.json(updatedBooking);
	} catch (error) {
		res.status(500).json({ error: error.message });
	}
});

// Update payment status
router.put("/update-payment/:bookingId", VerifyJWT, async (req, res) => {
	try {
		const booking = await bookingModel.findById(req.params.bookingId);
		if (!booking) {
			return res.status(404).json({ message: "Booking not found" });
		}

		const oldPaymentStatus = booking.paymentStatus;
		const oldPaidAmount = booking.paidAmount;

		booking.paymentStatus = req.body.paymentStatus;
		booking.paidAmount = req.body.paidAmount;
		booking.updatedAt = Date.now();
		const updatedBooking = await booking.save();

		// Create notification for payment update
		try {
			// Notification for the user
			await notificationService.createNotification({
				userId: booking.userId,
				title: "Payment Status Updated",
				message: `Your payment status has been updated from ${oldPaymentStatus} to ${updatedBooking.paymentStatus}. Amount paid: Rs. ${updatedBooking.paidAmount}`,
				type: "payment",
				relatedId: booking._id,
				onModel: "Booking",
			});

			// Notification for the vendor
			await notificationService.createNotification({
				userId: booking.vendorId,
				title: "Payment Received",
				message: `Payment received for booking. Status updated from ${oldPaymentStatus} to ${
					updatedBooking.paymentStatus
				}. Amount: Rs. ${updatedBooking.paidAmount - oldPaidAmount}`,
				type: "payment",
				relatedId: booking._id,
				onModel: "Booking",
			});
		} catch (notifError) {
			console.error("Error creating payment update notification:", notifError);
			// Continue with the response even if notification creation fails
		}

		res.json(updatedBooking);
	} catch (error) {
		res.status(500).json({ error: error.message });
	}
});

// Cancel booking
router.put("/cancel/:bookingId", VerifyJWT, async (req, res) => {
	try {
		const booking = await bookingModel.findById(req.params.bookingId);
		if (!booking) {
			return res.status(404).json({ message: "Booking not found" });
		}

		if (booking.userId.toString() !== req.user.id) {
			return res.status(403).json({ message: "Not authorized" });
		}

		booking.bookingStatus = "cancelled";
		booking.updatedAt = Date.now();
		const updatedBooking = await booking.save();

		// Create cancellation notifications
		try {
			// Notification for the user
			await notificationService.createNotification({
				userId: booking.userId,
				title: "Booking Cancelled",
				message: `Your booking for ${
					booking.eventDetails.eventType
				} on ${new Date(
					booking.eventDetails.eventDate
				).toLocaleDateString()} has been cancelled.`,
				type: "booking",
				relatedId: booking._id,
				onModel: "Booking",
			});

			// Notification for the vendor
			await notificationService.createNotification({
				userId: booking.vendorId,
				title: "Booking Cancelled",
				message: `A booking for ${booking.eventDetails.eventType} on ${new Date(
					booking.eventDetails.eventDate
				).toLocaleDateString()} has been cancelled by the user.`,
				type: "booking",
				relatedId: booking._id,
				onModel: "Booking",
			});
		} catch (notifError) {
			console.error("Error creating cancellation notification:", notifError);
			// Continue with the response even if notification creation fails
		}

		res.json(updatedBooking);
	} catch (error) {
		res.status(500).json({ error: error.message });
	}
});

module.exports = router;
