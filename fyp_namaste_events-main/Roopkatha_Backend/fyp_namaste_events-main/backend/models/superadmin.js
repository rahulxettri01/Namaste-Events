const mongoose = require("mongoose");

const superAdminSchema = new mongoose.Schema({
  userName: { type: String, required: true },
  email: { type: String, required: true, unique: true },
  password: { type: String, required: true },
  role: { type: String, default: "superadmin" },
  createdAt: { type: Date, default: Date.now },
});

const superAdminModel = mongoose.model("superAdmins", superAdminSchema);

module.exports = { superAdminModel };
