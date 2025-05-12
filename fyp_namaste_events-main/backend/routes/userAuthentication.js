const express = require("express");
const router = express.Router();
const { userModel } = require("../models/user");
const {
  vendorModel,
  photographyModel,
  venueModel,
  decoratorModel,
} = require("../models/vendor");
const {
  connectUserDB,
  connectInventoryDB,
  connectSuperAdminDB,
} = require("../Config/DBconfig");
const encrypt = require("bcrypt");
const jwt = require("jsonwebtoken");
const { sendMail, sendOTPEmail } = require("../middleware/sendMail");

const jwtExpiryMinute = 60;

const userData = [];

require("dotenv").config();

// POST API to add signup details
router.post("/sign_up", async (req, res) => {
  console.log("back auth hit");

  const udata = {
    userName: req.body.userName,
    email: req.body.email,
    phone: req.body.phone,
    password: req.body.password,
    role: req.body.role,
    category: req.body.vendorType ? req.body.vendorType : "user",
  };

  userData.push(udata);
  console.log("Endpoint dhit", udata);
  let duplicateEmail = null;
  if (udata.role == "Admin") {
    await connectInventoryDB(async () => {
      duplicateEmail = await vendorModel.findOne({ email: udata.email });
    });
  } else if (udata.role == "super Admin") {
    await connectSuperAdminDB(async () => {
      duplicateEmail = await userModel.findOne({ email: udata.email });
    });
  } else {
    await connectUserDB(async () => {
      duplicateEmail = await userModel.findOne({ email: udata.email });
    });
  }
  console.log("dub", duplicateEmail);
  if (duplicateEmail) {
    return res.status(400).json({
      status_code: 400,
      message: "User already exists. Please login",
    });
  } else {
    try {
      console.log("asd", udata);
      const salt = await encrypt.genSalt(10);
      const passwordEncrypted = await encrypt.hash(udata.password, salt);
      console.log("suc", passwordEncrypted);
      console.log("rol", udata.role);
      if (udata.role == "Vendor") {
        let newVendor;
        let vendorType;
        newVendor = new vendorModel({
          vendorName: udata.userName,
          email: udata.email,
          phone: udata.phone,
          password: passwordEncrypted,
          role: udata.role,
          citizenshipFilePath: "",
          panFilePath: "",
          category: udata.category,
        });
        // if (udata.category == "Venue") {
        //   vendorType = new venueModel({
        //     venueName: udata.userName,
        //     address: udata.address,
        //     price: udata.price,
        //     description: udata.description,
        //     accommodation: udata.accommodation,
        //     status: udata.status,
        //   });
        // } else if (udata.category == "Photography") {
        //   vendorType = new photographyModel({
        //     photographyName: udata.photographyName,
        //     address: udata.address,
        //     price: udata.price,
        //     description: udata.description,
        //     accommodation: udata.accommodation,
        //     status: udata.status,
        //   });
        // } else {
        //   vendorType = new decoratorModel({
        //     decoratorName: udata.decoratorName,
        //     address: udata.address,
        //     price: udata.price,
        //     description: udata.description,
        //     accommodation: udata.accommodation,
        //     status: udata.status,
        //   });
        // }
        console.log("modl", newVendor);

        await connectInventoryDB(async () => {
          // await vendorType.save();
          await newVendor.save().then(() => {
            console.log("succeded");

            res.status(200).send({
              status_code: 200,
              message: "Vendor registered successfully",
              userDetails: udata,
            });
          });
        });
      } else {
        // Add this helper function
        const generateOTP = () => {
          return Math.floor(100000 + Math.random() * 900000).toString();
        };
        let newUser = new userModel({
          userName: udata.userName,
          email: udata.email,
          phone: udata.phone,
          password: passwordEncrypted,
          role: udata.role,
          status: "unverified", // Add this field
          otp: generateOTP(), // Generate and store OTP
          otpExpires: new Date(Date.now() + 30 * 60 * 1000), // 30 minutes expiry
        });

        try {
          // Save user first
          await connectUserDB(async () => {
            await newUser.save();
          });

          // Send OTP email
          try {
            await sendOTPEmail(newUser.email, newUser.userName, newUser.otp);
          } catch (emailError) {
            console.error("OTP email failed:", emailError);
            // Continue even if email fails
          }

          // In your sign_up route response:
          res.status(200).send({
            status_code: 200,
            message: "User registered successfully. OTP sent for verification.",
            userDetails: udata,
            userId: newUser._id.toString(), // Ensure this is included
          });
        } catch (err) {
          return res.status(400).json({
            status_code: 400,
            message: err.message,
          });
        }
      }

      // try {
      //   // Save user first
      //   await connectUserDB(async () => {
      //     await newUser.save();
      //   });

      //   // Then send email
      //   try {
      //     await sendMail(
      //       newUser.email,
      //       "Welcome to Namaste Events",
      //       `Dear ${newUser.userName}, your account was created successfully!`
      //     );
      //   } catch (emailError) {
      //     console.error("Email failed but user created:", emailError);
      //     // Continue even if email fails
      //   }

      //   res.status(200).send({
      //     status_code: 200,
      //     message: "User registered successfully",
      //     userDetails: udata,
      //   });
      // } catch (err) {
      //   return res.status(400).json({
      //     status_code: 400,
      //     message: err.message,
      //   });
      // }
    } catch (err) {
      return res.status(400).json({ message: err.message });
    }
  }
});

router.post("/log_in", async (req, res) => {
  console.log("back auth hit");

  const udata = {
    email: req.body.email,
    password: req.body.password,
    role: req.body.role,
  };

  userData.push(udata);
  console.log("Endpoint hit", udata);

  let existEmail = null;
  if (udata.role == "Vendor") {
    console.log("vend");
    
    await connectInventoryDB(async () => {
      existEmail = await vendorModel.findOne({ email: udata.email });
    });
    await console.log("new", existEmail);
  } else if (udata.role == "super admin") {
    await connectSuperAdminDB(async () => {
      existEmail = await userModel.findOne({ email: udata.email });
    });
  } else {
    await connectUserDB(async () => {
      existEmail = await userModel.findOne({ email: udata.email });
    });
  }

  console.log("dubeee", existEmail);
  if (!existEmail) {
    return res.status(400).json({
      status_code: 400,
      message: "User doesn't exist. Please sign up",
    });
  } else {
    try {
      const correctPassword = await encrypt.compare(
        udata.password,
        existEmail.password
      );

      if (!correctPassword) {
        console.log("inc pas");
        return res
          .status(400)
          .json({ status_code: 400, message: "Incorrect email or password" });
      }
      console.log("user login role", existEmail.role);
      const token = jwt.sign(
        {
          id: existEmail._id,
          email: existEmail.email,
          role: existEmail.role,
          status: existEmail.status,
          category: existEmail.category,
        },
        "SECRET"
      );

      if (existEmail.role == "User") {
        console.log("c pas u");
        return res.status(200).send({
          status_code: 200,
          message: "User logged in successfully",
          role: existEmail.role,
          status: existEmail.status,
          userId: existEmail._id.toString(), // Ensure this is included
          email: existEmail.email,
          token: token,
        });
      } else if (existEmail.role == "Vendor") {
        console.log("c pas V");
        return res.status(200).send({
          status_code: 200,
          message: "Vendor logged in successfully",
          role: existEmail.role,
          token: token,
        });
        console.log("c pas A");
        return res.status(200).send({
          status_code: 200,
          message: "Admin logged in successfully",
          role: existEmail.role,
          token: token,
        });
      } else if (existEmail.role == "super admin") {
        console.log("c pas SA");
        return res.status(200).send({
          status_code: 200,
          message: "Super Admin logged in successfully",
          role: existEmail.role,
          token: token,
        });
      }
    } catch (err) {
      console.log("err mai");
      console.log(err);
      return res.status(400).json({ message: err.message });
    }
  }
});

// Add these routes after your existing routes

// Get vendor profile by ID
router.get("/vendors/:vendorId", async (req, res) => {
  try {
    const { vendorId } = req.params;
    const token = req.headers.authorization?.split(" ")[1];

    if (!token) {
      return res.status(401).json({
        success: false,
        message: "Authorization token required",
      });
    }

    // Verify token
    const decoded = jwt.verify(token, "SECRET");

    // Fetch vendor data
    let vendor;
    await connectInventoryDB(async () => {
      vendor = await vendorModel.findById(vendorId);
    });

    if (!vendor) {
      return res.status(404).json({
        success: false,
        message: "Vendor not found",
      });
    }

    // Return vendor profile data
    res.status(200).json({
      success: true,
      vendor: {
        _id: vendor._id,
        vendorName: vendor.vendorName,
        email: vendor.email,
        phone: vendor.phone,
        address: vendor.address,
        businessName: vendor.businessName,
        vendorType: vendor.category,
        status: vendor.status,
        isVerified: vendor.isVerified,
        createdAt: vendor.createdAt,
      },
    });
  } catch (error) {
    console.error("Vendor profile fetch error:", error);
    if (error.name === "JsonWebTokenError") {
      return res.status(401).json({
        success: false,
        message: "Invalid token",
      });
    }
    res.status(500).json({
      success: false,
      message: "Error fetching vendor profile: " + error.message,
    });
  }
});

// Update vendor profile
router.put("/vendors/update/:vendorId", async (req, res) => {
  try {
    const { vendorId } = req.params;
    const token = req.headers.authorization?.split(" ")[1];
    
    if (!token) {
      return res.status(401).json({
        success: false,
        message: "Authorization token required",
      });
    }

    // Verify token
    const decoded = jwt.verify(token, "SECRET");
    
    // Check if the user is authorized to update this vendor
    if (decoded.id !== vendorId && decoded.role !== "super admin") {
      return res.status(403).json({
        success: false,
        message: "Unauthorized to update this vendor profile",
      });
    }

    const updateData = {
      vendorName: req.body.vendorName,
      phone: req.body.phone,
      address: req.body.address,
      businessName: req.body.businessName,
    };

    // Update vendor data
    let updatedVendor;
    await connectInventoryDB(async () => {
      updatedVendor = await vendorModel.findByIdAndUpdate(
        vendorId,
        updateData,
        { new: true }
      );
    });

    if (!updatedVendor) {
      return res.status(404).json({
        success: false,
        message: "Vendor not found",
      });
    }

    // Return updated vendor data
    res.status(200).json({
      success: true,
      message: "Vendor profile updated successfully",
      vendor: {
        _id: updatedVendor._id,
        vendorName: updatedVendor.vendorName,
        email: updatedVendor.email,
        phone: updatedVendor.phone,
        address: updatedVendor.address,
        businessName: updatedVendor.businessName,
        vendorType: updatedVendor.category,
      },
    });
  } catch (error) {
    console.error("Vendor profile update error:", error);
    if (error.name === "JsonWebTokenError") {
      return res.status(401).json({
        success: false,
        message: "Invalid token",
      });
    }
    res.status(500).json({
      success: false,
      message: "Error updating vendor profile: " + error.message,
    });
  }
});

router.get("/users/profile", async (req, res) => {
  try {
    // Get token from Authorization header
    const token = req.headers.authorization?.split(" ")[1];

    if (!token) {
      return res.status(401).json({
        success: false,
        message: "Authorization token required",
      });
    }

    // Verify token
    const decoded = jwt.verify(token, "SECRET");

    let user;
    if (decoded.role === "Admin") {
      await connectInventoryDB(async () => {
        user = await vendorModel.findById(decoded.id);
      });
    } else {
      await connectUserDB(async () => {
        user = await userModel.findById(decoded.id);
      });
    }

    if (!user) {
      return res.status(404).json({
        success: false,
        message: "User not found",
      });
    }

    // Return user profile data
    res.status(200).json({
      success: true,
      data: {
        userName: user.userName,
        email: user.email,
        phone: user.phone,
        role: user.role,
        status: user.status,
      },
    });
  } catch (error) {
    console.error("Profile fetch error:", error);
    if (error.name === "JsonWebTokenError") {
      return res.status(401).json({
        success: false,
        message: "Invalid token",
      });
    }
    res.status(500).json({
      success: false,
      message: "Error fetching profile: " + error.message,
    });
  }
});

router.put("/users/update_profile", async (req, res) => {
  try {
    const token = req.headers.authorization?.split(" ")[1];
    if (!token) {
      return res.status(401).json({
        success: false,
        message: "Authorization token required",
      });
    }

    const decoded = jwt.verify(token, "SECRET");
    const { userName, phone } = req.body;

    let updatedUser;
    if (decoded.role === "Admin") {
      await connectInventoryDB(async () => {
        updatedUser = await vendorModel.findByIdAndUpdate(
          decoded.id,
          { vendorName: userName, phone },
          { new: true }
        );
      });
    } else {
      await connectUserDB(async () => {
        updatedUser = await userModel.findByIdAndUpdate(
          decoded.id,
          { userName, phone },
          { new: true }
        );
      });
    }

    if (!updatedUser) {
      return res.status(404).json({
        success: false,
        message: "User not found",
      });
    }

    res.status(200).json({
      success: true,
      message: "Profile updated successfully",
      data: {
        userName: updatedUser.userName,
        email: updatedUser.email,
        phone: updatedUser.phone,
      },
    });
  } catch (error) {
    console.error("Profile update error:", error);
    if (error.name === "JsonWebTokenError") {
      return res.status(401).json({
        success: false,
        message: "Invalid token",
      });
    }
    res.status(500).json({
      success: false,
      message: "Error updating profile: " + error.message,
    });
  }
});

router.post("/verify-otp", async (req, res) => {
  const { userId, otp } = req.body;

  try {
    // Find and update user in a single operation
    let updatedUser;
    await connectUserDB(async () => {
      updatedUser = await userModel.findOne({
        _id: userId,
        otp,
      });
    });
    console.log("updatedUser", updatedUser);

    if (!updatedUser) {
      return res.status(400).json({
        status_code: 400,
        message: "Invalid or expired OTP",
      });
    }
    // Update user status to "verified"
    updatedUser.status = "verified";
    await connectUserDB(async () => {
      await updatedUser.save();
    });
    // await updatedUser.save();
    res.status(200).json({
      status_code: 200,
      message: "Account verified successfully",
      user: {
        id: updatedUser._id,
        email: updatedUser.email,
        status: updatedUser.status,
      },
    });
  } catch (err) {
    console.error("OTP verification error:", err);
    res.status(500).json({
      status_code: 500,
      message: "Server error during verification",
    });
  }
});

router.post("/isValidMail", async (req, res) => {
  const { email, role } = req.body;
  console.log("email", email, role);

  try {
    let existEmail;
    if (role == "Admin") {
      await connectInventoryDB(async () => {
        existEmail = await vendorModel.findOne({ email: email });
      });
    } else {
      await connectUserDB(async () => {
        existEmail = await userModel.findOne({ email: email });
      });
    }

    if (existEmail) {
      // Generate and send new OTP
      const newOTP = Math.floor(100000 + Math.random() * 900000).toString();
      const otpExpiry = new Date(Date.now() + 30 * 60 * 1000); // 30 minutes expiry

      // Update user with new OTP
      if (role === "Admin") {
        await connectInventoryDB(async () => {
          await vendorModel.findOneAndUpdate(
            { email },
            { otp: newOTP, otpExpires: otpExpiry }
          );
        });
      } else {
        await connectUserDB(async () => {
          await userModel.findOneAndUpdate(
            { email },
            { otp: newOTP, otpExpires: otpExpiry }
          );
        });
      }

      // Send OTP email
      await sendOTPEmail(email, "User", newOTP);

      res.status(200).json({
        status: "success",
        message: "User exists in the system",
        email: existEmail.email,
        userId: existEmail._id.toString(), // Convert ObjectId to string
      });
    } else {
      res.status(404).json({
        status: "failed",
        message: "User doesn't exist. Please sign up",
      });
    }
  } catch (err) {
    console.error("Error checking email:", err);
    res.status(500).json({
      status: "error",
      message: "Error checking email: " + err.message,
    });
  }
});

router.post("/reset-password", async (req, res) => {
  const { userId, newPassword } = req.body;
  console.log("userId", userId, newPassword);

  try {
    if (!userId || !newPassword) {
      return res.status(400).json({
        status_code: 400,
        message: "User ID and new password are required",
      });
    }

    // Find user by ID
    let user;
    await connectUserDB(async () => {
      user = await userModel.findById({ _id: userId });
    });

    if (!user) {
      return res.status(404).json({
        status_code: 404,
        message: "User not found",
      });
    }

    // Hash the new password
    const salt = await encrypt.genSalt(10);
    const passwordEncrypted = await encrypt.hash(newPassword, salt);

    // Update user's password
    await connectUserDB(async () => {
      console.log("save in ", user);

      user.password = passwordEncrypted;
      await user.save();
    });

    res.status(200).json({
      status_code: 200,

      message: "Password reset successfully",
    });
  } catch (error) {
    console.error("Password reset error:", error);
    res.status(500).json({
      status_code: 500,
      message: "Error resetting password: " + error.message,
    });
  }
});
// Add this route for vendor password change
router.post("/vendors/change-password", async (req, res) => {
  try {
    const { currentPassword, newPassword } = req.body;
    const token = req.headers.authorization?.split(" ")[1];
    
    if (!token) {
      return res.status(401).json({
        success: false,
        message: "Authorization token required",
      });
    }

    // Verify token
    const decoded = jwt.verify(token, "SECRET");
    const vendorId = decoded.id;
    
    if (!vendorId) {
      return res.status(401).json({
        success: false,
        message: "Invalid token",
      });
    }

    // Get vendor from database
    let vendor;
    await connectInventoryDB(async () => {
      vendor = await vendorModel.findById(vendorId);
    });

    if (!vendor) {
      return res.status(404).json({
        success: false,
        message: "Vendor not found",
      });
    }

    // Verify current password
    const isPasswordCorrect = await encrypt.compare(currentPassword, vendor.password);
    if (!isPasswordCorrect) {
      return res.status(400).json({
        success: false,
        message: "Current password is incorrect",
      });
    }

    // Hash new password
    const salt = await encrypt.genSalt(10);
    const hashedPassword = await encrypt.hash(newPassword, salt);

    // Update password
    await connectInventoryDB(async () => {
      await vendorModel.findByIdAndUpdate(
        vendorId,
        { password: hashedPassword },
        { new: true }
      );
    });

    res.status(200).json({
      success: true,
      message: "Password changed successfully",
    });
  } catch (error) {
    console.error("Change password error:", error);
    if (error.name === "JsonWebTokenError") {
      return res.status(401).json({
        success: false,
        message: "Invalid token",
      });
    }
    res.status(500).json({
      success: false,
      message: "Error changing password: " + error.message,
    });
  }
});
// Add this route for user password change
router.post("/users/change-password", async (req, res) => {
  try {
    const { currentPassword, newPassword } = req.body;
    const token = req.headers.authorization?.split(" ")[1];
    
    if (!token) {
      return res.status(401).json({
        success: false,
        message: "Authorization token required",
      });
    }

    // Verify token
    const decoded = jwt.verify(token, "SECRET");
    const userId = decoded.id;
    
    if (!userId) {
      return res.status(401).json({
        success: false,
        message: "Invalid token",
      });
    }

    // Get user from database
    let user;
    await connectUserDB(async () => {
      user = await userModel.findById(userId);
    });

    if (!user) {
      return res.status(404).json({
        success: false,
        message: "User not found",
      });
    }

    // Verify current password
    const isPasswordCorrect = await encrypt.compare(currentPassword, user.password);
    if (!isPasswordCorrect) {
      return res.status(400).json({
        success: false,
        message: "Current password is incorrect",
      });
    }

    // Hash new password
    const salt = await encrypt.genSalt(10);
    const hashedPassword = await encrypt.hash(newPassword, salt);

    // Update password
    await connectUserDB(async () => {
      await userModel.findByIdAndUpdate(
        userId,
        { password: hashedPassword },
        { new: true }
      );
    });

    res.status(200).json({
      success: true,
      message: "Password changed successfully",
    });
  } catch (error) {
    console.error("Change password error:", error);
    if (error.name === "JsonWebTokenError") {
      return res.status(401).json({
        success: false,
        message: "Invalid token",
      });
    }
    res.status(500).json({
      success: false,
      message: "Error changing password: " + error.message,
    });
  }
});
module.exports = router;
