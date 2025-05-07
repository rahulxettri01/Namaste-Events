const mongoose = require('mongoose');

const otpSchema = new mongoose.Schema({
    email: {
        type: String,
        required: true,
        unique: true
    },
    otp: {
        type: String,
        required: true
    },
    createdAt: {
        type: Date,
        default: Date.now,
        expires: 1800 // 30 minutes in seconds
    },
    attempts: {
        type: Number,
        default: 0
    }
});

module.exports = mongoose.model('OTP', otpSchema);