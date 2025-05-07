const express = require("express");
const router = express.Router();
const { vendorModel } = require("../models/vendor");

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

module.exports = router;
