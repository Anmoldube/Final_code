"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.getLocalFilePath = exports.getFileUrl = exports.upload = void 0;
const multer_1 = __importDefault(require("multer"));
const path_1 = __importDefault(require("path"));
const fs_1 = __importDefault(require("fs"));
const ApiError_1 = require("../core/ApiError");
// Create uploads directory if it doesn't exist
const uploadDir = path_1.default.join(__dirname, '../../public/uploads');
const avatarDir = path_1.default.join(uploadDir, 'avatars');
// Ensure directories exist
if (!fs_1.default.existsSync(uploadDir)) {
    fs_1.default.mkdirSync(uploadDir, { recursive: true });
}
if (!fs_1.default.existsSync(avatarDir)) {
    fs_1.default.mkdirSync(avatarDir, { recursive: true });
}
// Log the directories for debugging
console.log('Upload directory:', uploadDir);
console.log('Avatar directory:', avatarDir);
// Configure storage
const storage = multer_1.default.diskStorage({
    destination: function (req, file, cb) {
        // Store avatars in a dedicated directory
        if (file.fieldname === 'avatar') {
            cb(null, avatarDir);
        }
        else {
            cb(null, uploadDir);
        }
    },
    filename: function (req, file, cb) {
        // Clean the original filename (remove spaces, special chars)
        const originalName = file.originalname
            .split(" ")
            .join("-")
            .replace(/[^a-zA-Z0-9-_.]/g, "");
        // Generate a unique filename with original name, timestamp and original extension
        const uniqueSuffix = Date.now() + '-' + Math.round(Math.random() * 1E9);
        const ext = path_1.default.extname(originalName);
        const nameWithoutExt = path_1.default.basename(originalName, ext);
        // Format: originalname-timestamp-random.ext
        cb(null, `${nameWithoutExt}-${uniqueSuffix}${ext}`);
    }
});
// File filter to only allow certain file types
const fileFilter = (req, file, cb) => {
    // Accept images only
    if (file.mimetype.startsWith('image/')) {
        cb(null, true);
    }
    else {
        cb(new ApiError_1.BadRequestError('Only image files are allowed!'));
    }
};
// Create multer instance with configuration
exports.upload = (0, multer_1.default)({
    storage: storage,
    fileFilter: fileFilter,
    limits: {
        fileSize: 5 * 1024 * 1024, // 5MB max file size
    }
});
// Helper function to get the URL for an uploaded file
const getFileUrl = (filename, type = 'attachment') => {
    // For LAN/offline environment, use a relative URL instead of an absolute URL
    // This ensures the URL will work regardless of the server's hostname or IP
    const pathSegment = type === 'avatar' ? 'avatars' : '';
    // Return a relative URL without a timestamp to avoid caching issues
    // Note: Files in the public directory are served at the root path, so we remove the '/public' prefix
    return `/uploads/${pathSegment}/${filename}`;
};
exports.getFileUrl = getFileUrl;
// Helper function to get the local file path
const getLocalFilePath = (filename, type = 'attachment') => {
    const dir = type === 'avatar' ? avatarDir : uploadDir;
    return path_1.default.join(dir, filename);
};
exports.getLocalFilePath = getLocalFilePath;
//# sourceMappingURL=multer.js.map