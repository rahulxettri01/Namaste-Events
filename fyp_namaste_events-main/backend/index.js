const express = require("express");
const mongoose = require("mongoose");
const dotenv = require("dotenv");
const multer = require("multer");
const path = require("path");
const bcrypt = require("bcrypt");
const app = express();
const PORT = 2000;
const cors = require('cors');
// Load environment variables
dotenv.config();

// Import the SuperAdmin model
const { superAdminModel } = require("./models/superadmin");

// Middleware to parse JSON and URL-encoded data
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Serve static files from the uploads directory
app.use("/uploads", express.static(path.join(__dirname, "uploads")));
// Add this near the top with other imports


// Add this before your route definitions
// Update the CORS configuration
app.use(cors({
  origin: '*', // Allow all origins in development
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS', 'PATCH'],
  allowedHeaders: ['Content-Type', 'Authorization', 'Accept'],
  credentials: true
}));
// Multer configuration for file uploads
const upload = multer({ dest: "uploads/" });

// Routes
const inventoryAction = require("./routes/inventoryActions");
const userAuth = require("./routes/userAuthentication");
const vendorAuth = require("./routes/VendorAuthentication");
const vendorRoutes = require("./routes/vendor");
const imageRoutes = require("./routes/images");
const superAdminRoutes = require("./routes/admin");
const inventoryRoutes = require("./routes/inventory");
const otpRoutes = require("./routes/otpRoutes");
const bookingRoutes = require("./routes/bookingRoutes");
const VendorAvailabilityRoutes = require("./routes/vendorAvailability");
const paymentRoutes = require("./routes/paymentRoutes");
const notificationRoutes = require("./routes/notificationRoutes");
const authRoutes = require("./routes/auth"); // Add this line

// Register all routes
app.use("/api/vendorAvailability", VendorAvailabilityRoutes);
app.use("/api/bookings", bookingRoutes);
app.use("/api", inventoryAction);
app.use("/auth", userAuth);
app.use("/auth", authRoutes); // Add this line
app.use("/vendor/auth", vendorAuth);
app.use("/vendor", vendorRoutes);
app.use("/superadmin", superAdminRoutes);
app.use("/images", imageRoutes);
app.use("/inventory", inventoryRoutes);
app.use("/api/otp", otpRoutes);
app.use("/api/payment", paymentRoutes);
app.use("/api/notifications", notificationRoutes);
app.use("/auth", authRoutes);
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
		// Update the app.listen call to listen on all network interfaces
		app.listen(PORT, '0.0.0.0', () => {
		  console.log(`Server running on port ${PORT}`);
		  console.log(`Server accessible at http://localhost:${PORT}`);
		  console.log(`For LAN access, use http://<your-ip-address>:${PORT}`);
		});
	})
	.catch((err) => {
		console.error("Database connection error:", err.message);
	});

app.get("/", async (req, res) => {
	res.json("hello from the backend");
});
