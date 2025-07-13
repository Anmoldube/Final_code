"use strict";
// src/helpers/colorsUtils.ts
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
const colors_1 = __importDefault(require("colors"));
const colorsStyles = {
    // Define various styles
    error: colors_1.default.red.bold,
    warning: colors_1.default.yellow,
    success: colors_1.default.green,
    info: colors_1.default.blue,
    debug: colors_1.default.gray,
};
const colorsUtils = {
    // Function to apply a style based on a type
    log: (type, message) => {
        switch (type) {
            case "error":
                console.error(colorsStyles.error(message));
                break;
            case "warning":
                console.warn(colorsStyles.warning(message));
                break;
            case "success":
                console.log(colorsStyles.success(message));
                break;
            case "info":
                console.log(colorsStyles.info(message));
                break;
            case "debug":
                console.log(colorsStyles.debug(message));
                break;
            default:
                console.log(message);
                break;
        }
    },
};
exports.default = colorsUtils;
//# sourceMappingURL=colorsUtils.js.map