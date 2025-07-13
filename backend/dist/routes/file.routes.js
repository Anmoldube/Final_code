"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
const express_1 = require("express");
const auth_middlewares_1 = require("../middlewares/auth.middlewares");
const path_1 = __importDefault(require("path"));
const fs_1 = __importDefault(require("fs"));
const ApiError_1 = require("../core/ApiError");
const ApiResponse_1 = require("../core/ApiResponse");
const fileUpload_controller_1 = require("../controllers/fileUpload.controller");
const router = (0, express_1.Router)();
// File upload routes
router.post("/upload", auth_middlewares_1.verifyJWT, fileUpload_controller_1.uploadFile);
router.get("/info/:filename", auth_middlewares_1.verifyJWT, fileUpload_controller_1.getFileInfo);
router.delete("/:filename", auth_middlewares_1.verifyJWT, fileUpload_controller_1.deleteFile);
// File download route with authentication
router.get("/download/*", auth_middlewares_1.verifyJWT, (req, res) => {
    try {
        // Get the file path from the URL
        const filePath = req.params[0]; // This captures everything after /download/
        if (!filePath) {
            throw new ApiError_1.BadRequestError("No file path provided");
        }
        console.log(`📁 File download request: ${filePath}`);
        // Construct the full file path
        const fullPath = path_1.default.join(__dirname, "..", "..", "public", "uploads", filePath);
        const normalizedPath = path_1.default.normalize(fullPath);
        console.log(`📁 Looking for file at: ${normalizedPath}`);
        // Security check - ensure the file is within the uploads directory
        const uploadsDir = path_1.default.join(__dirname, "..", "..", "public", "uploads");
        if (!normalizedPath.startsWith(uploadsDir)) {
            throw new ApiError_1.BadRequestError("Invalid file path");
        }
        // Check if file exists
        if (!fs_1.default.existsSync(normalizedPath)) {
            console.log(`❌ File not found: ${normalizedPath}`);
            // Try to find the file in subdirectories
            const fileName = path_1.default.basename(filePath);
            const possibleDirs = ['images', 'documents', 'videos', 'audio', 'other'];
            for (const dir of possibleDirs) {
                const possiblePath = path_1.default.join(uploadsDir, dir, fileName);
                if (fs_1.default.existsSync(possiblePath)) {
                    console.log(`✅ File found in ${dir} directory: ${possiblePath}`);
                    return res.sendFile(possiblePath);
                }
            }
            throw new ApiError_1.NotFoundError("File not found");
        }
        // Get file stats for headers
        const stats = fs_1.default.statSync(normalizedPath);
        const fileName = path_1.default.basename(normalizedPath);
        // Set appropriate headers
        res.setHeader('Content-Disposition', `attachment; filename="${fileName}"`);
        res.setHeader('Content-Length', stats.size);
        res.setHeader('Cache-Control', 'public, max-age=86400'); // Cache for 24 hours
        // Set content type based on file extension
        const ext = path_1.default.extname(fileName).toLowerCase();
        const mimeTypes = {
            '.pdf': 'application/pdf',
            '.doc': 'application/msword',
            '.docx': 'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
            '.xls': 'application/vnd.ms-excel',
            '.xlsx': 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
            '.jpg': 'image/jpeg',
            '.jpeg': 'image/jpeg',
            '.png': 'image/png',
            '.gif': 'image/gif',
            '.mp4': 'video/mp4',
            '.mp3': 'audio/mpeg',
            '.txt': 'text/plain',
            '.zip': 'application/zip',
        };
        if (mimeTypes[ext]) {
            res.setHeader('Content-Type', mimeTypes[ext]);
        }
        console.log(`✅ Serving file: ${fileName} (${stats.size} bytes)`);
        // Send the file
        res.sendFile(normalizedPath);
    }
    catch (error) {
        console.error(`❌ File download error:`, error);
        if (error instanceof ApiError_1.BadRequestError) {
            return new ApiResponse_1.BadRequestResponse(error.message).send(res);
        }
        else if (error instanceof ApiError_1.NotFoundError) {
            return new ApiResponse_1.NotFoundResponse(error.message).send(res);
        }
        else {
            return res.status(500).json({ error: "Internal server error" });
        }
    }
});
// File info route (check if file exists and get metadata)
router.get("/info/*", auth_middlewares_1.verifyJWT, (req, res) => {
    try {
        const filePath = req.params[0];
        if (!filePath) {
            throw new ApiError_1.BadRequestError("No file path provided");
        }
        // Construct the full file path
        const fullPath = path_1.default.join(__dirname, "..", "..", "public", "uploads", filePath);
        const normalizedPath = path_1.default.normalize(fullPath);
        // Security check
        const uploadsDir = path_1.default.join(__dirname, "..", "..", "public", "uploads");
        if (!normalizedPath.startsWith(uploadsDir)) {
            throw new ApiError_1.BadRequestError("Invalid file path");
        }
        let fileExists = false;
        let fileStats = null;
        let actualPath = normalizedPath;
        // Check if file exists
        if (fs_1.default.existsSync(normalizedPath)) {
            fileExists = true;
            fileStats = fs_1.default.statSync(normalizedPath);
        }
        else {
            // Try to find the file in subdirectories
            const fileName = path_1.default.basename(filePath);
            const possibleDirs = ['images', 'documents', 'videos', 'audio', 'other'];
            for (const dir of possibleDirs) {
                const possiblePath = path_1.default.join(uploadsDir, dir, fileName);
                if (fs_1.default.existsSync(possiblePath)) {
                    fileExists = true;
                    fileStats = fs_1.default.statSync(possiblePath);
                    actualPath = possiblePath;
                    break;
                }
            }
        }
        res.json({
            exists: fileExists,
            path: filePath,
            actualPath: fileExists ? path_1.default.relative(uploadsDir, actualPath) : null,
            size: fileStats ? fileStats.size : null,
            lastModified: fileStats ? fileStats.mtime : null,
            isFile: fileStats ? fileStats.isFile() : false,
        });
    }
    catch (error) {
        console.error(`❌ File info error:`, error);
        if (error instanceof ApiError_1.BadRequestError) {
            return new ApiResponse_1.BadRequestResponse(error.message).send(res);
        }
        else {
            return res.status(500).json({ error: "Internal server error" });
        }
    }
});
exports.default = router;
//# sourceMappingURL=file.routes.js.map