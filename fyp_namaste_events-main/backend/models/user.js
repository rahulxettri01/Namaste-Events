const mongoose = require("mongoose");
const joi = require("joi");

const userSchema = new mongoose.Schema({
  userName: { type: String, required: true, unique: false },
  email: { type: String, required: true, unique: true },
  phone: joi
    .string()
    .regex(/^[0-9]{10}$/)
    .messages({ "string.pattern.base": `Phone number must have 10 digits.` })
    .required(), //  phone not working
  password: { type: String, required: true },
  role: { type: String, default: "user" },
  status: { type: String, default: "unverified" },
  // role: { type: String, default: "user", enum: ["user", "admin"] },
  otp: { type: String },
  otpExpiry: { type: Date },
});

const userModel = mongoose.model("userModel", userSchema);

module.exports = { userModel };
