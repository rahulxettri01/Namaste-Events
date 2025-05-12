const express = require("express");
const router = express.Router();
const { vendorModel } = require("../models/vendor");
const VerifyJWT = require("../middleware/VerifyJWT");
const { connectVendorDB } = require("../Config/DBconfig"); // This import is correct

// Endpoint to get vendors by status
router.get("/vendors/:status", async (req, res) => {
  const status = req.params.status;

  try {
    const vendors = await vendorModel.find({ status: status });
    res.status(200).json({ success: true, data: vendors });
  } catch (error) {
    res
      .status(500)
      .json({ success: false, message: "Server error", error: error.message });
  }
});

// Add this route to handle vendor profile image uploads
const multer = require('multer');
const path = require('path');
const fs = require('fs');

// Configure multer for profile image uploads
const profileStorage = multer.diskStorage({
  destination: function (req, file, cb) {
    const uploadDir = path.join(__dirname, '../uploads/vendor/profiles');
    
    // Create directory if it doesn't exist
    if (!fs.existsSync(uploadDir)) {
      fs.mkdirSync(uploadDir, { recursive: true });
    }
    
    cb(null, uploadDir);
  },
  filename: function (req, file, cb) {
    // Generate unique filename with timestamp and original extension
    const uniqueSuffix = Date.now() + '-' + Math.round(Math.random() * 1E9);
    const ext = path.extname(file.originalname);
    cb(null, 'profile-' + uniqueSuffix + ext);
  }
});

const uploadProfileImage = multer({ 
  storage: profileStorage,
  limits: { fileSize: 5 * 1024 * 1024 }, // 5MB limit
  fileFilter: function (req, file, cb) {
    // Accept only image files
    if (!file.originalname.match(/\.(jpg|jpeg|png|gif)$/)) {
      return cb(new Error('Only image files are allowed!'), false);
    }
    cb(null, true);
  }
}).single('profileImage');

// Route to handle profile image upload
router.post('/upload-profile-image', VerifyJWT, (req, res) => {
  uploadProfileImage(req, res, async function (err) {
    if (err instanceof multer.MulterError) {
      return res.status(400).json({ success: false, message: `Multer error: ${err.message}` });
    } else if (err) {
      return res.status(400).json({ success: false, message: err.message });
    }
    
    try {
      // Get the vendor ID from the request
      const { vendorId } = req.body;
      
      if (!vendorId) {
        return res.status(400).json({ success: false, message: 'Vendor ID is required' });
      }
      
      // Modified: Check if connectVendorDB is a function or a promise
      // If it's not a function, we'll skip calling it
      if (typeof connectVendorDB === 'function') {
        await connectVendorDB();
      } else {
        console.log("connectVendorDB is not a function, skipping database connection");
      }
      
      // Find the vendor and update the profile image
      const vendor = await vendorModel.findById(vendorId);
      
      if (!vendor) {
        return res.status(404).json({ success: false, message: 'Vendor not found' });
      }
      
      // If vendor already has a profile image, delete the old one
      if (vendor.profileImage) {
        const oldImagePath = path.join(__dirname, '../uploads/vendor/profiles', vendor.profileImage);
        if (fs.existsSync(oldImagePath)) {
          fs.unlinkSync(oldImagePath);
        }
      }
      
      // Update vendor with new profile image filename
      vendor.profileImage = req.file.filename;
      await vendor.save();
      
      // Return success response with image URL
      return res.status(200).json({
        success: true,
        message: 'Profile image uploaded successfully',
        imageUrl: req.file.filename
      });
    } catch (error) {
      console.error('Error updating vendor profile image:', error);
      return res.status(500).json({ success: false, message: `Server error: ${error.message}` });
    }
  });
});

// Add this test endpoint at the end of your vendor.js file before module.exports
router.get('/test', (req, res) => {
  res.status(200).json({ message: 'Vendor routes are working!' });
});

// Add this route to get vendor profile
// Modified route to get vendor profile with image URL instead of raw image data
router.get('/profile/:vendorId', async (req, res) => {
  try {
    const vendorId = req.params.vendorId;
    
    // Find the vendor by ID
    const vendor = await vendorModel.findById(vendorId);
    
    if (!vendor) {
      return res.status(404).json({ success: false, message: 'Vendor not found' });
    }
    
    // Create a vendor object without sensitive information
    const vendorData = {
      _id: vendor._id,
      vendorName: vendor.vendorName,
      email: vendor.email,
      phone: vendor.phone,
      role: vendor.role,
      status: vendor.status,
      category: vendor.category,
      profileImageUrl: vendor.profileImage ? `/uploads/vendor/profiles/${vendor.profileImage}` : null
    };
    
    // Return the vendor data with image URL instead of raw image
    return res.status(200).json({
      success: true,
      vendor: vendorData
    });
  } catch (error) {
    console.error('Error fetching vendor profile:', error);
    return res.status(500).json({ success: false, message: `Server error: ${error.message}` });
  }
});

// Add a route to get just the profile image
router.get('/profile-image/:vendorId', async (req, res) => {
  try {
    const vendorId = req.params.vendorId;
    
    // Find the vendor by ID
    const vendor = await vendorModel.findById(vendorId);
    
    if (!vendor || !vendor.profileImage) {
      return res.status(404).json({ success: false, message: 'Profile image not found' });
    }
    
    // Return just the image URL
    return res.status(200).json({
      success: true,
      imageUrl: `/uploads/vendor/profiles/${vendor.profileImage}`
    });
  } catch (error) {
    console.error('Error fetching profile image:', error);
    return res.status(500).json({ success: false, message: `Server error: ${error.message}` });
  }
});

module.exports = router;


