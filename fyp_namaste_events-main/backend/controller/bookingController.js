import dotenv from 'dotenv';
import BookingModel from '../model/Booking.js';
import mongoose from 'mongoose';
// Add these imports for notification functionality
import { createNotification, sendBookingNotification, scheduleReminderNotifications } from './notificationController.js';
import BookingNotificationMail from '../mails/notification/bookingNotification.js';

dotenv.config();
const isValidObjectId = (id) => mongoose.Types.ObjectId.isValid(id);
// Controller functions

export const getAllBookingsForArtist = async (req, res) => {
  const artistId = req.params.artistId;
  try {
    let data = await BookingModel.find({ artistID: artistId, status: 'active' })
      .populate('customerID')
      .populate('serviceID')
      .populate('availabilityID');
    res.status(200).send({ Bookings: data });
  } catch (err) {
    console.error('Error fetching bookings for artist:', err.message || err);
    res.status(500).send({ error: 'An error occurred while fetching bookings for the artist', details: err.message });
  }
};

export const getBookingsForCustomer = async (req, res) => {
  const customerId = req.params.customerId;
  try {
    let data = await BookingModel.find({ customerID: customerId, status: 'active' })
      .populate('artistID')
      .populate('serviceID')
      .populate('availabilityID');
    res.status(200).send({ Bookings: data });
  } catch (err) {
    console.error('Error fetching bookings for customer:', err.message || err);
    res.status(500).send({ error: 'An error occurred while fetching bookings for the customer', details: err.message });
  }
};

export const getCanceledBookingsForCustomer = async (req, res) => {
  const customerId = req.params.customerId;
  try {
    let data = await BookingModel.find({ customerID: customerId, status: 'canceled' })
      .populate('artistID')
      .populate('serviceID')
      .populate('availabilityID');
    res.status(200).send({ Bookings: data });
  } catch (err) {
    console.error('Error fetching canceled bookings for customer:', err.message || err);
    res.status(500).send({ error: 'An error occurred while fetching canceled bookings for the customer', details: err.message });
  }
};

export const getAllBookings = async (req, res) => {
  try {
    let data = await BookingModel.find({}).populate('customerID serviceID availabilityID');
      res.status(200).send({ Bookings: data });
  } catch (err) {
    console.error('Error fetching all bookings:', err.message || err);
    res.status(500).send({ error: 'An error occurred while fetching all bookings', details: err.message });
  }
};

export const getAvailableSlots = async (req, res) => {
  const { artistId, date } = req.query;
  try {
    const existingBookings = await BookingModel.find({ artistId, date, status: 'active' });

    const allSlots = [
      '09:00', '10:00', '11:00', '12:00',
      '13:00', '14:00', '15:00', '16:00',
      '17:00', '18:00'
    ];

    const bookedSlots = existingBookings.map(booking => booking.startTime);
    const availableSlots = allSlots.filter(slot => !bookedSlots.includes(slot));

    res.status(200).send({ availableSlots });
  } catch (err) {
    console.error('Error fetching available slots:', err.message || err);
    res.status(500).send({ error: 'An error occurred while fetching available slots', details: err.message });
  }
};

export const createBooking = async (req, res) => {
  const { customerID, availabilityID, serviceID, artistID, price, paymentMethod } = req.body;

  console.log('Received booking data:', req.body);

  if (!customerID || !artistID) {
    return res.status(400).send({ error: 'Customer ID and Artist ID cannot be empty' });
  }

  try {
    const booking = new BookingModel({
      customerID,
      availabilityID,
      serviceID,
      artistID,
      price,
      paymentMethod,
    });

    await booking.save();
    
    // Send notifications after booking is created
    try {
      // Send in-app notifications and emails
      await sendBookingNotification(booking._id);
      
      // Schedule reminder notifications
      await scheduleReminderNotifications(booking._id);
    } catch (notificationError) {
      console.error('Error sending notifications:', notificationError);
      // Continue with the response even if notifications fail
    }
    
    res.status(201).send({ bookingID: booking._id });
  } catch (error) {
    console.error('Error during booking creation:', error.message || error);
    res.status(500).send({ error: 'An error occurred while booking the service', details: error.message });
  }
};

export const updateBooking = async (req, res) => {
  const ID = req.params.id;
  const payload = req.body;
  try {
    const updatedBooking = await BookingModel.findByIdAndUpdate(ID, payload, { new: true });
    
    // If booking status changed to confirmed, send notification
    if (payload.bookingStatus === 'Confirmed') {
      try {
        await createNotification(
          updatedBooking.customerID,
          'Customer',
          'Booking Confirmed',
          `Your booking has been confirmed`,
          'booking',
          { model: 'Booking', id: updatedBooking._id }
        );
        
        // Send email notification
        const booking = await BookingModel.findById(ID)
          .populate('customerID')
          .populate('serviceID');
          
        if (booking.customerID.email) {
          const customerMail = new BookingNotificationMail({
            to: booking.customerID.email
          }, {
            user: booking.customerID,
            booking: booking,
            message: `Your booking for ${booking.serviceID.name} has been confirmed`
          });
          customerMail.send();
        }
      } catch (notificationError) {
        console.error('Error sending confirmation notification:', notificationError);
      }
    }
    
    res.send({ message: 'Booking modified' });
  } catch (err) {
    console.error('Error updating booking:', err.message || err);
    res.status(500).send({ error: 'An error occurred while updating the booking', details: err.message });
  }
};

export const deleteBooking = async (req, res) => {
  const ID = req.params.id;
  try {
    const booking = await BookingModel.findByIdAndUpdate(ID, { status: 'canceled' }, { new: true });
    if (!booking) {
      return res.status(404).send({ error: 'Booking not found' });
    }
    
    // Send cancellation notification
    try {
      // Get full booking details
      const fullBooking = await BookingModel.findById(ID)
        .populate('customerID')
        .populate('artistID')
        .populate('serviceID');
      
      // Notify artist
      await createNotification(
        booking.artistID,
        'Artist',
        'Booking Canceled',
        `A booking has been canceled`,
        'booking',
        { model: 'Booking', id: booking._id }
      );
      
      // Send email to artist
      if (fullBooking.artistID.email) {
        const artistMail = new BookingNotificationMail({
          to: fullBooking.artistID.email
        }, {
          user: fullBooking.artistID,
          booking: fullBooking,
          message: `A booking for ${fullBooking.serviceID.name} has been canceled`
        });
        artistMail.send();
      }
    } catch (notificationError) {
      console.error('Error sending cancellation notification:', notificationError);
    }
    
    res.send({ message: 'Booking has been canceled' });
  } catch (err) {
    console.error('Error canceling booking:', err.message || err);
    res.status(500).send({ error: 'An error occurred while canceling the booking', details: err.message });
  }
};