import mongoose from 'mongoose';

const ReviewSchema = new mongoose.Schema(
    {
        reviewID: { type: mongoose.Schema.Types.ObjectId, unique: true, default: () => new mongoose.Types.ObjectId() },
        customerID: { type: mongoose.Schema.Types.ObjectId, required: true, ref: 'Customer' },
        artistID: { type: mongoose.Schema.Types.ObjectId, required: true, ref: 'Artist' },
        serviceID: { type: mongoose.Schema.Types.ObjectId, required: true, ref: 'Service' },
        review: { type: String, required: true, trim: true }, // Detailed review text
        rating: { type: Number, required: true, min: 1, max: 5 },
        reply: { type: String }
    },
    { timestamps: true }
);

const ReviewModel = mongoose.model('Review', ReviewSchema);
export { ReviewModel };