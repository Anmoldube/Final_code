"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.deleteFile = exports.getFileInfo = exports.uploadFile = void 0;
const ApiError_1 = require("../core/ApiError");
const ApiResponse_1 = require("../core/ApiResponse");
const asyncHandler_1 = __importDefault(require("../helpers/asyncHandler"));
const multer_1 = __importDefault(require("multer"));
const path_1 = __importDefault(require("path"));
const fs_1 = __importDefault(require("fs"));
// Configure multer for file uploads
const storage = multer_1.default.diskStorage({
    destination: (req, file, cb) => {
        const uploadPath = path_1.default.join(__dirname, "..", "..", "public", "uploads", "temp");
        // Ensure temp directory exists
        if (!fs_1.default.existsSync(uploadPath)) {
            fs_1.default.mkdirSync(uploadPath, { recursive: true });
        }
        cb(null, uploadPath);
    },
    filename: (req, file, cb) => {
        // Generate unique filename with timestamp
        const uniqueSuffix = Date.now() + '-' + Math.round(Math.random() * 1E9);
        const ext = path_1.default.extname(file.originalname);
        const name = path_1.default.basename(file.originalname, ext);
        cb(null, `${name}-${uniqueSuffix}${ext}`);
    }
});
const upload = (0, multer_1.default)({
    storage,
    limits: {
        fileSize: 50 * 1024 * 1024, // 50MB limit
    },
    fileFilter: (req, file, cb) => {
        // Allow all file types for now
        cb(null, true);
    }
});
// Helper function to determine file category based on MIME type
function getFileCategory(mimeType) {
    if (mimeType.startsWith('image/'))
        return 'images';
    if (mimeType.startsWith('video/'))
        return 'videos';
    if (mimeType.startsWith('audio/'))
        return 'audio';
    if (mimeType.includes('pdf'))
        return 'documents';
    if (mimeType.includes('document') || mimeType.includes('text') ||
        mimeType.includes('spreadsheet') || mimeType.includes('presentation')) {
        return 'documents';
    }
    return 'files';
}
// Regular file upload (non-encrypted)
exports.uploadFile = (0, asyncHandler_1.default)(async (req, res) => {
    const uploadMiddleware = upload.single('file');
    uploadMiddleware(req, res, async (err) => {
        if (err) {
            console.error('❌ File upload error:', err);
            throw new ApiError_1.BadRequestError('File upload failed: ' + err.message);
        }
        if (!req.file) {
            throw new ApiError_1.BadRequestError('No file uploaded');
        }
        try {
            const category = getFileCategory(req.file.mimetype);
            const finalDir = path_1.default.join(__dirname, "..", "..", "public", "uploads", category);
            // Ensure category directory exists
            if (!fs_1.default.existsSync(finalDir)) {
                fs_1.default.mkdirSync(finalDir, { recursive: true });
            }
            const finalPath = path_1.default.join(finalDir, req.file.filename);
            // Move file from temp to final location
            fs_1.default.renameSync(req.file.path, finalPath);
            const fileUrl = `/uploads/${category}/${req.file.filename}`;
            const relativePath = `${category}/${req.file.filename}`;
            console.log(`✅ File uploaded successfully: ${fileUrl}`);
            // Save file metadata to database
            const { FileMetadataService } = require('../services/FileMetadataService');
            const fileMetadata = await FileMetadataService.createFileMetadata({
                originalName: req.file.originalname,
                fileName: req.file.filename,
                filePath: relativePath,
                mimeType: req.file.mimetype,
                fileSize: req.file.size,
                uploadedBy: req.user?._id || 'unknown',
                metadata: {
                    category,
                    isEncrypted: false,
                }
            });
            console.log(`📊 File metadata saved to database: ${fileMetadata.id}`);
            return new ApiResponse_1.SuccessResponse("File uploaded successfully", {
                id: fileMetadata.id,
                url: fileUrl,
                localPath: relativePath,
                originalName: req.file.originalname,
                type: req.file.mimetype,
                size: req.file.size,
                category,
                isEncrypted: false,
                metadata: fileMetadata,
            }).send(res);
        }
        catch (error) {
            // Clean up temp file if it exists
            if (req.file && fs_1.default.existsSync(req.file.path)) {
                fs_1.default.unlinkSync(req.file.path);
            }
            console.error('❌ File processing error:', error);
            throw new ApiError_1.InternalError('Failed to process uploaded file');
        }
    });
});
// Get file info
exports.getFileInfo = (0, asyncHandler_1.default)(async (req, res) => {
    const { filename } = req.params;
    if (!filename) {
        throw new ApiError_1.BadRequestError('Filename is required');
    }
    // Search for file in all categories
    const categories = ['images', 'videos', 'audio', 'documents', 'files'];
    let fileInfo = null;
    for (const category of categories) {
        const filePath = path_1.default.join(__dirname, "..", "..", "public", "uploads", category, filename);
        if (fs_1.default.existsSync(filePath)) {
            const stats = fs_1.default.statSync(filePath);
            fileInfo = {
                filename,
                category,
                size: stats.size,
                createdAt: stats.birthtime,
                modifiedAt: stats.mtime,
                url: `/uploads/${category}/${filename}`,
            };
            break;
        }
    }
    if (!fileInfo) {
        throw new ApiError_1.BadRequestError('File not found');
    }
    return new ApiResponse_1.SuccessResponse("File info retrieved successfully", fileInfo).send(res);
});
// Delete file
exports.deleteFile = (0, asyncHandler_1.default)(async (req, res) => {
    const { filename } = req.params;
    if (!filename) {
        throw new ApiError_1.BadRequestError('Filename is required');
    }
    // Search for file in all categories
    const categories = ['images', 'videos', 'audio', 'documents', 'files'];
    let fileDeleted = false;
    for (const category of categories) {
        const filePath = path_1.default.join(__dirname, "..", "..", "public", "uploads", category, filename);
        if (fs_1.default.existsSync(filePath)) {
            fs_1.default.unlinkSync(filePath);
            fileDeleted = true;
            console.log(`🗑️ File deleted successfully: ${filename}`);
            break;
        }
    }
    if (!fileDeleted) {
        throw new ApiError_1.BadRequestError('File not found');
    }
    return new ApiResponse_1.SuccessResponse("File deleted successfully", { filename }).send(res);
});
//# sourceMappingURL=fileUpload.controller.js.map