import mongoose from "mongoose";

const paymentSchema = new mongoose.Schema(
  {
    transactionId: { type: String, unique: true, required: true }, // add required
    pidx: { type: String, unique: true, required: true }, // add required
    bookingID: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "Booking",
      required: true,
    },
    customerID: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "Customer",
      required: true,
    },
    artistID: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'artist',
      required: true,
    },
    availabilityID: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "Availability",
      required: true,
    },
    amount: { type: Number, required: true },
    dataFromVerificationReq: { type: mongoose.Schema.Types.Mixed }, // better than plain Object
    apiQueryFromUser: { type: mongoose.Schema.Types.Mixed },
    paymentGateway: {
      type: String,
      enum: ["khalti", "Khalti"], // Ideally store lowercase only -> consider enforcing "lowercase: true"
      required: true,
    },
    status: {
      type: String,
      enum: ["success", "pending", "failed"],
      default: "pending",
    },
    paymentDate: { type: Date, default: Date.now },
  },
  { timestamps: true }
);

const PaymentModel = mongoose.model("Payment", paymentSchema);
export default PaymentModel;
