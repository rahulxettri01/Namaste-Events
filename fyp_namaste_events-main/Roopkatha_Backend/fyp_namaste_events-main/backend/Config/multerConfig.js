const multer = require("multer");
const path = require("path");
const { connectInventoryDB, connectUserDB } = require("../Config/DBconfig");
const {
  docImageModel,
  photographyImageModel,
  venueImageModel,
  decorationImageModel,
} = require("../models/image");

const {
  decoratorModel,
  photographyModel,
  venueModel,
  vendorModel,
} = require("../models/vendor");

// Configure storage with unique filename using date-time
const storageVendor = multer.diskStorage({
  destination: (req, file, cb) => {
    const details = req.user;
    let folderName = "";

    if (!req.inventoryFolder) {
      // Generate a unique folder name based on email and category
      const timestamp = Date.now();
      folderName = `${details.email.split("@")[0]}-${
        details.category
      }-${timestamp}`;
      req.inventoryFolder = folderName;

      // Create the directory if it doesn't exist
      const fs = require("fs");
      const inventoryPath = `./uploads/vendor/${folderName}`;
      if (!fs.existsSync(inventoryPath)) {
        fs.mkdirSync(inventoryPath, { recursive: true });
        console.log(`Created inventory folder: ${inventoryPath}`);
      }
    } else {
      folderName = req.inventoryFolder;
    }
    cb(null, `./uploads/vendor/${folderName}`); // Directory where files will be stored
  },
  filename: async (req, file, cb) => {
    // Extract file extension
    const ext = path.extname(file.originalname);
    // Generate a unique filename: originalName_without_extension + timestamp + extension
    const uniqueName =
      path.basename(file.originalname, ext) + "-" + Date.now() + ext;
    const details = req.user;
    console.log("details", details);

    // Initialize file counter if not already set
    if (!req.fileCount) {
      req.fileCount = 0;
      req.alreadyExists = false;
      req.savedImages = [];

      // Check if verification docs already exist - only check once for the first file
      await connectInventoryDB(async () => {
        const dupImg = await docImageModel.findOne({
          srcFrom: details.email,
          type: details.category.toLowerCase(),
        });
        if (dupImg) {
          console.log("Vendor doc already exists");
          req.alreadyExists = true;
        }
      });
    }

    req.fileCount++;

    // If docs already exist, reject all files
    if (req.alreadyExists) {
      console.log(
        `Rejecting file ${req.fileCount}: Verification docs already exist`
      );
      return cb(new Error("Verification docs already exist"), false);
    }

    // Create appropriate image model based on category
    const image = new docImageModel({
      fileName: uniqueName,
      filePath: `uploads/vendor/${req.inventoryFolder}`,
      srcFrom: details.email,
      type: details.category.toLowerCase(),
    });

    try {
      // Save image to database with proper error handling
      let savedImage;
      await connectInventoryDB(async () => {
        try {
          savedImage = await image.save();
          console.log(
            `File ${req.fileCount} uploaded to database with ID: ${savedImage._id}`
          );

          req.imageStatus = true;
        } catch (dbError) {
          console.error("Database save error:", dbError);
        }
      });
      // Store saved image info
      if (!req.savedImages) req.savedImages = [];
      req.savedImages.push({
        id: savedImage._id,
        fileName: uniqueName,
      });

      // Always call the callback to ensure the file is saved to disk
      cb(null, uniqueName);
    } catch (error) {
      console.error("Error in file upload process:", error);
      cb(error, false);
    }
  },
});
const storageUser = multer.diskStorage({
  destination: (req, file, cb) => {
    cb(null, "./uploads/user"); // Directory where files will be stored
  },
  filename: (req, file, cb) => {
    // Extract file extension
    const ext = path.extname(file.originalname);
    // Generate a unique filename: originalName_without_extension + timestamp + extension
    const uniqueName =
      path.basename(file.originalname, ext) + "-" + Date.now() + ext;
    const image = new docImageModel({
      fileName: uniqueName,
      filePath: "uploads/user",
      srcFrom: "user",
    });
    cb(null, uniqueName);
  },
});

// Configure storage for inventory images
// In the storageInventory configuration, update the destination function:

const storageInventory = multer.diskStorage({
  destination: (req, file, cb) => {
    const details = req.user;

    // Create a unique folder name for this inventory
    let folderName = "";

    if (!req.inventoryFolder) {
      // Generate a unique folder name based on email and category
      const timestamp = Date.now();
      folderName = `${details.email.split("@")[0]}-${
        details.category
      }-${timestamp}`;
      req.inventoryFolder = folderName;

      // Create the directory if it doesn't exist
      const fs = require("fs");
      const inventoryPath = `./uploads/inventory/${folderName}`;

      if (!fs.existsSync(inventoryPath)) {
        fs.mkdirSync(inventoryPath, { recursive: true });
        console.log(`Created inventory folder: ${inventoryPath}`);
      }
    } else {
      folderName = req.inventoryFolder;
    }

    cb(null, `./uploads/inventory/${folderName}`);
  },

  // Update the filename function to save the inventory folder path
  filename: async (req, file, cb) => {
    const ext = path.extname(file.originalname);
    const uniqueName =
      path.basename(file.originalname, ext) + "-" + Date.now() + ext;

    const details = req.user;
    console.log("inventory upload details", details);

    // Check if this is the first file being processed
    if (!req.fileCount) {
      req.fileCount = 0;
      req.alreadyExists = false;
      req.savedImages = [];

      // Check if inventory already exists for this vendor
      if (details.category === "Photography") {
        await connectInventoryDB(async () => {
          const dupImg = await photographyModel.findOne({
            owner: details.email,
          });
          if (dupImg) {
            console.log("Photography inventory already exists");
            req.alreadyExists = true;
          }
        });
      } else if (details.category === "Venue") {
        await connectInventoryDB(async () => {
          const dupImg = await venueModel.findOne({
            owner: details.email,
          });
          if (dupImg) {
            console.log("Venue inventory already exists");
            req.alreadyExists = true;
          }
        });
      } else if (details.category === "Decoration") {
        await connectInventoryDB(async () => {
          const dupImg = await decoratorModel.findOne({
            owner: details.email,
          });
          if (dupImg) {
            console.log("Decoration inventory already exists");
            req.alreadyExists = true;
          }
        });
      }
    }

    req.fileCount++;

    // If inventory already exists, reject all files
    if (req.alreadyExists) {
      console.log(`Rejecting file ${req.fileCount}: Inventory already exists`);
      return cb(new Error("Inventory already exists"), false);
    }

    // Create appropriate image model based on category
    let image;
    if (details.category === "Photography") {
      image = new photographyImageModel({
        fileName: uniqueName,
        filePath: `uploads/inventory/${req.inventoryFolder}`,
        srcFrom: details.email,
        type: "photography",
      });
    } else if (details.category === "Venue") {
      image = new venueImageModel({
        fileName: uniqueName,
        filePath: `uploads/inventory/${req.inventoryFolder}`,
        srcFrom: details.email,
        type: "venue",
      });
    } else if (details.category === "Decoration") {
      image = new decorationImageModel({
        fileName: uniqueName,
        filePath: `uploads/inventory/${req.inventoryFolder}`,
        srcFrom: details.email,
        type: "decoration",
      });
    }

    try {
      // Save image to database with proper error handling
      await connectInventoryDB(async () => {
        try {
          console.log("imagessssssssssssssssss", image);

          const savedImage = await image.save();
          console.log(
            `File ${req.fileCount} uploaded to database with ID: ${savedImage._id}`
          );
        } catch (dbError) {
          console.error("Database save error:", dbError);
        }
      });

      // Always call the callback to ensure the file is saved to disk
      cb(null, uniqueName);
    } catch (error) {
      console.error("Error in file upload process:", error);
      cb(error, false);
    }
  },
});

// Initialize Multer upload with array support for multiple files
const uploadVendor = multer({ storage: storageVendor });
const uploadUser = multer({ storage: storageUser });
const uploadInventory = multer({ storage: storageInventory });

module.exports = { uploadUser, uploadVendor, uploadInventory };
