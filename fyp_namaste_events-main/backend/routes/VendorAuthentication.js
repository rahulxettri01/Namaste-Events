const express = require("express");
const router = express.Router();
const http = require("http");
const axios = require("axios");
const { vendorModel } = require("../models/vendor");
const { connectInventoryDB, connectVendorDB } = require("../Config/DBconfig");
const encrypt = require("bcrypt");
const jwt = require("jsonwebtoken");
const {
  uploadVendor,
  uploadUser,
  uploadInventory,
} = require("../Config/multerConfig");
const { diskStorage } = require("multer");
const VerifyJWT = require("../middleware/VerifyJWT");
const { Ruleset } = require("firebase-admin/security-rules");
const jwtExpiryMinute = 60;
const {
  docImageModel,
  photographyImageModel,
  venueImageModel,
  decorationImageModel,
} = require("../models/image");

const vendorData = [];
// POST API to add vendor signup details
router.post("/sign_up", async (req, res) => {
  const vdata = {
    vendorName: req.body.vendorName,
    email: req.body.email,
    phone: req.body.phone,
    password: req.body.password,
  };

  let duplicateEmail = null;
  await connectInventoryDB(async () => {
    duplicateEmail = await vendorModel.findOne({ email: vdata.email });
  });

  if (duplicateEmail) {
    return res.status(400).json({
      status_code: 400,
      message: "Vendor already exists. Please login",
    });
  } else {
    try {
      const salt = await encrypt.genSalt(10);
      const passwordEncrypted = await encrypt.hash(vdata.password, salt);
      let newVendor = new vendorModel({
        vendorName: vdata.vendorName,
        email: vdata.email,
        phone: vdata.phone,
        password: passwordEncrypted,
      });

      await connectInventoryDB(async () => {
        await newVendor.save().then(() => {
          res.status(200).send({
            status_code: 200,
            message: "Vendor registered successfully",
            vendorDetails: vdata,
          });
        });
      });
    } catch (err) {
      return res.status(400).json({ message: err.message });
    }
  }
});

// POST API to login vendor
router.post("/login", async (req, res) => {
  const vdata = {
    email: req.body.email,
    password: req.body.password,
  };

  let existEmail = null;

  connectInventoryDB(async () => {
    existEmail = await vendorModel.findOne({ email: vdata.email });
  });
  if (!existEmail) {
    return res.status(400).json({
      status_code: 400,
      message: "Vendor doesn't exist. Please sign up",
    });
  } else {
    try {
      const correctPassword = await encrypt.compare(
        vdata.password,
        existEmail.password
      );
      if (!correctPassword) {
        return res
          .status(400)
          .json({ status_code: 400, message: "Incorrect email or password" });
      }

      const token = jwt.sign({ id: existEmail._id, role: "Admin" }, "SECRET");
      res.cookie("token", token, {
        httpOnly: true,
        secure: process.env.NODE_ENV !== "development",
        sameSite: "strict",
        maxAge: jwtExpiryMinute * 30,
      });

      return res.status(200).send({
        status_code: 200,
        message: "Vendor logged in successfully",
        role: "Admin",
      });
    } catch (err) {
      return res.status(400).json({ message: err.message });
    }
  }
});

// router.post("/upload", upload.array("files"), async (req, res) => {
//   console.log("file uploaded");
// });
router.post(
  "/vendorAuth/upload",
  VerifyJWT,
  uploadVendor.array("files"),
  async (req, res) => {
    // diskStorage.name;

    console.log("file ");
    if (!req.imageStatus) {
      return res.status(400).json({
        status_code: 400,
        message: "Image upload failed",
      });
    } else {
      res.status(200).send({
        status_code: 200,
        message: "File uploaded successfully",
      });
    }
  }
);
router.post("/update_vendor_status", VerifyJWT, (req, res) => {
  console.log("aaaa");
  const { id, status } = req.body;

  console.log("new hit");

  connectInventoryDB(async () => {
    try {
      const vendor = await vendorModel.findByIdAndUpdate(
        id,
        { status: status },
        { new: true }
      );

      if (!vendor) {
        return res.status(404).json({
          status_code: 404,
          message: "Vendor not found",
        });
      }

      res.status(200).send({
        status_code: 200,
        message: "Vendor status updated successfully",
        vendor,
      });
    } catch (err) {
      return res.status(400).json({ message: err.message });
    }
  });
});
// GET API to fetch verification images for a vendor
router.post("/get_verification_images", VerifyJWT, async (req, res) => {
  console.log("hit at /vendor/auth/get_verification_images");
  
  const { email, type } = req.body;

  if (!email) {
    return res.status(400).json({
      status_code: 400,
      message: "Email is required",
    });
  }

  console.log("type", type);

  try {
    let images = [];
    if (type === "verification") {
      console.log("email", email);
      console.log("type", req.user);

      await connectInventoryDB(async () => {
        images = await docImageModel.find({
          srcFrom: email,
        });
      });
    } else if (type === "inventory") {
      console.log("in inventory");

      if (req.user.category === "Venue") {
        await connectInventoryDB(async () => {
          images = await venueImageModel.find({
            srcFrom: email,
            type: "venue",
          });
        });
      } else if (req.user.category === "Photography") {
        console.log("in Photo", email, type);
        await connectInventoryDB(async () => {
          images = await photographyImageModel.find({
            srcFrom: email,
            type: "photography",
          });
        });
      } else {
        await connectInventoryDB(async () => {
          images = await decorationImageModel.find({
            srcFrom: email,
            type: "decoration",
          });
        });
      }
    }

    console.log("images", images);

    // Transform images to include full URLs
    const transformedImages = images.map((img) => {
      // Determine the correct path based on image type
      // let imagePath = "vendor";
      let imagePath = img.filePath;
      // if (type === "inventory") {
      //   imagePath = "uploads/inventory";
      // } else if (type === "venue" || type === "decoration") {
      //   imagePath = type;
      // }

      return {
        ...img.toObject(),
        fullUrl: `${req.protocol}://${req.get("host")}/${imagePath}/${
          img.fileName
        }`,
        type: img.type || type,
        uploadDate: img.createdAt || new Date(),
      };
    });
    console.log("transformedImages", transformedImages);

    // In the get_verification_images endpoint
    if (type === "inventory") {
      if (req.user.category === "Decoration") {
        // Extract the folder name from the first image's filePath if available
        if (images.length > 0 && images[0].filePath) {
          const folderPath = images[0].filePath;
          // The filePath format is typically "uploads/inventory/folderName"
          const folderName = folderPath.split("/").pop();

          try {
            let resp = await axios.post(
              `http://${req.get("host")}/vendor/get_inventory_files`,
              {
                folderName: folderName,
              }
            );
            console.log("Inventory files response:", resp.data);

            // If successful, use the file details from the response
            if (resp.data && resp.data.status_code === 200) {
              return res.status(200).json({
                status_code: 200,
                message: "Images fetched successfully",
                data: resp.data.data,
                folderPath: resp.data.folderPath,
              });
            }
          } catch (error) {
            console.error("Error fetching inventory files:", error);
            // Continue with normal flow if there's an error
          }
        }
      } else if (req.user.category === "Photography") {
        // Extract the folder name from the first image's filePath if available
        if (images.length > 0 && images[0].filePath) {
          const folderPath = images[0].filePath;
          // The filePath format is typically "uploads/inventory/folderName"
          const folderName = folderPath.split("/").pop();

          try {
            let resp = await axios.post(
              `http://${req.get("host")}/vendor/get_inventory_files`,
              {
                folderName: folderName,
              }
            );
            if (resp.data && resp.data.status_code === 200) {
              return res.status(200).json({
                status_code: 200,
                message: "Images fetched successfully",
                data: resp.data.data,
                folderPath: resp.data.folderPath,
              });
            }
          } catch (error) {
            console.error("Error fetching inventory files:", error);
            // Continue with normal flow if there's an error
          }
        }
      } else if (req.user.category === "Venue") {
        // Extract the folder name from the first image's filePath if available
        if (images.length > 0 && images[0].filePath) {
          const folderPath = images[0].filePath;
          // The filePath format is typically "uploads/inventory/folderName"
          const folderName = folderPath.split("/").pop();

          try {
            let resp = await axios.post(
              `http://${req.get("host")}/vendor/get_inventory_files`,
              {
                folderName: folderName,
              }
            );
            if (resp.data && resp.data.status_code === 200) {
              return res.status(200).json({
                status_code: 200,
                message: "Images fetched successfully",
                data: resp.data.data,
                folderPath: resp.data.folderPath,
              });
            }
          } catch (error) {
            console.error("Error fetching inventory files:", error);
            // Continue with normal flow if there's an error
          }
        }
      }
    } else if (type === "verification") {
      // Extract the folder name from the first image's filePath if available
      if (images.length > 0 && images[0].filePath) {
        const folderPath = images[0].filePath;
        // The filePath format is typically "uploads/inventory/folderName"
        const folderName = folderPath.split("/").pop();
        console.log("folderName", folderName);

        try {
          console.log(
            "uurrll",
            `http://${req.get("host")}/vendor/get_inventory_files`
          );

          let resp = await axios.post(
            `http://${req.get("host")}/vendor/get_inventory_files`,
            {
              folderName: folderName,
            }
          );
          console.log("Inventory files response:", resp.data);

          if (resp.data && resp.data.status_code === 200) {
            return res.status(200).json({
              status_code: 200,
              message: "Images fetched successfully",
              data: resp.data.data,
              folderPath: resp.data.folderPath,
            });
          }
        } catch (error) {
          console.error("Error fetching inventory files:", error);
          // Continue with normal flow if there's an error
        }
      }
    }

    return res.status(200).json({
      status_code: 200,
      message: "Images fetched successfully",
      data: transformedImages,
    });
  } catch (err) {
    console.error("Error fetching verification images:", err);
    return res.status(500).json({
      status_code: 500,
      message: err.message,
    });
  }
});

// New endpoint to serve images directly
const path = require("path");
const fs = require("fs");
const { log } = require("console");

router.get("/image/:filename", async (req, res) => {
  try {
    const filename = req.params.filename;
    const imagePath = path.join(__dirname, "../uploads/vendor", filename);

    // Check if file exists
    if (fs.existsSync(imagePath)) {
      return res.sendFile(imagePath);
    } else {
      return res.status(404).json({
        status_code: 404,
        message: "Image not found",
      });
    }
  } catch (err) {
    console.error("Error serving image:", err);
    return res.status(500).json({
      status_code: 500,
      message: err.message,
    });
  }
});

router.post(
  "/upload_inventory_images",
  VerifyJWT,
  uploadInventory.array("files"),
  async (req, res) => {
    const { type, inventoryName, address, price, description, accommodation } =
      req.body;

    // console.log("inventory upload details", req.user);
    const data = req.user;
    console.log("data", data);
    console.log("data", req.imageStatus);

    if (!req.imageStatus) {
      return res.status(400).json({
        status_code: 400,
        message: "Image upload failed",
      });
    }

    // req.get({
    //   url: `${process.env.BASE_URL}/api/add_inventory`,
    //   method: "POST",
    //   headers: req.headers,
    // });
    console.log(`${process.env.BASE_URL}/api/add_inventory`);

    res.redirect(`${process.env.BASE_URL}/api/add_inventory`);
  }
);

// New endpoint to get all files in a specific inventory folder
router.post("/get_inventory_files", async (req, res) => {
  console.log("hit at get_inventory_files");

  try {
    const { folderName } = req.body;
    console.log("hiinventory_files", folderName);

    if (!folderName) {
      return res.status(400).json({
        status_code: 400,
        message: "Folder name is required",
      });
    }

    const inventoryFolderPath = path.join(
      __dirname,
      "../uploads/inventory",
      folderName
    );

    // Check if directory exists
    if (!fs.existsSync(inventoryFolderPath)) {
      return res.status(404).json({
        status_code: 404,
        message: "Inventory folder not found",
      });
    }

    // Read all files in the directory
    fs.readdir(inventoryFolderPath, (err, files) => {
      if (err) {
        console.error("Error reading directory:", err);
        return res.status(500).json({
          status_code: 500,
          message: "Error reading inventory folder",
        });
      }

      // Transform files to include full URLs
      const fileDetails = files.map((fileName) => {
        return {
          fileName: fileName,
          fullUrl: `${req.protocol}://${req.get(
            "host"
          )}/uploads/inventory/${folderName}/${fileName}`,
          uploadDate: fs.statSync(path.join(inventoryFolderPath, fileName))
            .mtime,
        };
      });

      return res.status(200).json({
        status_code: 200,
        message: "Files retrieved successfully",
        data: fileDetails,
        folderPath: `/uploads/inventory/${folderName}`,
      });
    });
  } catch (err) {
    console.error("Error getting inventory files:", err);
    return res.status(500).json({
      status_code: 500,
      message: err.message,
    });
  }
});

// Alternative endpoint that gets files based on inventory ID or vendor email
router.post("/get_inventory_images", VerifyJWT, async (req, res) => {
  try {
    const { email, category, inventoryId } = req.body;

    if (!email || !category) {
      return res.status(400).json({
        status_code: 400,
        message: "Email and category are required",
      });
    }

    let images = [];

    // Find images based on category
    if (category === "Venue") {
      await connectInventoryDB(async () => {
        images = await venueImageModel.find({
          srcFrom: email,
          ...(inventoryId && { inventoryId }),
        });
      });
    } else if (category === "Photography") {
      await connectInventoryDB(async () => {
        images = await photographyImageModel.find({
          srcFrom: email,
          ...(inventoryId && { inventoryId }),
        });
      });
    } else if (category === "Decoration") {
      await connectInventoryDB(async () => {
        images = await decorationImageModel.find({
          srcFrom: email,
          ...(inventoryId && { inventoryId }),
        });
      });
    }
    console.log("imageddddddds", images);

    // Transform images to include full URLs
    const transformedImages = images.map((img) => {
      return {
        ...img.toObject(),
        fullUrl: `${req.protocol}://${req.get("host")}/${img.filePath}/${
          img.fileName
        }`,
        uploadDate: img._id.getTimestamp(),
      };
    });

    return res.status(200).json({
      status_code: 200,
      message: "Inventory images retrieved successfully",
      data: transformedImages,
    });
  } catch (err) {
    console.error("Error getting inventory images:", err);
    return res.status(500).json({
      status_code: 500,
      message: err.message,
    });
  }
});
// Route for vendor forgot password
router.post("/vendors/forgot-password", async (req, res) => {
  try {
    const { email } = req.body;
    
    // Check if vendor exists
    const vendor = await vendorModel.findOne({ email });
    if (!vendor) {
      return res.status(404).json({
        success: false,
        message: "Vendor not found with this email"
      });
    }
    
    // Generate OTP and send email
    // Your OTP generation and email sending logic here
    
    return res.status(200).json({
      success: true,
      vendorId: vendor._id,
      message: "OTP sent to your email"
    });
  } catch (error) {
    console.error("Error in forgot password:", error);
    return res.status(500).json({
      success: false,
      message: "Internal server error"
    });
  }
});
// Forgot password - check email and send OTP
router.post("/vendor/forgot-password", async (req, res) => {
  const { email } = req.body;
  
  if (!email) {
    return res.status(400).json({
      success: false,
      message: "Email is required"
    });
  }

  try {
    let vendor = null;
    await connectInventoryDB(async () => {
      vendor = await vendorModel.findOne({ email: email });
    });

    if (!vendor) {
      return res.status(404).json({
        success: false,
        message: "Vendor not found"
      });
    }

    // Generate a 6-digit OTP
    const otp = Math.floor(100000 + Math.random() * 900000).toString();
    const otpExpiry = new Date();
    otpExpiry.setMinutes(otpExpiry.getMinutes() + 10); // OTP valid for 10 minutes

    // Save OTP to vendor record
    await connectInventoryDB(async () => {
      await vendorModel.findByIdAndUpdate(vendor._id, {
        resetOTP: otp,
        resetOTPExpiry: otpExpiry
      });
    });

    // Send OTP via email
    try {
      await sendOTPEmail(email, otp, "Vendor Password Reset");
      console.log(`OTP sent to ${email}: ${otp}`);
    } catch (emailErr) {
      console.error("Error sending email:", emailErr);
      // Continue even if email fails
    }

    return res.status(200).json({
      success: true,
      vendorId: vendor._id,
      message: "OTP sent to your email",
      // Remove this in production
      otp: process.env.NODE_ENV === 'development' ? otp : undefined
    });
  } catch (err) {
    console.error("Error in forgot password:", err);
    return res.status(500).json({
      success: false,
      message: "Server error while processing request"
    });
  }
});

// Verify OTP
router.post("/verify-otp", async (req, res) => {
  const { email, otp } = req.body;
  
  if (!email || !otp) {
    return res.status(400).json({
      success: false,
      message: "Email and OTP are required"
    });
  }

  try {
    let vendor = null;
    await connectInventoryDB(async () => {
      vendor = await vendorModel.findOne({ email: email });
    });

    if (!vendor) {
      return res.status(404).json({
        success: false,
        message: "Vendor not found"
      });
    }

    // Check if OTP is valid and not expired
    if (vendor.resetOTP !== otp) {
      return res.status(400).json({
        success: false,
        message: "Invalid OTP"
      });
    }

    const now = new Date();
    if (now > vendor.resetOTPExpiry) {
      return res.status(400).json({
        success: false,
        message: "OTP has expired"
      });
    }

    // Generate a reset token
    const resetToken = jwt.sign(
      { id: vendor._id, purpose: 'reset_password' },
      'SECRET',
      { expiresIn: '15m' }
    );

    return res.status(200).json({
      success: true,
      vendorId: vendor._id,
      token: resetToken,
      message: "OTP verified successfully"
    });
  } catch (err) {
    console.error("Error verifying OTP:", err);
    return res.status(500).json({
      success: false,
      message: "Server error while verifying OTP"
    });
  }
});

// Reset password
router.post("/reset-password", async (req, res) => {
  const { vendorId, newPassword } = req.body;
  
  if (!vendorId || !newPassword) {
    return res.status(400).json({
      success: false,
      message: "Vendor ID and new password are required"
    });
  }

  try {
    // Verify the token from Authorization header
    const authHeader = req.headers.authorization;
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      return res.status(401).json({
        success: false,
        message: "Authorization token is required"
      });
    }

    const token = authHeader.split(' ')[1];
    let decoded;
    
    try {
      decoded = jwt.verify(token, 'SECRET');
      
      // Check if token is for password reset and matches the vendor ID
      if (decoded.purpose !== 'reset_password' || decoded.id !== vendorId) {
        return res.status(401).json({
          success: false,
          message: "Invalid or expired token"
        });
      }
    } catch (err) {
      return res.status(401).json({
        success: false,
        message: "Invalid or expired token"
      });
    }

    // Hash the new password
    const salt = await encrypt.genSalt(10);
    const hashedPassword = await encrypt.hash(newPassword, salt);

    // Update the password and clear reset fields
    let vendor = null;
    await connectInventoryDB(async () => {
      vendor = await vendorModel.findByIdAndUpdate(
        vendorId,
        {
          password: hashedPassword,
          resetOTP: null,
          resetOTPExpiry: null
        },
        { new: true }
      );
    });

    if (!vendor) {
      return res.status(404).json({
        success: false,
        message: "Vendor not found"
      });
    }

    return res.status(200).json({
      success: true,
      message: "Password reset successfully"
    });
  } catch (err) {
    console.error("Error resetting password:", err);
    return res.status(500).json({
      success: false,
      message: "Server error while resetting password"
    });
  }
});

// Check if vendor email exists
router.post("/vendors/check-email", async (req, res) => {
  const { email } = req.body;
  
  if (!email) {
    return res.status(400).json({
      success: false,
      message: "Email is required"
    });
  }

  try {
    let vendor = null;
    await connectInventoryDB(async () => {
      vendor = await vendorModel.findOne({ email: email });
    });

    if (vendor) {
      return res.status(200).json({
        success: true,
        exists: true,
        vendorId: vendor._id,
        message: "Vendor found"
      });
    } else {
      return res.status(200).json({
        success: true,
        exists: false,
        message: "Vendor not found"
      });
    }
  } catch (err) {
    console.error("Error checking vendor email:", err);
    return res.status(500).json({
      success: false,
      message: "Server error while checking email"
    });
  }
});

// Keep the existing /reset-password endpoint for backward compatibility
router.post("/reset-password", async (req, res) => {
  try {
    const { vendorId, newPassword } = req.body;
    
    if (!vendorId || !newPassword) {
      return res.status(400).json({
        success: false,
        message: "Vendor ID and new password are required"
      });
    }
    
    // Use connectInventoryDB instead of connectVendorDB if that's what you have
    await connectInventoryDB(async () => {
      // Find the vendor
      const vendor = await vendorModel.findById(vendorId);
      
      if (!vendor) {
        return res.status(404).json({
          success: false,
          message: "Vendor not found"
        });
      }
      
      // Hash the new password
      const salt = await encrypt.genSalt(10);
      const hashedPassword = await encrypt.hash(newPassword, salt);
      
      // Update the password
      vendor.password = hashedPassword;
      await vendor.save();
      
      return res.status(200).json({
        success: true,
        message: "Password reset successfully"
      });
    });
  } catch (error) {
    console.error("Error resetting password:", error);
    return res.status(500).json({
      success: false,
      message: "Error resetting password: " + error.message
    });
  }
});

// Add this near the top of your file with other imports
const { sendOTPEmail } = require('../utils/emailService');

// At the end of your VendorAuthentication.js file, add:
module.exports = router;
