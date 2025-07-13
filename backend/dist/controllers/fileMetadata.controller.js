"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.FileMetadataController = void 0;
const FileMetadataService_1 = require("../services/FileMetadataService");
const asyncHandler_1 = __importDefault(require("../helpers/asyncHandler"));
const ApiError_1 = require("../core/ApiError");
const ApiResponse_1 = require("../core/ApiResponse");
class FileMetadataController {
    /**
     * Get file metadata by ID
     */
    static getFileMetadata = (0, asyncHandler_1.default)(async (req, res) => {
        const { fileId } = req.params;
        if (!fileId) {
            throw new ApiError_1.BadRequestError('File ID is required');
        }
        const fileMetadata = await FileMetadataService_1.FileMetadataService.getFileMetadata(fileId);
        if (!fileMetadata) {
            throw new ApiError_1.NotFoundError('File not found');
        }
        new ApiResponse_1.SuccessResponse('File metadata retrieved successfully', fileMetadata).send(res);
    });
    /**
     * Get files by message ID
     */
    static getFilesByMessage = (0, asyncHandler_1.default)(async (req, res) => {
        const { messageId } = req.params;
        if (!messageId) {
            throw new ApiError_1.BadRequestError('Message ID is required');
        }
        const files = await FileMetadataService_1.FileMetadataService.getFilesByMessageId(messageId);
        new ApiResponse_1.SuccessResponse('Files retrieved successfully', files).send(res);
    });
    /**
     * Get files by chat ID
     */
    static getFilesByChat = (0, asyncHandler_1.default)(async (req, res) => {
        const { chatId } = req.params;
        const { limit = 50, skip = 0 } = req.query;
        if (!chatId) {
            throw new ApiError_1.BadRequestError('Chat ID is required');
        }
        const files = await FileMetadataService_1.FileMetadataService.getFilesByChatId(chatId, parseInt(limit), parseInt(skip));
        new ApiResponse_1.SuccessResponse('Files retrieved successfully', files).send(res);
    });
    /**
     * Get files by user ID
     */
    static getFilesByUser = (0, asyncHandler_1.default)(async (req, res) => {
        const { userId } = req.params;
        const { limit = 50, skip = 0 } = req.query;
        if (!userId) {
            throw new ApiError_1.BadRequestError('User ID is required');
        }
        const files = await FileMetadataService_1.FileMetadataService.getFilesByUserId(userId, parseInt(limit), parseInt(skip));
        new ApiResponse_1.SuccessResponse('Files retrieved successfully', files).send(res);
    });
    /**
     * Get current user's files
     */
    static getCurrentUserFiles = (0, asyncHandler_1.default)(async (req, res) => {
        const { limit = 50, skip = 0 } = req.query;
        const currentUserId = req.user?._id.toString();
        if (!currentUserId) {
            throw new ApiError_1.BadRequestError('User authentication required');
        }
        const files = await FileMetadataService_1.FileMetadataService.getFilesByUserId(currentUserId, parseInt(limit), parseInt(skip));
        new ApiResponse_1.SuccessResponse('User files retrieved successfully', {
            files,
            totalCount: files.length,
            userId: currentUserId
        }).send(res);
    });
    /**
     * Update file metadata
     */
    static updateFileMetadata = (0, asyncHandler_1.default)(async (req, res) => {
        const { fileId } = req.params;
        const updates = req.body;
        if (!fileId) {
            throw new ApiError_1.BadRequestError('File ID is required');
        }
        const updatedFile = await FileMetadataService_1.FileMetadataService.updateFileMetadata(fileId, updates);
        if (!updatedFile) {
            throw new ApiError_1.NotFoundError('File not found');
        }
        new ApiResponse_1.SuccessResponse('File metadata updated successfully', updatedFile).send(res);
    });
    /**
     * Delete file metadata (soft delete)
     */
    static deleteFileMetadata = (0, asyncHandler_1.default)(async (req, res) => {
        const { fileId } = req.params;
        if (!fileId) {
            throw new ApiError_1.BadRequestError('File ID is required');
        }
        const success = await FileMetadataService_1.FileMetadataService.deleteFileMetadata(fileId);
        if (!success) {
            throw new ApiError_1.NotFoundError('File not found');
        }
        new ApiResponse_1.SuccessResponse('File deleted successfully', { success: true }).send(res);
    });
    /**
     * Get file statistics
     */
    static getFileStatistics = (0, asyncHandler_1.default)(async (req, res) => {
        const { userId } = req.query;
        const stats = await FileMetadataService_1.FileMetadataService.getFileStatistics(userId);
        new ApiResponse_1.SuccessResponse('File statistics retrieved successfully', stats).send(res);
    });
    /**
     * Search files
     */
    static searchFiles = (0, asyncHandler_1.default)(async (req, res) => {
        const { searchTerm, fileType, chatId, uploadedBy, dateFrom, dateTo, limit = 50, skip = 0 } = req.query;
        const searchQuery = {
            searchTerm: searchTerm,
            fileType: fileType,
            chatId: chatId,
            uploadedBy: uploadedBy,
            dateFrom: dateFrom ? new Date(dateFrom) : undefined,
            dateTo: dateTo ? new Date(dateTo) : undefined,
            limit: parseInt(limit),
            skip: parseInt(skip),
        };
        const files = await FileMetadataService_1.FileMetadataService.searchFiles(searchQuery);
        new ApiResponse_1.SuccessResponse('Files searched successfully', files).send(res);
    });
    /**
     * Get attachment metadata for multiple files
     */
    static getAttachmentMetadata = (0, asyncHandler_1.default)(async (req, res) => {
        const { attachmentIds } = req.body;
        if (!attachmentIds || !Array.isArray(attachmentIds)) {
            throw new ApiError_1.BadRequestError('Attachment IDs array is required');
        }
        const files = await FileMetadataService_1.FileMetadataService.getAttachmentMetadata(attachmentIds);
        new ApiResponse_1.SuccessResponse('Attachment metadata retrieved successfully', files).send(res);
    });
    /**
     * Clean up orphaned files
     */
    static cleanupOrphanedFiles = (0, asyncHandler_1.default)(async (req, res) => {
        const deletedCount = await FileMetadataService_1.FileMetadataService.cleanupOrphanedFiles();
        new ApiResponse_1.SuccessResponse('Orphaned files cleaned up successfully', { deletedCount }).send(res);
    });
}
exports.FileMetadataController = FileMetadataController;
//# sourceMappingURL=fileMetadata.controller.js.map