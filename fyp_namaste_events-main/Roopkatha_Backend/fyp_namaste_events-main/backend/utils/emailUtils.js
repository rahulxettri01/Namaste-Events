// ... existing email setup code ...

const sendOTPEmail = async (email, otp, userName) => {
  try {
    const mailOptions = {
      from: `"Namaste Events" <${process.env.MAIL_USER}>`,
      to: email,
      subject: "Your Verification Code - Namaste Events",
      html: `
                <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
                    <div style="background-color: #f8f9fa; padding: 30px; border-radius: 10px;">
                        <h2 style="color: #333;">Hello ${userName},</h2>
                        <p style="font-size: 16px; color: #555;">
                            Your verification code for Namaste Events is:
                        </p>
                        <div style="background-color: #e9ecef; 
                                    padding: 15px; 
                                    margin: 20px 0; 
                                    text-align: center; 
                                    font-size: 24px; 
                                    letter-spacing: 5px;
                                    border-radius: 5px;">
                            ${otp}
                        </div>
                        <p style="font-size: 14px; color: #777;">
                            This code will expire in 30 minutes. If you didn't request this, please ignore this email.
                        </p>
                    </div>
                </div>
            `,
    };

    await transporter.sendMail(mailOptions);
  } catch (error) {
    console.error("Error sending OTP email:", error);
    throw error;
  }
};

module.exports = {
  sendOTPEmail,
  // ... other exports ...
};
