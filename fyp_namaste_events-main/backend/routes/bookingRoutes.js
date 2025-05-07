const express = require("express");
const router = express.Router();
const  {bookingModel} = require("../models/booking");
const VerifyJWT = require("../middleware/VerifyJWT");

// Create a new booking
router.post("/create", VerifyJWT, async (req, res) => {
  console.log("hit at /api/bookings/create");
  
  try {
    console.log("req.body", req.body);
    
    const booking = new bookingModel({
      userId: req.user.id,
      vendorId: req.body.vendorId,
      inventoryId: req.body.inventoryId?? '',
      price: req.body.price,
      paymentMethod: 'Khalti', // Using default value
      bookingStatus: 'pending',
      paymentStatus: 'pending',
      status: 'active',
      paidAmount: 0,
      eventDetails: {
        eventType: req.body.eventType,
        startDate: new Date(req.body.startDate),
        endDate: new Date(req.body.endDate),
        eventName: req.body.eventName,
        eventDescription: req.body.eventDescription || '',
        guestCount: req.body.guestCount,
      },
      totalAmount: req.body.totalAmount,
    });

    const savedBooking = await booking.save();

    if (!savedBooking) {
      return res.status(500).json({ error: "Failed to create booking" });
    }

    res.status(201).json({ message: "Booking created successfully", booking: savedBooking, status: 201});
  } catch (error) {
    console.log("error at /api/bookings/create", error.message);
    
    res.status(500).json({ error: error.message });
  }
});

// Get all bookings for a user
router.get("/user-bookings", VerifyJWT, async (req, res) => {
  try {
    const bookings = await bookingModel
      .find({ userId: req.user.id })
      .populate('vendorId', 'businessName email phone');
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
      .populate('userId', 'name email');
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
    if (booking.userId.toString() !== req.user.id && 
        booking.vendorId.toString() !== req.user.id) {
      return res.status(403).json({ message: "Not authorized" });
    }

    booking.bookingStatus = req.body.status;
    booking.updatedAt = Date.now();
    const updatedBooking = await booking.save();
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

    booking.paymentStatus = req.body.paymentStatus;
    booking.paidAmount = req.body.paidAmount;
    booking.updatedAt = Date.now();
    const updatedBooking = await booking.save();
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

    booking.bookingStatus = 'cancelled';
    booking.updatedAt = Date.now();
    const updatedBooking = await booking.save();
    res.json(updatedBooking);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

module.exports = router;