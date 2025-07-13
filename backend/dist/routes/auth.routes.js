"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
const express_1 = __importDefault(require("express"));
const user_controller_1 = require("../controllers/user.controller");
const user_validators_1 = require("../validators/user.validators");
const validate_1 = require("../validators/validate");
const router = express_1.default.Router();
// Auth routes (matching client expectations)
router.post("/register", (0, user_validators_1.userRegisterValidator)(), validate_1.validate, user_controller_1.signUp);
router.post("/login", (0, user_validators_1.userLoginValidator)(), validate_1.validate, user_controller_1.login);
router.post("/logout", user_controller_1.logout);
router.post("/refresh", user_controller_1.refreshToken);
exports.default = router;
//# sourceMappingURL=auth.routes.js.map