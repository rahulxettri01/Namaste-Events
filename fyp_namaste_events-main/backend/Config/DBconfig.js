const mongoose = require("mongoose");
const dotenv = require("dotenv");

dotenv.config();

const connectUserDB = async (callback) => {
  try {
    await mongoose.connect(process.env.DATABASE_User).then(async () => {
      console.log("User DB connected");
      await callback();
    });
  } catch (error) {
    console.error(`Error: ${error.message}`); // Log the error message
  } finally {
    // await mongoose.connection.close();
    console.log("User DB connection closed");
  }
};

const connectInventoryDB = async (callback) => {
  try {
    await mongoose.connect(process.env.DATABASE_Vendor).then(async () => {
      console.log("Inventory DB connected");
      await callback(); // Execute the passed database operation
    });
  } catch (error) {
    console.error(`Error in conInvDB: ${error.message}`); // Log the error message
  } finally {
    // await mongoose.connection.close();
    console.log("Inventory DB connection closed");
  }
};

const connectSuperAdminDB = async (callback) => {
  try {
    await mongoose.connect(process.env.DATABASE_Super_Admin).then(async () => {
      console.log("Super Admin DB connected");
      await callback();
    });
  } catch (error) {
    console.error(`Error: ${error.message}`); // Log the error message
  } finally {
    // await mongoose.connection.close();
    console.log("Super Admin DB connection closed");
  }
};

module.exports = {
  connectUserDB,
  connectInventoryDB,
  connectSuperAdminDB,
};
