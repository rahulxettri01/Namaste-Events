const jwt = require("jsonwebtoken");
const { superAdminModel } = require("../models/superadmin");

const verifySuperAdmin = async (req, res, next) => {
  try {
    const token = req.header("Authorization").replace("Bearer ", "");
    const decoded = jwt.verify(token, process.env.JWT_SECRET);
    const user = await superAdminModel.findOne({
      _id: decoded.id,
      "tokens.token": token,
    });

    if (!user || user.role !== "superadmin") {
      throw new Error();
    }

    req.user = user;
    next();
  } catch (error) {
    res.status(403).send({ error: "Access denied" });
  }
};

module.exports = verifySuperAdmin;
