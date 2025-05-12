const mongoose = require("mongoose");

const bookingSchema = new mongoose.Schema({
  userId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: "userModel",
    required: true,
  },
  vendorId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: "vendorModels",
    required: true,
  },
  eventDetails: {
    eventType: { type: String, required: true },
    eventDate: { type: Date, required: true },
    guestCount: { type: Number, required: true },
    requirements: { type: String },
    venue: { type: String },
  },
  bookingStatus: {
    type: String,
    enum: ["pending", "confirmed", "cancelled", "completed"],
    default: "pending",
  },
  paymentStatus: {
    type: String,
    enum: ["pending", "partial", "completed"],
    default: "pending",
  },
  totalAmount: {
    type: Number,
    required: true,
  },
  paidAmount: {
    type: Number,
    default: 0,
  },
  createdAt: {
    type: Date,
    default: Date.now,
  },
  updatedAt: {
    type: Date,
    default: Date.now,
  },
});

const bookingModel = mongoose.model("Booking", bookingSchema);

module.exports = { bookingModel };
