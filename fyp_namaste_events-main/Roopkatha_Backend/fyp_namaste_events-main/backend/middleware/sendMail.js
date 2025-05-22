const nodemailer = require('nodemailer');
require('dotenv').config();

const transporter = nodemailer.createTransport({
    service: 'gmail',
    host: 'smtp.gmail.com',
    port: 587,
    secure: false,
    auth: {
        user: process.env.EMAIL_USER,
        pass: process.env.EMAIL_PASSWORD
    },
    tls: {
        rejectUnauthorized: false
    }
});

const sendMail = async (to, subject, text) => {
    try {
        const mailOptions = {
            from: `Namaste Events <${process.env.EMAIL_USER}>`,
            to: to,
            subject: subject,
            html: `
                <div style="font-family: Arial, sans-serif; padding: 20px;">
                    <h2>${subject}</h2>
                    <p>${text}</p>
                </div>
            `
        };

        const info = await transporter.sendMail(mailOptions);
        console.log('Message sent: %s', info.messageId);
        return true;
    } catch (error) {
        console.error('Error sending email:', error);
        throw error; // Re-throw to handle in calling function
    }
};

const sendOTPEmail = async (email, userName, otp) => {
    try {
        const mailOptions = {
            from: `Namaste Events <${process.env.EMAIL_USER}>`,
            to: email,
            subject: 'Your OTP for Verification',
            html: `
                <div style="font-family: Arial, sans-serif; padding: 20px;">
                    <h2>OTP Verification</h2>
                    <p>Dear ${userName},</p>
                    <p>Your OTP for verification is:</p>
                    <div style="font-size: 24px; font-weight: bold; margin: 20px 0;">
                        ${otp}
                    </div>
                    <p>This OTP is valid for 30 minutes.</p>
                </div>
            `
        };

        await transporter.sendMail(mailOptions);
        console.log('OTP email sent to:', email);
        return true;
    } catch (error) {
        console.error('Error sending OTP email:', error);
        throw error;
    }
};

module.exports = { 
    sendMail,
    sendOTPEmail
};
