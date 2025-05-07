const express = require("express");
const mongoose = require("mongoose");
const dotenv = require("dotenv");
const multer = require("multer");
const path = require("path");
const bcrypt = require("bcrypt"); // Add bcrypt for password hashing
const app = express();
const PORT = 2000;

// Load environment variables
dotenv.config();

// Import the SuperAdmin model
const { superAdminModel } = require("./models/superadmin");

// Middleware to parse JSON and URL-encoded data
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Serve static files from the uploads directory
app.use("/uploads", express.static(path.join(__dirname, "uploads")));

// Multer configuration for file uploads
const upload = multer({ dest: "uploads/" });

// Routes
const inventoryAction = require("./routes/inventoryActions");
const userAuth = require("./routes/userAuthentication");
const vendorAuth = require("./routes/VendorAuthentication");
const vendorRoutes = require("./routes/vendor");
const imageRoutes = require("./routes/images");
const superAdminRoutes = require("./routes/admin");
const inventoryRoutes = require("./routes/inventory"); // New route added
const otpRoutes = require("./routes/otpRoutes");

// Add this line with your other routes
const bookingRoutes = require("./routes/bookingRoutes");
const VendorAvailabilityRoutes = require("./routes/vendorAvailability");

app.use("/api/vendorAvailability", VendorAvailabilityRoutes);
// Add this line where you define other app.use() statements
app.use("/api/bookings", bookingRoutes);
app.use("/api", inventoryAction);
app.use("/auth", userAuth);
app.use("/vendor", vendorAuth);
app.use("/superadmin", superAdminRoutes);
app.use("/images", imageRoutes);
app.use("/inventory", inventoryRoutes); // New route added
app.use("/api/otp", otpRoutes);

// Function to initialize admin if not exists
async function initializeAdmin() {
  try {
    console.log("Checking if admin exists in database...");
    const adminExists = await superAdminModel.findOne({
      email: process.env.ADMIN_EMAIL,
    });

    if (!adminExists) {
      console.log("Admin does not exist, creating one...");

      const salt = await bcrypt.genSalt(10);
      const passwordEncrypted = await bcrypt.hash(
        process.env.ADMIN_PASSWORD,
        salt
      );

      const newAdmin = new superAdminModel({
        userName: "superAdmin",
        email: process.env.ADMIN_EMAIL,
        password: passwordEncrypted,
      });

      await newAdmin.save();
      console.log("SuperAdmin created successfully!");
    } else {
      console.log("Admin already exists in the database.");
    }
  } catch (error) {
    console.error("Error during admin initialization:", error.message);
  }
}

// Connect to MongoDB and start server
mongoose
  .connect(process.env.DATABASE_Super_Admin)
  .then(() => {
    console.log("Connected to MongoDB database");
    return initializeAdmin();
  })
  .then(() => {
    app.listen(PORT, () => {
      console.log(`Server running on port ${PORT}`);
    });
  })
  .catch((err) => {
    console.error("Database connection error:", err.message);
  });
