import axios from "axios";
import PaymentModel from "../models/Payment.js"; // Add this at the top with other imports
import { connectInventoryDB } from "./DBconfig.js";

// require("dotenv").config();

// Function to verify Khalti Payment
async function verifyKhaltiPayment(pidx) {
	try {
		console.log("in verify khalti function");

		const headersList = {
			Authorization: `Key ${process.env.KHALTI_SECRET_KEY}`,
			"Content-Type": "application/json",
		};

		const bodyContent = JSON.stringify({ pidx });

		const reqOptions = {
			url: `${process.env.KHALTI_GATEWAY_URL}/api/v2/epayment/lookup/`,
			method: "POST",
			headers: headersList,
			data: bodyContent,
		};

		const response = await axios.request(reqOptions);
		return response.data;
	} catch (error) {
		console.error("Error verifying Khalti payment:", error);
		throw error;
	}
}

// Function to initialize Khalti Payment
const KHALTI_CONFIG = {
	GATEWAY_URL: "https://dev.khalti.com", // Test environment URL
	SECRET_KEY: process.env.KHALTI_SECRET_KEY,
	RETURN_URL: `${process.env.BASE_URL}/api/payment/callback`,
};

async function initializeKhaltiPayment(details) {
	const headersList = {
		Authorization: `Key ${process.env.KHALTI_SECRET_KEY}`,
		"Content-Type": "application/json",
	};
	console.log("kha details, ", KHALTI_CONFIG);

	// Store PIDX in database for verification
	const paymentDetails = {
		...details,
		// return_url: KHALTI_CONFIG.RETURN_URL,
		// website_url: process.env.BASE_URL,
	};

	console.log("pay details, ", paymentDetails);

	const reqOptions = {
		url: `${KHALTI_CONFIG.GATEWAY_URL}/api/v2/epayment/initiate/`,
		method: "POST",
		headers: headersList,
		data: paymentDetails,
	};

	// console.log("par url ", reqOptions.url);

	try {
		const response = await axios.request(reqOptions);
		// console.log(":initialize response ", response);

		let paymentRecord;

		let newPayment = new PaymentModel({
			pidx: response.data.pidx,
			amount: details.amount / 100,
			status: "initiated",
			bookingDetails: details.bookingDetails || {},
		});
		// Create payment record with error handling
		await connectInventoryDB(async () => {
			paymentRecord = await newPayment.save();
		});

		if (!paymentRecord) {
			throw new Error("Failed to create payment record");
		}

		return response.data;
	} catch (error) {
		console.error("Error initializing Khalti payment:", error);
		throw error;
	}
}

export { verifyKhaltiPayment, initializeKhaltiPayment };
