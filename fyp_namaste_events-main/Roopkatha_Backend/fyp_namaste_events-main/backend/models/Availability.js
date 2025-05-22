const mongoose = require("mongoose");

const AvailabilitySchema = new mongoose.Schema(
  {
    availabilityID: {
      type: String,
      unique: true,
      default: () => new mongoose.Types.ObjectId().toString(),
    },
    vendorEmail: {
      type: String,
      required: true,
    },
    startDate: {
      type: String,
      required: true,
    },
    endDate: {
      type: String,
      required: true,
    },
    category: {
      type: String,
      required: true,
      enum: ["Photography", "Venue", "Decorator"],
    },
    status: {
      type: String,
      required: true,
      enum: ["Available", "Booked"],
      default: "Available",
    },
  },
  {
    timestamps: true,
    collection: "availabilities",
  }
);

// Create compound index for unique date ranges per vendor
AvailabilitySchema.index(
  { vendorEmail: 1, startDate: 1, endDate: 1, category: 1 },
  { unique: true }
);

const AvailabilityModel = mongoose.model("Availability", AvailabilitySchema);
module.exports = { AvailabilityModel };
