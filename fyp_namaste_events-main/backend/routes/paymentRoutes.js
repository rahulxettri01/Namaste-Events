const express = require("express");
const {
	initializeKhaltiPayment,
	verifyKhaltiPayment,
} = require("../Config/khaltiConfig");
const PaymentModel = require("../models/Payment");
const { connectInventoryDB } = require("../Config/DBconfig");

const router = express.Router();

// route to initilize khalti payment gateway
router.post("/initialize-khalti", async (req, res) => {
	try {
		//try catch for error handling
		const { itemId, totalPrice } = req.body;
		// console.log("aayako itemId");
		// console.log(itemId);
		// console.log("weburl payrout init: ", website_url);

		// const itemData = await Item.findOne({
		// 	_id: itemId,
		// 	price: Number(totalPrice),
		// });

		// if (!itemData) {
		// 	return res.status(400).send({
		// 		success: false,
		// 		message: "item not found",
		// 	});
		// }

		// const purchasedItemData = await PurchasedItem.create({
		// 	item: itemId,
		// 	paymentMethod: "khalti",
		// 	totalPrice: totalPrice * 100,
		// });

		const paymentInitiate = await initializeKhaltiPayment({
			amount: totalPrice * 100, // amount should be in paisa (Rs * 100)
			purchase_order_id: "purchasedItemData._id",
			purchase_order_name: "itemData.name",
			// return_url: `${process.env.BACKEND_URI}/api/payment/complete-khalti-payment`,
			return_url: `${process.env.SERVER_URL}/api/payment/khalti-callback`,
			website_url: `${process.env.SERVER_URL}`,
		});

		// console.log("payI", paymentInitiate);

		res.json({
			// purchasedItemData,
			paymentInitiate,
		});
	} catch (error) {
		res.json({
			success: false,
			error,
		});
	}
});

// it is our `return url` where we verify the payment done by user
router.get("/complete-khalti-payment", async (req, res) => {
	const {
		pidx,
		txnId,
		amount,
		mobile,
		purchase_order_id,
		purchase_order_name,
		transaction_id,
	} = req.query;

	try {
		const paymentInfo = await verifyKhaltiPayment(pidx);

		// Check if payment is completed and details match
		if (
			paymentInfo?.status !== "Completed" ||
			paymentInfo.transaction_id !== transaction_id ||
			Number(paymentInfo.total_amount) !== Number(amount)
		) {
			return res.status(400).json({
				success: false,
				message: "Incomplete information",
				paymentInfo,
			});
		}

		// Check if payment done in valid item
		// const purchasedItemData = await PurchasedItem.find({
		// 	_id: purchase_order_id,
		// 	totalPrice: amount,
		// });

		// if (!purchasedItemData) {
		// 	return res.status(400).send({
		// 		success: false,
		// 		message: "Purchased data not found",
		// 	});
		// }
		// await PurchasedItem.findByIdAndUpdate(
		// 	purchase_order_id,

		// 	{
		// 		$set: {
		// 			status: "completed",
		// 		},
		// 	}
		// );

		// Create a new payment record
		// const paymentData = await Payment.create({
		// 	pidx,
		// 	transactionId: transaction_id,
		// 	productId: purchase_order_id,
		// 	amount,
		// 	dataFromVerificationReq: paymentInfo,
		// 	apiQueryFromUser: req.query,
		// 	paymentGateway: "khalti",
		// 	status: "success",
		// });

		// Send success response
		res.json({
			success: true,
			message: "Payment Successful",
			// paymentData,
		});
	} catch (error) {
		console.error(error);
		res.status(500).json({
			success: false,
			message: "An error occurred",
			error,
		});
	}
});
router.get("/khalti-callback", async (req, res) => {
	console.log("in the khalti callback");

	try {
		const { pidx, transaction_id, mobile, status, amount } = req.query;

		console.log("pidx: ", pidx);

		// Verify payment with Khalti
		const verificationResponse = await verifyKhaltiPayment(pidx);
		console.log("pidx verification: ", verificationResponse);

		// Find stored payment

		let payment;
		await connectInventoryDB(async () => {
			payment = await PaymentModel.findOne({ pidx: pidx });
		});

		if (!payment) {
			return res.status(404).json({
				success: false,
				message: "Payment not found",
			});
		}

		if (verificationResponse.status === "Completed") {
			// Update payment status and remove expiry
			payment.status = "completed";
			payment.transactionId = transaction_id;
			payment.verificationDetails = verificationResponse;
			payment.completedAt = new Date();
			payment.amount = verificationResponse.total_amount / 100;
			payment.mobile = mobile || "";
			payment.paymentMethod = verificationResponse.payment_method || "Khalti";
			// Remove expiry
			payment.collection.updateOne(
				{ _id: payment._id },
				{ $unset: { createdAt: "" } }
			);
			await payment.save();

			// Create booking
			if (payment.bookingDetails) {
				// Create booking logic here
			}

			// For successful payment
			return res.status(200).json({
				success: true,
				message: "Payment successful",
				data: {
					pidx: pidx,
					transactionId: transaction_id,
					status: "completed",
					amount: payment.amount,
				},
			});
		} else {
			payment.status = "failed";
			payment.failureReason = verificationResponse.message;
			await payment.save();

			return res.status(400).json({
				success: false,
				message: "Payment failed",
				error: verificationResponse.message,
			});
		}
	} catch (error) {
		console.error("Payment callback error:", error);
		res.redirect(
			`${process.env.FRONTEND_URL}/payment-failed?error=${encodeURIComponent(
				error.message
			)}`
		);
	}
});

module.exports = router;
