"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.mongoIdRequestBodyValidator = exports.mongoIdPathValidator = void 0;
const express_validator_1 = require("express-validator");
const mongoIdPathValidator = (idName) => {
    return [
        (0, express_validator_1.param)(idName)
            .notEmpty()
            .isMongoId()
            .withMessage("Invalid " + idName),
    ];
};
exports.mongoIdPathValidator = mongoIdPathValidator;
const mongoIdRequestBodyValidator = (idName) => {
    return [
        (0, express_validator_1.body)(idName)
            .notEmpty()
            .isMongoId()
            .withMessage("Invalid " + idName),
    ];
};
exports.mongoIdRequestBodyValidator = mongoIdRequestBodyValidator;
//# sourceMappingURL=mongoId.validator.js.map