const mongoose = require("mongoose");

const vendorAvailabilitySchema = new mongoose.Schema({
  vendorId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'vendorModels',
    required: true
  },
  date: {
    type: Date,
    required: true
  },
  isAvailable: {
    type: Boolean,
    default: true
  },
  reason: {
    type: String
  },
  updatedAt: {
    type: Date,
    default: Date.now
  }
});

const vendorAvailabilityModel = mongoose.model("VendorAvailability", vendorAvailabilitySchema);
module.exports = { vendorAvailabilityModel };