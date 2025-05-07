import mongoose from 'mongoose';

const RatingSchema = new mongoose.Schema(
    {
        ratingID: { type: mongoose.Schema.Types.ObjectId, unique: true, default: () => new mongoose.Types.ObjectId() },
        customerID: { type: mongoose.Schema.Types.ObjectId, required: true, ref: 'Customer' },
        artistID: { type: mongoose.Schema.Types.ObjectId, required: true, ref: 'Artist' },
        serviceID: { type: mongoose.Schema.Types.ObjectId, required: true, ref: 'Service' },
        rating: { type: Number, required: true, min: 1, max: 5 }, 
    },
    { timestamps: true }
);

const RatingModel = mongoose.model('Rating', RatingSchema);
export { RatingModel };