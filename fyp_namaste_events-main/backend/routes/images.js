const express = require("express");
const { docImageModel, venueImageModel } = require("../models/image");
const router = express.Router();

// Fetch all images
router.get("/", async (req, res) => {
  try {
    const images = await docImageModel.find();
    res.json({ success: true, data: images });
  } catch (err) {
    res.status(500).json({ success: false, message: "Server error" });
  }
});

// Fetch images by email
router.get("/email/:email", async (req, res) => {
  const email = req.params.email;
  try {
    const images = await docImageModel.find({ srcFrom: email });
    res.json({ success: true, data: images });
  } catch (err) {
    res.status(500).json({ success: false, message: "Server error" });
  }
});

module.exports = router;
