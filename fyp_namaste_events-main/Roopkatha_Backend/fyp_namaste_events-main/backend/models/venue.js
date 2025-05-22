const { object } = require("joi");
const mongoose = require("mongoose");

const venueSchema = new mongoose.Schema({
  venueName: { type: String, required: true },
  address: { type: String, required: true, unique: true },
  price: { type: String, required: true },
  description: { type: String, required: true },
  accommodation: { type: Object, default: {} },
  status: { type: String, default: "avaiable" },
  image: { type: String }, // Add image field
});

// todo : add ratings

const venueModel = mongoose.model("venueModel", venueSchema);

module.exports = { venueModel };
