// Add these requires at the top
const { userModel } = require("../models/user");
const express = require("express");
const router = express.Router();
const {
  connectSuperAdminDB,
  connectInventoryDB,
  connectUserDB,
} = require("../Config/DBconfig");
const { superAdminModel } = require("../models/superadmin");
const getVendorModel = require("../models/vendor");
const bcrypt = require("bcrypt");
const jwt = require("jsonwebtoken");
const { vendorModel } = require("../models/vendor");

const jwtExpiryMinute = 60;

// require("dotenv").config();

// POST API for super admin login
router.post("/log_in", async (req, res) => {
  console.log("super admin hit");
  const { uEmail, password } = req.body;

  try {
    let superAdmin = null;
    await connectSuperAdminDB(async () => {
      // const superAdminModel = getSuperAdminModel(connection);
      superAdmin = await superAdminModel.find();
    });
    console.log("admin det", superAdmin);

    await console.log("admin det", superAdmin);
    if (!superAdmin) {
      return res
        .status(400)
        .json({ message: "Super Admin doesn't exist. Please sign up." });
    }
    const isMatch = await bcrypt.compare(password, superAdmin[0].password);
    if (!isMatch) {
      return res.status(400).json({ message: "Incorrect email or password." });
    }

    const token = jwt.sign(
      { id: superAdmin._id, email: superAdmin.email, role: superAdmin.role },
      "SECRET",
      { expiresIn: jwtExpiryMinute * 30 }
    );

    return res.status(200).send({
      status_code: 200,
      message: "Super Admin logged in successfully.",
      token: token,
    });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

router.get("/get_vendors", async (req, res) => {
  console.log("naya");
  let data = null;
  await connectInventoryDB(async () => {
    data = await vendorModel.find({ status: "unverified" });
  });
  console.log("alli", data);

  return res.status(200).send({
    status_code: 200,
    message: "All unverified vendors retrived successfully",
    data: data,
  });
});

// New endpoint to get all vendors
router.get("/get_all_vendors", async (req, res) => {
  console.log("Getting all vendors");
  let data = [];
  try {
    await connectInventoryDB(async () => {
      data = await vendorModel.find();
    });

    return res.status(200).send({
      status_code: 200,
      message: "All vendors retrieved successfully",
      data: data,
    });
  } catch (error) {
    console.error("Error fetching all vendors:", error);
    return res.status(500).send({
      status_code: 500,
      message: "Error fetching vendors",
      error: error.message,
    });
  }
});

// New endpoint to get verified vendors
router.get("/get_verified_vendors", async (req, res) => {
  console.log("Getting verified vendors");
  let data = [];
  try {
    await connectInventoryDB(async () => {
      data = await vendorModel.find({ status: "verified" });
    });

    return res.status(200).send({
      status_code: 200,
      message: "All verified vendors retrieved successfully",
      data: data,
    });
  } catch (error) {
    console.error("Error fetching verified vendors:", error);
    return res.status(500).send({
      status_code: 500,
      message: "Error fetching verified vendors",
      error: error.message,
    });
  }
});

// New endpoint to get rejected vendors
router.get("/get_rejected_vendors", async (req, res) => {
  console.log("Getting rejected vendors");
  let data = [];
  try {
    await connectInventoryDB(async () => {
      data = await vendorModel.find({ status: "rejected" });
    });

    return res.status(200).send({
      status_code: 200,
      message: "All rejected vendors retrieved successfully",
      data: data,
    });
  } catch (error) {
    console.error("Error fetching rejected vendors:", error);
    return res.status(500).send({
      status_code: 500,
      message: "Error fetching rejected vendors",
      error: error.message,
    });
  }
});

// Add verify vendor endpoint
router.put("/verify_vendor/:id", async (req, res) => {
  const vendorId = req.params.id;
  console.log("Verifying vendor with ID:", vendorId);

  try {
    let updatedVendor = null;
    await connectInventoryDB(async () => {
      updatedVendor = await vendorModel.findByIdAndUpdate(
        vendorId,
        { status: "verified", isVerified: true },
        { new: true }
      );
    });

    if (!updatedVendor) {
      return res.status(404).json({ message: "Vendor not found" });
    }

    return res.status(200).json({
      status_code: 200,
      message: "Vendor verified successfully",
      data: updatedVendor,
    });
  } catch (error) {
    console.error("Error verifying vendor:", error);
    return res
      .status(500)
      .json({ message: "Server error", error: error.message });
  }
});

// Add reject vendor endpoint
router.put("/reject_vendor/:id", async (req, res) => {
  const vendorId = req.params.id;
  console.log("Rejecting vendor with ID:", vendorId);

  try {
    let updatedVendor = null;
    await connectInventoryDB(async () => {
      updatedVendor = await vendorModel.findByIdAndUpdate(
        vendorId,
        { status: "rejected", isVerified: false },
        { new: true }
      );
    });

    if (!updatedVendor) {
      return res.status(404).json({ message: "Vendor not found" });
    }

    return res.status(200).json({
      status_code: 200,
      message: "Vendor rejected successfully",
      data: updatedVendor,
    });
  } catch (error) {
    console.error("Error rejecting vendor:", error);
    return res
      .status(500)
      .json({ message: "Server error", error: error.message });
  }
});

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

router.post("/update_vendor", async (req, res) => {
  console.log(req.body);
});

// Get all users
router.get("/get_all_users", async (req, res) => {
  console.log("Getting all users for admins");

  try {
    await connectUserDB(async () => {
      const users = await userModel.find();
      console.log("get all users bat aako", users);

      return res.status(200).send({
        status_code: 200,
        message: "Users retrieved successfully",
        data: users,
      });
    });
  } catch (error) {
    console.error("Error fetching users:", error);
    return res.status(500).send({
      status_code: 500,
      message: "Error fetching users",
      error: error.message,
    });
  }
});

// Get verified users
router.get("/get_verified_users", async (req, res) => {
  console.log("Getting verified users");
  let data = [];
  try {
    await connectUserDB(async () => {
      data = await userModel.find({ status: "verified" });
    });

    return res.status(200).send({
      status_code: 200,
      message: "Verified users retrieved successfully",
      data: data,
    });
  } catch (error) {
    console.error("Error fetching verified users:", error);
    return res.status(500).send({
      status_code: 500,
      message: "Error fetching verified users",
      error: error.message,
    });
  }
});

// Get unverified users
router.get("/get_unverified_users", async (req, res) => {
  console.log("Getting unverified users");
  let data = [];
  try {
    await connectUserDB(async () => {
      data = await userModel.find({ status: "unverified" });
    });

    return res.status(200).send({
      status_code: 200,
      message: "Unverified users retrieved successfully",
      data: data,
    });
  } catch (error) {
    console.error("Error fetching unverified users:", error);
    return res.status(500).send({
      status_code: 500,
      message: "Error fetching unverified users",
      error: error.message,
    });
  }
});

module.exports = router;
