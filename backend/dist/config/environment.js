"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.DEV_CONFIG = exports.FILE_CONFIG = exports.DATABASE_CONFIG = exports.getCorsUrls = exports.getServerUrl = exports.SERVER_CONFIG = void 0;
const dotenv_1 = __importDefault(require("dotenv"));
dotenv_1.default.config();
// Server Configuration - Change this IP to switch environments
exports.SERVER_CONFIG = {
    ip: process.env.SERVER_IP || "192.168.1.6",
    port: process.env.PORT || "5000",
    useHttps: process.env.USE_HTTPS === "true",
};
// Computed URLs
const getServerUrl = () => {
    const protocol = exports.SERVER_CONFIG.useHttps ? "https" : "http";
    return `${protocol}://${exports.SERVER_CONFIG.ip}:${exports.SERVER_CONFIG.port}`;
};
exports.getServerUrl = getServerUrl;
const getCorsUrls = () => {
    const serverUrl = (0, exports.getServerUrl)();
    const defaultUrls = [
        "http://localhost:5173",
        "http://localhost:3000",
        "http://localhost:8080",
        `${serverUrl}`,
        `http://${exports.SERVER_CONFIG.ip}:5173`,
        `http://${exports.SERVER_CONFIG.ip}:3000`,
        `http://${exports.SERVER_CONFIG.ip}:8080`,
    ];
    const envUrls = process.env.CORS_URL?.split(",") || [];
    return [...new Set([...defaultUrls, ...envUrls])];
};
exports.getCorsUrls = getCorsUrls;
// Database Configuration
exports.DATABASE_CONFIG = {
    host: process.env.DB_HOST || "localhost",
    port: process.env.DB_PORT || "27017",
    name: process.env.DB_NAME || "lan_chat",
    url: process.env.DB_URL ||
        `mongodb://${process.env.DB_HOST || "localhost"}:${process.env.DB_PORT || "27017"}`,
    minPoolSize: parseInt(process.env.DB_MIN_POOL_SIZE || "2"),
    maxPoolSize: parseInt(process.env.DB_MAX_POOL_SIZE || "5"),
};
// File Upload Configuration
exports.FILE_CONFIG = {
    maxSize: parseInt(process.env.MAX_FILE_SIZE || "52428800"), // 50MB default
    uploadPath: process.env.UPLOAD_PATH || "./public/uploads",
    allowedImageTypes: ["image/jpeg", "image/png", "image/gif", "image/webp"],
    allowedVideoTypes: ["video/mp4", "video/avi", "video/mov", "video/wmv"],
    allowedDocumentTypes: [
        "application/pdf",
        "application/msword",
        "application/vnd.openxmlformats-officedocument.wordprocessingml.document",
        "text/plain",
    ],
};
// Development Configuration
exports.DEV_CONFIG = {
    isDevelopment: process.env.NODE_ENV === "development",
    enableLogging: process.env.ENABLE_LOGGING !== "false",
    enableDebug: process.env.ENABLE_DEBUG === "true",
};
//# sourceMappingURL=environment.js.map