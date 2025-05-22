const mongoose = require("mongoose");
const { vendorModel } = require("./vendor");

const docImgSchema = new mongoose.Schema({
  fileName: { type: String, required: true },
  filePath: { type: String, required: true },
  srcFrom: { type: String, required: true },
  type: { type: String, required: true },
});

const venueImgSchema = new mongoose.Schema({
  fileName: { type: String, required: true },
  filePath: { type: String, required: true },
  srcFrom: { type: String, required: true },
  type: { type: String, required: true },
});
const photographyImgSchema = new mongoose.Schema({
  fileName: { type: String, required: true },
  filePath: { type: String, required: true },
  srcFrom: { type: String, required: true },
  type: { type: String, required: true },
});
const decorationImgSchema = new mongoose.Schema({
  fileName: { type: String },
  filePath: { type: String, required: true },
  srcFrom: { type: String, required: true },
  type: { type: String, required: true },
});

const docImageModel = mongoose.model("docImageModel", docImgSchema);
const venueImageModel = mongoose.model("venueImageModel", venueImgSchema);
const photographyImageModel = mongoose.model(
  "photographyImageModel",
  photographyImgSchema
);
const decorationImageModel = mongoose.model(
  "decorationImageModel",
  decorationImgSchema
);

module.exports = {
  docImageModel,
  venueImageModel,
  photographyImageModel,
  decorationImageModel,
};
