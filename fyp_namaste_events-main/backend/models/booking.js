const mongoose = require("mongoose");

const bookingSchema = new mongoose.Schema({
    userId: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'User',
        required: true
    },
    vendorId: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'Vendor',
        required: true
    },
    inventoryId: {
        type: String,
        // required: true
    },
    
    price: {
        type: Number,
        required: true
    },
    paymentMethod: { 
        type: String, 
        default: 'Khalti',
        required: true 
    },
    bookingStatus: {
        type: String,
        enum: ['pending', 'completed', 'cancled', 'failed'],
        default: 'pending'
    },
    paymentStatus: {
        type: String,
        enum: ['pending', 'half-paid', 'full-paid', 'failed'],
        default: 'pending'
    },
    status: {
        type: String,
        enum: ['active', 'completed', 'canceled'],
        default: 'active'
    },
    paidAmount: {
        type: Number,
        default: 0
    },
    eventDetails: {
        eventType: {
            type: String,
            // enum: ['Venue', 'Decoration', 'Photography'],
            required: true
        },
        startDate: {
            type: Date,
            required: true
        },
        endDate: {
            type: Date,
            required: true
        },
        eventName: {
            type: String,
            // required: true
        },
        eventDescription: {
            type: String,
            
        },
        guestCount: {
            type: Number,
            required: true
        },
    },
    totalAmount: {
        type: Number,
        required: true
    }
}, { timestamps: true });

const bookingModel = mongoose.model('Bookings', bookingSchema);
module.exports = {bookingModel};