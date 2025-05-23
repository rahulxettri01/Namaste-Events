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

// Add this new function for vendor OTP emails
const sendVendorOTPEmail = async (email, vendorName, otp, subject = 'Namaste Events - Vendor Password Reset OTP') => {
    try {
        const mailOptions = {
            from: `Namaste Events <${process.env.EMAIL_USER}>`,
            to: email,
            subject: subject,
            html: `
                <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto; padding: 20px; border: 1px solid #e0e0e0; border-radius: 5px;">
                    <div style="text-align: center; margin-bottom: 20px;">
                        <h2 style="color: #333;">Namaste Events</h2>
                        <p style="color: #777; font-style: italic;">"Turning Plans into Perfect Moments!"</p>
                    </div>
                    <div style="padding: 20px; background-color: #f9f9f9; border-radius: 5px;">
                        <h3 style="color: #333;">Password Reset Request</h3>
                        <p>Dear ${vendorName || 'Vendor'},</p>
                        <p>We received a request to reset your password for your vendor account at Namaste Events.</p>
                        <p>Your OTP for password reset is:</p>
                        <div style="text-align: center; margin: 20px 0; padding: 15px; background-color: #f0f0f0; border-radius: 5px; font-size: 24px; font-weight: bold; letter-spacing: 5px;">
                            ${otp}
                        </div>
                        <p>This OTP will expire in 10 minutes.</p>
                        <p>If you did not request a password reset, please ignore this email or contact our support team if you have concerns.</p>
                        <p>Thank you,<br>Namaste Events Team</p>
                    </div>
                    <div style="text-align: center; margin-top: 20px; color: #777; font-size: 12px;">
                        <p>© ${new Date().getFullYear()} Namaste Events. All rights reserved.</p>
                    </div>
                </div>
            `
        };

        await transporter.sendMail(mailOptions);
        console.log('Vendor OTP email sent to:', email);
        return true;
    } catch (error) {
        console.error('Error sending vendor OTP email:', error);
        throw error;
    }
};

// Add this new function for vendor password reset confirmation emails
const sendVendorPasswordResetConfirmationEmail = async (email, vendorName) => {
    try {
        const mailOptions = {
            from: `Namaste Events <${process.env.EMAIL_USER}>`,
            to: email,
            subject: 'Password Reset Confirmation - Namaste Events Vendor Portal',
            html: `
                <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto; padding: 20px; border: 1px solid #e0e0e0; border-radius: 5px;">
                    <div style="text-align: center; margin-bottom: 20px;">
                        <h2 style="color: #333;">Namaste Events</h2>
                        <p style="color: #777; font-style: italic;">"Turning Plans into Perfect Moments!"</p>
                    </div>
                    <div style="padding: 20px; background-color: #f9f9f9; border-radius: 5px;">
                        <h3 style="color: #333;">Password Reset Successful</h3>
                        <p>Dear ${vendorName || 'Vendor'},</p>
                        <p>Your password for Namaste Events vendor account has been successfully reset.</p>
                        <p>If you did not make this change, please contact our support team immediately as your account may have been compromised.</p>
                        <div style="text-align: center; margin: 30px 0;">
                            <a href="${process.env.FRONTEND_URL || 'http://localhost:3000'}/vendor/login" 
                               style="background-color: #000; color: #fff; padding: 12px 24px; text-decoration: none; border-radius: 5px; font-weight: bold;">
                              Login to Your Account
                            </a>
                        </div>
                        <p>Thank you,<br>Namaste Events Team</p>
                    </div>
                    <div style="text-align: center; margin-top: 20px; color: #777; font-size: 12px;">
                        <p>© ${new Date().getFullYear()} Namaste Events. All rights reserved.</p>
                    </div>
                </div>
            `
        };

        await transporter.sendMail(mailOptions);
        console.log('Vendor password reset confirmation email sent to:', email);
        return { success: true, message: 'Vendor password reset confirmation email sent successfully' };
    } catch (error) {
        console.error('Error sending vendor password reset confirmation email:', error);
        return { success: false, message: 'Failed to send vendor password reset confirmation email' };
    }
};

// Add this new function for password reset confirmation emails
const sendPasswordResetConfirmationEmail = async (email) => {
    try {
        const mailOptions = {
            from: `Namaste Events <${process.env.EMAIL_USER}>`,
            to: email,
            subject: 'Password Reset Confirmation - Namaste Events',
            html: `
                <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto; padding: 20px; border: 1px solid #e0e0e0; border-radius: 5px;">
                    <h2 style="color: #4a4a4a;">Password Reset Confirmation</h2>
                    <p>Dear User,</p>
                    <p>Your password has been successfully reset. If you did not perform this action, please contact our support team immediately.</p>
                    <p>Thank you for using Namaste Events!</p>
                    <p style="margin-top: 30px; font-size: 12px; color: #888;">This is an automated email. Please do not reply.</p>
                </div>
            `
        };

        await transporter.sendMail(mailOptions);
        console.log('Password reset confirmation email sent to:', email);
        return { success: true, message: 'Password reset confirmation email sent successfully' };
    } catch (error) {
        console.error('Error sending password reset confirmation email:', error);
        return { success: false, message: 'Failed to send password reset confirmation email' };
    }
};

module.exports = { 
    sendMail,
    sendOTPEmail,
    sendVendorOTPEmail,  // Add this to the exports
    sendPasswordResetConfirmationEmail,
    sendVendorPasswordResetConfirmationEmail  // Add this to the exports
};
