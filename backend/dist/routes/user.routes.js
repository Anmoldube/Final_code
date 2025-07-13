"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
const express_1 = __importDefault(require("express"));
const user_controller_1 = require("../controllers/user.controller");
const user_validators_1 = require("../validators/user.validators");
const validate_1 = require("../validators/validate");
const auth_middlewares_1 = require("../middlewares/auth.middlewares");
const multer_1 = require("../helpers/multer");
const router = express_1.default.Router();
router.post("/register", (0, user_validators_1.userRegisterValidator)(), validate_1.validate, user_controller_1.signUp);
router.post("/login", (0, user_validators_1.userLoginValidator)(), validate_1.validate, user_controller_1.login);
router.post("/logout", user_controller_1.logout);
router.post("/refresh", user_controller_1.refreshToken);
// Protected routes (require authentication)
router.use(auth_middlewares_1.verifyJWT);
router.put("/profile", (0, user_validators_1.userProfileUpdateValidator)(), validate_1.validate, user_controller_1.updateProfile);
router.post("/avatar", multer_1.upload.single("avatar"), user_controller_1.updateAvatar);
router.post("/change-password", (0, user_validators_1.changePasswordValidator)(), validate_1.validate, user_controller_1.changePassword);
exports.default = router;
//# sourceMappingURL=user.routes.js.map