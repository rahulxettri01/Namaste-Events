import mongoose from 'mongoose';

const worksSchema = new mongoose.Schema({
    title: {
        type: String,
        required: [true, 'Title is required']
    },
    description: {
        type: String,
        required: [true, 'Description is required']
    },
    service: {
        type: String,
        required: [true, 'Service is required']
    },
    imageUrl: {
        type: String,
        required: [true, 'Image URL is required']
    },
    artistId: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'Artist',
        required: true
    }
}, {
    timestamps: true
});

const Works = mongoose.model('Works', worksSchema);

export default Works;

