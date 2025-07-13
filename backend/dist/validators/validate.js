"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.validate = void 0;
const express_validator_1 = require("express-validator");
const ApiError_1 = require("../core/ApiError");
const validate = (req, res, next) => {
    try {
        const errors = (0, express_validator_1.validationResult)(req);
        // if no errors then return next
        if (errors.isEmpty()) {
            return next();
        }
        // if errors
        const extractedErrors = errors
            .array()
            // @ts-ignore
            .map((err) => ({ [err.param]: err.msg }));
        const errorMsg = extractedErrors
            .map((err) => Object.values(err).join(", "))
            .join(", ");
        next(new ApiError_1.BadRequestError(errorMsg));
    }
    catch (error) {
        next(error);
    }
};
exports.validate = validate;
//# sourceMappingURL=validate.js.map