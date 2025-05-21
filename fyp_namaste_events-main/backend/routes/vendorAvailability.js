const express = require("express");
const router = express.Router();
const { AvailabilityModel } = require("../models/availability");
const VerifyJWT = require("../middleware/VerifyJWT");
const { connectInventoryDB } = require("../Config/DBconfig");
const { vendorModel } = require("../models/vendor");

// Helper function to validate time format (HH:mm)
const isValidTimeFormat = (time) => {
	const timeRegex = /^([01]?[0-9]|2[0-3]):[0-5][0-9]$/;
	return timeRegex.test(time);
};

// Create availability slot
router.post("/create-slot", VerifyJWT, async (req, res) => {
	try {
		const { vendorEmail, startDate, endDate, category, status } = req.body;

		// Validate required fields
		if (!vendorEmail || !startDate || !endDate || !category) {
			return res.status(400).json({
				success: false,
				message: "Missing required fields",
			});
		}

		// Check for existing slot
		let existingSlot;
		await connectInventoryDB(async () => {
			existingSlot = await AvailabilityModel.find({
				vendorEmail,
				category,
			});
		});

		// If slot exists, update it
		if (existingSlot.length > 0) {
			existingSlot[0].startDate = startDate;
			existingSlot[0].endDate = endDate;

			await connectInventoryDB(async () => {
				await existingSlot[0].save();
			});

			return res.status(200).json({
				success: true,
				message: "Availability slot updated successfully",
			});
		}

		// Create new slot if none exists
		const newSlot = new AvailabilityModel({
			vendorEmail,
			startDate,
			endDate,
			category,
			status: status || "Available",
		});

		await connectInventoryDB(async () => {
			await newSlot.save();
		});

		res.status(201).json({
			success: true,
			message: "Availability slot created successfully",
			data: newSlot,
		});
	} catch (error) {
		console.error("Error creating slot:", error);
		res.status(500).json({
			success: false,
			message: `Error creating availability slot: ${error.message}`,
		});
	}
});

// Get vendor availability
router.get("/available", async (req, res) => {
	try {
		const { vendorEmail } = req.query;
		console.log("ven", vendorEmail);

		let availability;
		await connectInventoryDB(async () => {
			availability = await AvailabilityModel.find({
				vendorEmail,
			}).sort({ date: 1 });
		});
		console.log(availability);

		if (availability && availability.length > 0) {
			res.json({ success: true, data: availability });
		} else {
			res.json({ success: false, message: "No availability found" });
		}
	} catch (error) {
		res.status(500).json({
			success: false,
			message: `Error fetching availability: ${error.message}`,
		});
	}
});

// Update vendor availability
router.post("/vendor-availability/update", VerifyJWT, async (req, res) => {
	try {
		const { vendorId, date, isAvailable } = req.body;

		// Find existing availability or create new one
		let availability = await vendorAvailabilityModel.findOne({
			vendorId,
			date: new Date(date),
		});

		if (availability) {
			availability.isAvailable = isAvailable;
			availability.updatedAt = new Date();
			await availability.save();
		} else {
			availability = new vendorAvailabilityModel({
				vendorId,
				date: new Date(date),
				isAvailable,
			});
			await availability.save();
		}

		res.json({
			success: true,
			message: "Availability updated successfully",
			data: availability,
		});
	} catch (error) {
		res.status(500).json({
			success: false,
			message: `Error updating availability: ${error.message}`,
		});
	}
});

// Get vendor's available dates
router.get("/vendor-available-dates/:vendorId", async (req, res) => {
	try {
		const { vendorId } = req.params;
		const { startDate, endDate } = req.query;

		const query = {
			vendorId,
			isAvailable: true,
			date: {
				$gte: startDate ? new Date(startDate) : new Date(),
				...(endDate && { $lte: new Date(endDate) }),
			},
		};

		const availableDates = await vendorAvailabilityModel
			.find(query)
			.select("date")
			.sort({ date: 1 });

		res.json({
			success: true,
			data: availableDates.map((a) => a.date),
		});
	} catch (error) {
		res.status(500).json({
			success: false,
			message: `Error fetching available dates: ${error.message}`,
		});
	}
});

// Add this new endpoint for bulk updates
router.post("/vendor-availability/bulk-update", VerifyJWT, async (req, res) => {
	try {
		const { vendorId, dates, isAvailable, reason } = req.body;

		// Validate input
		if (!Array.isArray(dates) || dates.length === 0) {
			return res.status(400).json({
				success: false,
				message: "Please provide an array of dates",
			});
		}

		// Process all dates
		const updates = await Promise.all(
			dates.map(async (date) => {
				const availability = await vendorAvailabilityModel.findOneAndUpdate(
					{ vendorId, date: new Date(date) },
					{
						$set: {
							isAvailable,
							reason,
							updatedAt: new Date(),
						},
					},
					{ upsert: true, new: true }
				);
				return availability;
			})
		);

		res.json({
			success: true,
			message: `Successfully updated ${updates.length} dates`,
			data: updates,
		});
	} catch (error) {
		res.status(500).json({
			success: false,
			message: `Error updating availability: ${error.message}`,
		});
	}
});

// Update availability slot
router.put("/update-slot/:id", VerifyJWT, async (req, res) => {
	try {
		const { id } = req.params;
		const updateData = req.body;

		await connectInventoryDB(async () => {
			const updatedSlot = await AvailabilityModel.findOneAndUpdate(
				{ availabilityID: id },
				{
					$set: {
						startDate: updateData.startDate,
						endDate: updateData.endDate,
						status: updateData.status,
						category: updateData.category,
					},
				},
				{ new: true }
			);

			if (!updatedSlot) {
				return res.status(404).json({
					success: false,
					message: "Availability slot not found",
				});
			}

			res.json({
				success: true,
				message: "Availability slot updated successfully",
				data: updatedSlot,
			});
		});
	} catch (error) {
		console.error("Error updating slot:", error);
		res.status(500).json({
			success: false,
			message: `Error updating availability slot: ${error.message}`,
		});
	}
});
// Get vendor availability by vendor ID
router.get("/slots/vendor/:vendorId", async (req, res) => {
	try {
		const { vendorId } = req.params;

		await connectInventoryDB(async () => {
			const vendor = await vendorModel.findById(vendorId);
			if (!vendor) {
				return res.status(404).json({
					success: false,
					message: "Vendor not found",
				});
			}

			const availability = await AvailabilityModel.find({
				vendorEmail: vendor.email,
				status: "Available",
			}).sort({ startDate: 1 });

			return res.json({
				success: true,
				data: availability,
			});
		});
	} catch (error) {
		console.error("Error fetching availability:", error);
		return res.status(500).json({
			success: false,
			message: `Error fetching availability: ${error.message}`,
		});
	}
});

// Get vendor availability by email
router.get("/slots/email/:email", async (req, res) => {
	try {
		const { email } = req.params;

		await connectInventoryDB(async () => {
			const availability = await AvailabilityModel.find({
				vendorEmail: email,
				status: "Available",
			}).sort({ startDate: 1 });

			return res.json({
				success: true,
				data: availability,
			});
		});
	} catch (error) {
		console.error("Error fetching availability:", error);
		return res.status(500).json({
			success: false,
			message: `Error fetching availability: ${error.message}`,
		});
	}
});
module.exports = router;
