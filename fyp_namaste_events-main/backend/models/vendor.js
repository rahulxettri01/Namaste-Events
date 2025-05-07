const mongoose = require("mongoose");

const vendorSchema = new mongoose.Schema({
  vendorName: { type: String, required: true },
  email: { type: String, required: true, unique: true },
  phone: { type: String, required: true },
  password: { type: String, required: true },
  role: { type: String, default: "admin" },
  status: { type: String, default: "unverified" },
  citizenshipFilePath: { type: String },
  panFilePath: { type: String },
  category: { type: String, required: true },
});

const vendorModel = mongoose.model("vendorModels", vendorSchema);

// const venueSchema = new mongoose.Schema({
//   venueName: { type: String, required: true },
//   address: { type: String, unique: true },
//   price: { type: String },
//   description: { type: String },
//   accommodation: { type: Object, default: {} },
//   status: { type: String, default: "avaiable" },
//   image: { type: String }, // Add image field
// });

// // todo : add ratings

// const venueModel = mongoose.model("venueModel", venueSchema);

const venueSchema = new mongoose.Schema({
  venueName: { type: String },
  address: { type: String },
  price: { type: String },
  description: { type: String },
  accommodation: { type: Object, default: {} },
  avaiable: { type: String, default: "available" },
  image: { type: String },
  owner: { type: String, unique: true },
});

// Look for this section in your vendor.js file
// Change this:
// const venueModel = mongoose.model("venue", venueSchema);

// To this:
const venueModel =
  mongoose.models.venue || mongoose.model("venue", venueSchema);

const photographySchema = new mongoose.Schema({
  photographyName: { type: String },
  address: { type: String, unique: true },
  price: { type: String },
  description: { type: String },
  accommodation: { type: Object, default: {} },
  status: { type: String, default: "avaiable" },
  owner: { type: String, unique: true },
});

// todo : add ratings

// const photographyModel = mongoose.model("photographyModel", photographySchema);
const photographyModel =
  mongoose.models.photography ||
  mongoose.model("photography", photographySchema);

const decoratorSchema = new mongoose.Schema({
  decoratorName: { type: String },
  address: { type: String, unique: true },
  price: { type: String },
  description: { type: String },
  accommodation: { type: Object, default: {} },
  status: { type: String, default: "avaiable" },
  owner: { type: String, unique: true },
});

// todo : add ratings

// const decoratorModel = mongoose.model("decoratorModel", decoratorSchema);
const decoratorModel =
  mongoose.models.decorator || mongoose.model("decorator", decoratorSchema);

module.exports = { vendorModel, decoratorModel, photographyModel, venueModel };
