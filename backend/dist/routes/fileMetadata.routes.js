"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
const express_1 = __importDefault(require("express"));
const fileMetadata_controller_1 = require("../controllers/fileMetadata.controller");
const auth_middlewares_1 = require("../middlewares/auth.middlewares");
const validate_1 = require("../validators/validate");
const express_validator_1 = require("express-validator");
const router = express_1.default.Router();
// Apply authentication to all routes
router.use(auth_middlewares_1.verifyJWT);
// Validation schemas
const fileIdValidation = [
    (0, express_validator_1.param)('fileId').isMongoId().withMessage('Invalid file ID format'),
];
const messageIdValidation = [
    (0, express_validator_1.param)('messageId').isMongoId().withMessage('Invalid message ID format'),
];
const chatIdValidation = [
    (0, express_validator_1.param)('chatId').isMongoId().withMessage('Invalid chat ID format'),
];
const userIdValidation = [
    (0, express_validator_1.param)('userId').isMongoId().withMessage('Invalid user ID format'),
];
const paginationValidation = [
    (0, express_validator_1.query)('limit').optional().isInt({ min: 1, max: 100 }).withMessage('Limit must be between 1 and 100'),
    (0, express_validator_1.query)('skip').optional().isInt({ min: 0 }).withMessage('Skip must be a non-negative integer'),
];
const updateFileValidation = [
    (0, express_validator_1.body)('originalName').optional().isString().trim().isLength({ min: 1 }).withMessage('Original name must be a non-empty string'),
    (0, express_validator_1.body)('thumbnailUrl').optional().isURL().withMessage('Thumbnail URL must be a valid URL'),
    (0, express_validator_1.body)('duration').optional().isInt({ min: 0 }).withMessage('Duration must be a non-negative integer'),
    (0, express_validator_1.body)('dimensions.width').optional().isInt({ min: 0 }).withMessage('Width must be a non-negative integer'),
    (0, express_validator_1.body)('dimensions.height').optional().isInt({ min: 0 }).withMessage('Height must be a non-negative integer'),
];
const searchValidation = [
    (0, express_validator_1.query)('searchTerm').optional().isString().trim().isLength({ min: 1 }).withMessage('Search term must be a non-empty string'),
    (0, express_validator_1.query)('fileType').optional().isString().trim().withMessage('File type must be a string'),
    (0, express_validator_1.query)('chatId').optional().isMongoId().withMessage('Invalid chat ID format'),
    (0, express_validator_1.query)('uploadedBy').optional().isMongoId().withMessage('Invalid user ID format'),
    (0, express_validator_1.query)('dateFrom').optional().isISO8601().withMessage('Date from must be a valid ISO date'),
    (0, express_validator_1.query)('dateTo').optional().isISO8601().withMessage('Date to must be a valid ISO date'),
    ...paginationValidation,
];
const attachmentMetadataValidation = [
    (0, express_validator_1.body)('attachmentIds').isArray({ min: 1 }).withMessage('Attachment IDs must be a non-empty array'),
    (0, express_validator_1.body)('attachmentIds.*').isMongoId().withMessage('Each attachment ID must be a valid MongoDB ID'),
];
// Routes
/**
 * @route GET /api/files/my-files
 * @desc Get current user's files
 * @access Private
 */
router.get('/my-files', paginationValidation, validate_1.validate, fileMetadata_controller_1.FileMetadataController.getCurrentUserFiles);
/**
 * @route GET /api/files/stats
 * @desc Get file statistics
 * @access Private
 */
router.get('/stats', (0, express_validator_1.query)('userId').optional().isMongoId().withMessage('Invalid user ID format'), validate_1.validate, fileMetadata_controller_1.FileMetadataController.getFileStatistics);
/**
 * @route GET /api/files/search
 * @desc Search files
 * @access Private
 */
router.get('/search', searchValidation, validate_1.validate, fileMetadata_controller_1.FileMetadataController.searchFiles);
/**
 * @route GET /api/files/message/:messageId
 * @desc Get files by message ID
 * @access Private
 */
router.get('/message/:messageId', messageIdValidation, paginationValidation, validate_1.validate, fileMetadata_controller_1.FileMetadataController.getFilesByMessage);
/**
 * @route GET /api/files/chat/:chatId
 * @desc Get files by chat ID
 * @access Private
 */
router.get('/chat/:chatId', chatIdValidation, paginationValidation, validate_1.validate, fileMetadata_controller_1.FileMetadataController.getFilesByChat);
/**
 * @route GET /api/files/user/:userId
 * @desc Get files by user ID
 * @access Private
 */
router.get('/user/:userId', userIdValidation, paginationValidation, validate_1.validate, fileMetadata_controller_1.FileMetadataController.getFilesByUser);
/**
 * @route GET /api/files/:fileId
 * @desc Get file metadata by ID
 * @access Private
 */
router.get('/:fileId', fileIdValidation, validate_1.validate, fileMetadata_controller_1.FileMetadataController.getFileMetadata);
/**
 * @route PUT /api/files/:fileId
 * @desc Update file metadata
 * @access Private
 */
router.put('/:fileId', fileIdValidation, updateFileValidation, validate_1.validate, fileMetadata_controller_1.FileMetadataController.updateFileMetadata);
/**
 * @route DELETE /api/files/:fileId
 * @desc Delete file metadata (soft delete)
 * @access Private
 */
router.delete('/:fileId', fileIdValidation, validate_1.validate, fileMetadata_controller_1.FileMetadataController.deleteFileMetadata);
/**
 * @route POST /api/files/attachments/metadata
 * @desc Get attachment metadata for multiple files
 * @access Private
 */
router.post('/attachments/metadata', attachmentMetadataValidation, validate_1.validate, fileMetadata_controller_1.FileMetadataController.getAttachmentMetadata);
/**
 * @route POST /api/files/cleanup/orphaned
 * @desc Clean up orphaned files (admin only)
 * @access Private
 */
router.post('/cleanup/orphaned', 
// TODO: Add admin role check middleware
fileMetadata_controller_1.FileMetadataController.cleanupOrphanedFiles);
exports.default = router;
//# sourceMappingURL=fileMetadata.routes.js.map