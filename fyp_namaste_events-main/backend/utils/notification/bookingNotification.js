import Mail from '../mail.cjs';

export default class BookingNotificationMail extends Mail {
    /**
     * Change your options here
     * * this.subject
     * * this.html
     * * this.other
     */
    prepare() {
        const userName = this.other.user && this.other.user.name ? this.other.user.name : 'User';
        const message = this.other.message || 'You have a notification regarding your booking.';
        const booking = this.other.booking || {};
        
        let bookingDetails = '';
        if (booking.serviceID && booking.availabilityID) {
            const service = booking.serviceID;
            const availability = booking.availabilityID;
            
            bookingDetails = `
            <div style="margin-top: 15px; padding: 10px; background-color: #f8f9fa; border-radius: 5px;">
                <p><strong>Service:</strong> ${service.name}</p>
                <p><strong>Date:</strong> ${new Date(availability.date).toLocaleDateString()}</p>
                <p><strong>Time:</strong> ${availability.startTime}</p>
                <p><strong>Price:</strong> Rs. ${booking.price/100}</p>
            </div>`;
        }

        this.subject = "Booking Notification - Roopkatha";
        this.html = `
        <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto; padding: 20px; border: 1px solid #e0e0e0; border-radius: 5px;">
            <h2 style="color: #4a4a4a; border-bottom: 1px solid #e0e0e0; padding-bottom: 10px;">Roopkatha Booking</h2>
            <p>Hi ${userName},</p>
            <p>${message}</p>
            ${bookingDetails}
            <p style="margin-top: 20px;">Thank you for using Roopkatha!</p>
            <div style="margin-top: 30px; padding-top: 10px; border-top: 1px solid #e0e0e0; color: #777; font-size: 12px;">
                <p>This is an automated message, please do not reply to this email.</p>
            </div>
        </div>
        `;
    }
}