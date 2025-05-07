const express = require("express");
const router = express.Router();
const { OTP } = require("../models/otp");
const { sendOTPEmail, sendMail } = require("../middleware/sendMail");
const { connectUserDB } = require("../Config/DBconfig");
const { userModel } = require("../models/user");

// Generate and send OTP
router.post("/generate", async (req, res) => {
  const { email, userName } = req.body;
  console.log("resen oyp");
  console.log("email", email);

  try {
    // Generate 6-digit OTP
    const otp = Math.floor(100000 + Math.random() * 900000).toString();
    await connectUserDB(async () => {
      // Create or update OTP record
      await userModel.findOneAndUpdate(
        { email },
        { otp },
        { upsert: true, new: true }
      );
    });
    // Send email
    await sendOTPEmail(email, "userName", otp);

    res.status(200).json({
      success: true,
      message: "OTP sent successfully",
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: "Failed to send OTP",
    });
  }
});

// Verify OTP
router.post("/verify", async (req, res) => {
  const { email, otp } = req.body;

  try {
    await connectUserDB(async () => {
      const otpRecord = await OTP.findOne({ email });

      if (!otpRecord) {
        return res.status(400).json({
          success: false,
          message: "OTP expired or not found",
        });
      }

      if (otpRecord.otp !== otp) {
        // Increment failed attempts
        await OTP.updateOne({ email }, { $inc: { attempts: 1 } });

        return res.status(400).json({
          success: false,
          message: "Invalid OTP",
        });
      }

      // OTP verified successfully
      await OTP.deleteOne({ email });

      res.status(200).json({
        success: true,
        message: "OTP verified successfully",
      });
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: "OTP verification failed",
    });
  }
});

module.exports = router;
