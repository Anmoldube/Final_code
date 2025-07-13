"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.tokenInfo = exports.cookieValidity = exports.corsUrl = exports.db = exports.serverUrl = exports.port = exports.environment = void 0;
const dotenv_1 = __importDefault(require("dotenv"));
const environment_1 = require("./config/environment");
dotenv_1.default.config();
exports.environment = process.env.NODE_ENV;
exports.port = environment_1.SERVER_CONFIG.port;
exports.serverUrl = (0, environment_1.getServerUrl)();
exports.db = {
    name: environment_1.DATABASE_CONFIG.name,
    url: environment_1.DATABASE_CONFIG.url,
    minPoolSize: environment_1.DATABASE_CONFIG.minPoolSize,
    maxPoolSize: environment_1.DATABASE_CONFIG.maxPoolSize,
};
// Get CORS URLs from environment configuration
exports.corsUrl = (0, environment_1.getCorsUrls)();
console.log('CORS URLs:', exports.corsUrl);
exports.cookieValidity = process.env.COOKIE_VALIDITY_SEC || "0";
exports.tokenInfo = {
    jwtSecretKey: process.env.JWT_SECRET_KEY || "",
    accessTokenValidity: parseInt(process.env.ACCESS_TOKEN_VALIDITY_SEC || "0"),
    refreshTokenValidity: parseInt(process.env.REFRESH_TOKEN_VALIDITY_SEC || "0"),
    issuer: process.env.TOKEN_ISSUER || "",
    audience: process.env.TOKEN_AUDIENCE || "",
};
//# sourceMappingURL=config.js.map