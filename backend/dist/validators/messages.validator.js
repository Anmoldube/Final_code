"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.messagesValidator = void 0;
const express_validator_1 = require("express-validator");
const messagesValidator = () => {
    return [
        (0, express_validator_1.body)("content")
            .trim()
            .optional()
            .notEmpty()
            .withMessage("content is required"),
    ];
};
exports.messagesValidator = messagesValidator;
//# sourceMappingURL=messages.validator.js.map