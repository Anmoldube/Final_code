"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.changePasswordValidator = exports.userProfileUpdateValidator = exports.userLoginValidator = exports.userRegisterValidator = void 0;
const express_validator_1 = require("express-validator");
const userRegisterValidator = () => {
    return [
        (0, express_validator_1.body)("email")
            .trim()
            .notEmpty()
            .withMessage("email is required")
            .isEmail()
            .withMessage("invalid email address"),
        (0, express_validator_1.body)("username")
            .trim()
            .notEmpty()
            .withMessage("username is required")
            .isLowercase()
            .withMessage("username must be in lowercase")
            .isLength({ min: 3 })
            .withMessage("username must contain at least 3 characters"),
        (0, express_validator_1.body)("password")
            .trim()
            .notEmpty()
            .withMessage("password is required")
            .isLength({ min: 4 })
            .withMessage("password must contain at least 4 characters"),
    ];
};
exports.userRegisterValidator = userRegisterValidator;
const userLoginValidator = () => {
    return [
        (0, express_validator_1.body)("userId").trim().notEmpty().withMessage("userId is required"),
        (0, express_validator_1.body)("password").trim().notEmpty().withMessage("password is required"),
    ];
};
exports.userLoginValidator = userLoginValidator;
const userProfileUpdateValidator = () => {
    return [
        (0, express_validator_1.body)("username")
            .optional()
            .trim()
            .isLength({ min: 3 })
            .withMessage("username must contain at least 3 characters")
            .isLowercase()
            .withMessage("username must be in lowercase"),
        (0, express_validator_1.body)("bio")
            .optional()
            .trim()
            .isLength({ max: 200 })
            .withMessage("bio must not exceed 200 characters"),
        (0, express_validator_1.body)("statusMessage")
            .optional()
            .trim()
            .isLength({ max: 100 })
            .withMessage("status message must not exceed 100 characters"),
    ];
};
exports.userProfileUpdateValidator = userProfileUpdateValidator;
const changePasswordValidator = () => {
    return [
        (0, express_validator_1.body)("currentPassword")
            .trim()
            .notEmpty()
            .withMessage("current password is required"),
        (0, express_validator_1.body)("newPassword")
            .trim()
            .notEmpty()
            .withMessage("new password is required")
            .isLength({ min: 6 })
            .withMessage("new password must contain at least 6 characters"),
    ];
};
exports.changePasswordValidator = changePasswordValidator;
//# sourceMappingURL=user.validators.js.map