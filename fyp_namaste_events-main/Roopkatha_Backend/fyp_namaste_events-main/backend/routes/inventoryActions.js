const express = require("express");
const VerifyJWT = require("../middleware/VerifyJWT");
const router = express.Router();
const { connectInventoryDB } = require("../Config/DBconfig");
// const { venueModel } = require("../models/venue");
// const { decoratorModel } = require("../models/decoration");
// const { photographyModel } = require("../models/photography");
const {
  photographyModel,
  decoratorModel,
  venueModel,
} = require("../models/vendor");
const { photographyImageModel, venueImageModel } = require("../models/image");
const { uploadInventory } = require("../Config/multerConfig");

const venueData = [];

// POST API to add inventory
router.post(
  "/add_inventory",
  VerifyJWT,
  uploadInventory.array("files"),
  async (req, res) => {
    console.log("back hit");
    if (req.alreadyExists) {
      console.log("iiin already exists");

      return res.status(400).json({
        status_code: 400,
        message: "Inventory already exists. Please check details",
      });
    }
    const vdata = {
      owner: req.user["email"],
      inventoryName: req.body.inventoryName,
      address: req.body.address,
      price: req.body.price,
      description: req.body.description,
      accommodation: req.body.accommodation,
      image: req.file ? req.file.path : null,
    };

    venueData.push(vdata);
    let existInventory = null;

    console.log(vdata);

    let category = req.user["category"];

    if (category == "Venue") {
      vdata.venueName = vdata.inventoryName;
      delete vdata.inventoryName;
      await connectInventoryDB(async () => {
        existInventory = await venueModel.findOne({
          venueName: vdata.venueName,
        });
      });

      if (existInventory) {
        return res.status(400).json({
          status_code: 400,
          message: "Venue already exists. Please check details",
        });
      } else {
        const newVenue = new venueModel(vdata);
        await connectInventoryDB(async () => {
          await newVenue.save();
        });
        return res.status(200).send({
          status_code: 200,
          message: "Venue added successfully",
        });
      }
    } else if (category == "Decoration") {
      vdata.decoratorName = vdata.inventoryName;
      delete vdata.inventoryName;
      await connectInventoryDB(async () => {
        existInventory = await decoratorModel.findOne({
          decoratorName: vdata.decoratorName,
        });
      });

      if (existInventory) {
        return res.status(400).json({
          status_code: 400,
          message: "Decorator already exists. Please check details",
        });
      } else {
        const newDecorator = new decoratorModel(vdata);
        await connectInventoryDB(async () => {
          await newDecorator.save();
        });
        return res.status(200).send({
          status_code: 200,
          message: "Decorator added successfully",
        });
      }
    } else if (category == "Photography") {
      vdata.photographyName = vdata.inventoryName;
      delete vdata.inventoryName;

      await connectInventoryDB(async () => {
        existInventory = await photographyModel.findOne({
          photographyName: vdata.photographyName,
        });
      });

      if (existInventory) {
        return res.status(400).json({
          status_code: 400,
          message: "Photographer already exists. Please check details",
        });
      } else {
        const newPhotographer = new photographyModel(vdata);
        newPhotographer.owner = req.user["email"];
        newPhotographer["owner"] = req.user["email"];
        console.log("newPhotographer", newPhotographer);

        await connectInventoryDB(async () => {
          await newPhotographer.save();
        });
        return res.status(200).send({
          status_code: 200,
          message: "Photographer added successfully",
        });
      }
    }
  }
);

// GET API to fetch all inventories
router.get("/get_inventory", VerifyJWT, async (req, res) => {
  try {
    console.log("cat", req.user);

    let inventories = [];
    await connectInventoryDB(async () => {
      if (req.user["category"] == "Venue") {
        const venues = await venueModel.find({ owner: req.user["email"] });
        inventories = [...venues];
      } else if (req.user["category"] == "Decoration") {
        const decorators = await decoratorModel.find({
          owner: req.user["email"],
        });
        inventories = [...decorators];
      } else if (req.user["category"] == "Photography") {
        const photographers = await photographyModel.find({
          owner: req.user["email"],
        });
        inventories = [...photographers];
      }
    });
    console.log("lllllslslslsl", inventories);

    return res.status(200).json({
      success: true,
      data: inventories,
    });
  } catch (error) {
    console.error("Error fetching inventories:", error);
    return res.status(500).json({
      success: false,
      message: "Server error while fetching inventory",
    });
  }
});

// PUT API to update inventory
router.put("/update/:id", VerifyJWT, async (req, res) => {
  try {
    const { id } = req.params;
    const updateData = req.body;
    let updatedInventory;

    console.log("Updating inventory with ID:", id);
    console.log("Update data:", updateData);
    console.log("User category:", req.user.category);
    console.log("User email:", req.user.email);

    // Verify owner matches the authenticated user
    if (updateData.owner && updateData.owner !== req.user.email) {
      return res.status(403).json({
        success: false,
        message: "You don't have permission to update this inventory",
      });
    }

    await connectInventoryDB(async () => {
      if (req.user.category === "Venue") {
        // Find the venue by ID and owner for security
        const venue = await venueModel.findOne({
          _id: id,
          owner: req.user.email,
        });

        if (!venue) {
          return res.status(404).json({
            success: false,
            message: "Venue not found or you don't have permission",
          });
        }

        // Update the venue with new data
        updatedInventory = await venueModel.findByIdAndUpdate(id, updateData, {
          new: true,
        });
      } else if (req.user.category === "Decoration") {
        // Find the decorator by ID and owner for security
        const decorator = await decoratorModel.findOne({
          _id: id,
          owner: req.user.email,
        });

        if (!decorator) {
          return res.status(404).json({
            success: false,
            message: "Decorator not found or you don't have permission",
          });
        }

        // Update the decorator with new data
        updatedInventory = await decoratorModel.findByIdAndUpdate(
          id,
          updateData,
          { new: true }
        );
      } else if (req.user.category === "Photography") {
        // Find the photographer by ID and owner for security
        const photographer = await photographyModel.findOne({
          _id: id,
          owner: req.user.email,
        });

        if (!photographer) {
          return res.status(404).json({
            success: false,
            message: "Photographer not found or you don't have permission",
          });
        }

        // Update the photographer with new data
        updatedInventory = await photographyModel.findByIdAndUpdate(
          id,
          updateData,
          { new: true }
        );
      }
    });

    if (!updatedInventory) {
      return res.status(404).json({
        success: false,
        message: "Inventory not found or update failed",
      });
    }

    console.log("Updated inventory:", updatedInventory);

    return res.status(200).json({
      success: true,
      data: updatedInventory,
      message: "Inventory updated successfully",
    });
  } catch (error) {
    console.error("Error updating inventory:", error);
    return res.status(500).json({
      success: false,
      message: "Server error while updating inventory: " + error.message,
    });
  }
});

// DELETE API to delete inventory
router.delete("/delete/:id", VerifyJWT, async (req, res) => {
  try {
    const { id } = req.params;
    console.log("Deleting inventory with ID:", id);
    console.log("User category:", req.user.category);
    console.log("User email:", req.user.email);

    let deletedInventory;
    let modelToUse;

    // Determine which model to use based on user category
    if (req.user.category === "Venue") {
      modelToUse = venueModel;
    } else if (req.user.category === "Decoration") {
      modelToUse = decoratorModel;
    } else if (req.user.category === "Photography") {
      modelToUse = photographyModel;
    } else {
      return res.status(400).json({
        success: false,
        message: "Invalid user category",
      });
    }

    await connectInventoryDB(async () => {
      // Find the inventory by ID and owner for security
      const inventory = await modelToUse.findOne({
        _id: id,
        owner: req.user.email,
      });

      if (!inventory) {
        return res.status(404).json({
          success: false,
          message:
            "Inventory not found or you don't have permission to delete it",
        });
      }

      // Delete the inventory
      deletedInventory = await modelToUse.findByIdAndDelete(id);
    });

    if (!deletedInventory) {
      return res.status(404).json({
        success: false,
        message: "Inventory not found or delete failed",
      });
    }

    console.log("Deleted inventory:", deletedInventory);

    return res.status(200).json({
      success: true,
      message: "Inventory deleted successfully",
    });
  } catch (error) {
    console.error("Error deleting inventory:", error);
    return res.status(500).json({
      success: false,
      message: "Server error while deleting inventory: " + error.message,
    });
  }
});
module.exports = router;
