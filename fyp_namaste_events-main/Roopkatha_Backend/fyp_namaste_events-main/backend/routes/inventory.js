const express = require("express");
const VerifyJWT = require("../middleware/VerifyJWT");
const router = express.Router();
const { connectInventoryDB } = require("../Config/DBconfig");
const {
  photographyModel,
  decoratorModel,
  venueModel,
} = require("../models/vendor");
const { uploadInventory } = require("../Config/multerConfig");
const {
  photographyImageModel,
  venueImageModel,
  decorationImageModel,
} = require("../models/image");
const path = require("path");
const fs = require("fs");
const axios = require("axios");

const venueData = [];

// GET API to fetch inventory data for homepage
router.get("/get_all_inventory", async (req, res) => {
  console.log("get all inventory hit");

  try {
    let allInventories = {
      venues: [],
      decorators: [],
      photographers: [],
    };

    await connectInventoryDB(async () => {
      // Fetch all inventory items
      allInventories.venues = await venueModel.find({});
      allInventories.decorators = await decoratorModel.find({});
      allInventories.photographers = await photographyModel.find({});

      // Process venues to include images
      for (const venue of allInventories.venues) {
        const images = await venueImageModel.find({ srcFrom: venue.owner });
        console.log("images", images);

        venue._doc.images = images.map((img) => ({
          ...img.toObject(),
          fullUrl: `${req.protocol}://${req.get("host")}/${
            img.filePath || "uploads/inventory"
          }/${img.fileName}`,
        }));
      }

      // Process decorators to include images
      for (const decorator of allInventories.decorators) {
        const images = await decorationImageModel.find({
          srcFrom: decorator.owner,
        });
        decorator._doc.images = images.map((img) => ({
          ...img.toObject(),
          fullUrl: `${req.protocol}://${req.get("host")}/${
            img.filePath || "uploads/inventory"
          }/${img.fileName}`,
        }));
      }

      // Process photographers to include images
      for (const photographer of allInventories.photographers) {
        const images = await photographyImageModel.find({
          srcFrom: photographer.owner,
        });
        photographer._doc.images = images.map((img) => ({
          ...img.toObject(),
          fullUrl: `${req.protocol}://${req.get("host")}/${
            img.filePath || "uploads/inventory"
          }/${img.fileName}`,
        }));
      }
    });

    return res.status(200).json({
      success: true,
      data: allInventories,
    });
  } catch (error) {
    console.error("Error fetching all inventories:", error);
    return res.status(500).json({
      success: false,
      message: "Server error while fetching all inventory",
    });
  }
});

// New endpoint to get inventory images for users
router.post("/get_inventory_images", async (req, res) => {
  try {
    const { email, type } = req.body;

    // if (!category) {
    //   return res.status(400).json({
    //     success: false,
    //     message: "Category is required",
    //   });
    // }

    let images = [];

    // Find images based on category
    if (category === "Venue") {
      await connectInventoryDB(async () => {
        images = await venueImageModel.find({
          ...(email && { srcFrom: email }),
        });
      });
    } else if (category === "Photography") {
      await connectInventoryDB(async () => {
        images = await photographyImageModel.find({
          ...(inventoryId && { inventoryId }),
          ...(email && { srcFrom: email }),
        });
      });
    } else if (category === "Decoration") {
      await connectInventoryDB(async () => {
        images = await decorationImageModel.find({
          ...(inventoryId && { inventoryId }),
          ...(email && { srcFrom: email }),
        });
      });
    }

    // Transform images to include full URLs
    const transformedImages = images.map((img) => {
      return {
        ...img.toObject(),
        fullUrl: `${req.protocol}://${req.get("host")}/${img.filePath}/${
          img.fileName
        }`,
        type: img.type || category.toLowerCase(),
        uploadDate: img._id.getTimestamp(),
      };
    });

    // If we have a filePath in the first image, try to get all files from that folder
    if (images.length > 0 && images[0].filePath) {
      const folderPath = images[0].filePath;
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
            success: true,
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

    return res.status(200).json({
      success: true,
      message: "Inventory images retrieved successfully",
      data: transformedImages,
    });
  } catch (err) {
    console.error("Error getting inventory images:", err);
    return res.status(500).json({
      success: false,
      message: err.message,
    });
  }
});

// New endpoint to get all files in a specific inventory folder (for users)
router.post("/get_inventory_files", async (req, res) => {
  try {
    const { folderName } = req.body;

    if (!folderName) {
      return res.status(400).json({
        success: false,
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
        success: false,
        message: "Inventory folder not found",
      });
    }

    // Read all files in the directory
    fs.readdir(inventoryFolderPath, (err, files) => {
      if (err) {
        console.error("Error reading directory:", err);
        return res.status(500).json({
          success: false,
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
        success: true,
        message: "Files retrieved successfully",
        data: fileDetails,
        folderPath: `/uploads/inventory/${folderName}`,
      });
    });
  } catch (err) {
    console.error("Error getting inventory files:", err);
    return res.status(500).json({
      success: false,
      message: err.message,
    });
  }
});

// New endpoint to serve images directly
router.get("/image/:category/:filename", async (req, res) => {
  try {
    const { category, filename } = req.params;
    let imagePath;

    // Determine the correct path based on category
    if (category === "venue") {
      imagePath = path.join(__dirname, "../uploads/inventory/venue", filename);
    } else if (category === "photography") {
      imagePath = path.join(
        __dirname,
        "../uploads/inventory/photography",
        filename
      );
    } else if (category === "decoration") {
      imagePath = path.join(
        __dirname,
        "../uploads/inventory/decoration",
        filename
      );
    } else {
      imagePath = path.join(__dirname, "../uploads/inventory", filename);
    }

    // Check if file exists
    if (fs.existsSync(imagePath)) {
      return res.sendFile(imagePath);
    } else {
      return res.status(404).json({
        success: false,
        message: "Image not found",
      });
    }
  } catch (err) {
    console.error("Error serving image:", err);
    return res.status(500).json({
      success: false,
      message: err.message,
    });
  }
});

module.exports = router;
