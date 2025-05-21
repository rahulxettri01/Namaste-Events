const mongoose = require('mongoose');

const paymentSchema = new mongoose.Schema({
  pidx: {
    type: String,
    required: true,
    unique: true
  },
  amount: {
    type: Number,
    required: true
  },
  status: {
    type: String,
    enum: ['initiated', 'completed', 'failed', 'expired'],
    default: 'initiated'
  },
  transactionId: String,
  mobile: String,
  paymentMethod: String,
  bookingDetails: Object,
  verificationDetails: Object,
  failureReason: String,
  createdAt: {
    type: Date,
    default: Date.now,
    expires: 1800 // Document expires in 30 minutes if not completed
  },
  completedAt: {
    type: Date,
    default: null
  }
});

// Remove expiry when payment is completed
paymentSchema.pre('save', async function(next) {
  if (this.status === 'completed' && this.isModified('status')) {
    await this.collection.updateOne(
      { _id: this._id },
      { $unset: { createdAt: "" } }
    );
  }
  next();
});

module.exports = mongoose.model('Payment', paymentSchema);