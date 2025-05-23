const express = require('express');
const router = express.Router();
const { sendMail } = require('../middleware/sendMail');

// Add route for password reset confirmation email
router.post('/send-password-reset-confirmation', async (req, res) => {
  try {
    const { email } = req.body;
    
    if (!email) {
      return res.status(400).json({
        success: false,
        message: 'Email is required'
      });
    }
    
    // Use the existing sendMail function from your middleware
    const emailSent = await sendMail(
      email,
      'Password Reset Confirmation - Namaste Events',
      'Your password has been successfully reset. If you did not perform this action, please contact our support team immediately.'
    );
    
    if (emailSent) {
      return res.status(200).json({
        success: true,
        message: 'Password reset confirmation email sent successfully'
      });
    } else {
      return res.status(500).json({
        success: false,
        message: 'Failed to send confirmation email'
      });
    }
  } catch (error) {
    console.error('Error in send-password-reset-confirmation endpoint:', error);
    return res.status(500).json({
      success: false,
      message: 'Server error while sending password reset confirmation email'
    });
  }
});

module.exports = router;