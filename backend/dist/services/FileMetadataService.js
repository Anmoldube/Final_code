"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.FileMetadataService = void 0;
const FileMetadata_1 = require("../database/model/FileMetadata");
const environment_1 = require("../config/environment");
const path_1 = __importDefault(require("path"));
const promises_1 = __importDefault(require("fs/promises"));
class FileMetadataService {
    /**
     * Create file metadata record
     */
    static async createFileMetadata(data) {
        const fileExtension = path_1.default.extname(data.originalName).toLowerCase().substring(1);
        const fileUrl = `${(0, environment_1.getServerUrl)()}/uploads/${data.filePath}`;
        const fileMetadata = new FileMetadata_1.FileMetadataModel({
            ...data,
            fileUrl,
            fileExtension,
        });
        return await fileMetadata.save();
    }
    /**
     * Get file metadata by ID
     */
    static async getFileMetadata(fileId) {
        return await FileMetadata_1.FileMetadataModel.findById(fileId).populate('uploadedBy', 'username email');
    }
    /**
     * Get file metadata by message ID
     */
    static async getFilesByMessageId(messageId) {
        return await FileMetadata_1.FileMetadataModel.find({ messageId, isDeleted: false })
            .populate('uploadedBy', 'username email')
            .sort({ uploadedAt: 1 });
    }
    /**
     * Get file metadata by chat ID
     */
    static async getFilesByChatId(chatId, limit = 50, skip = 0) {
        return await FileMetadata_1.FileMetadataModel.find({ chatId, isDeleted: false })
            .populate('uploadedBy', 'username email')
            .sort({ uploadedAt: -1 })
            .limit(limit)
            .skip(skip);
    }
    /**
     * Get files by user ID
     */
    static async getFilesByUserId(userId, limit = 50, skip = 0) {
        return await FileMetadata_1.FileMetadataModel.find({ uploadedBy: userId, isDeleted: false })
            .sort({ uploadedAt: -1 })
            .limit(limit)
            .skip(skip);
    }
    /**
     * Update file metadata
     */
    static async updateFileMetadata(fileId, updates) {
        return await FileMetadata_1.FileMetadataModel.findByIdAndUpdate(fileId, { ...updates, updatedAt: new Date() }, { new: true }).populate('uploadedBy', 'username email');
    }
    /**
     * Soft delete file metadata
     */
    static async deleteFileMetadata(fileId) {
        const result = await FileMetadata_1.FileMetadataModel.findByIdAndUpdate(fileId, { isDeleted: true, deletedAt: new Date() }, { new: true });
        return !!result;
    }
    /**
     * Hard delete file metadata and file
     */
    static async permanentDeleteFile(fileId) {
        try {
            const fileMetadata = await FileMetadata_1.FileMetadataModel.findById(fileId);
            if (!fileMetadata)
                return false;
            // Delete physical file
            try {
                await promises_1.default.unlink(fileMetadata.filePath);
                if (fileMetadata.thumbnailUrl) {
                    const thumbnailPath = fileMetadata.thumbnailUrl.replace((0, environment_1.getServerUrl)(), './public');
                    await promises_1.default.unlink(thumbnailPath);
                }
            }
            catch (error) {
                console.error('Error deleting physical file:', error);
            }
            // Delete metadata record
            await FileMetadata_1.FileMetadataModel.findByIdAndDelete(fileId);
            return true;
        }
        catch (error) {
            console.error('Error permanently deleting file:', error);
            return false;
        }
    }
    /**
     * Get file statistics
     */
    static async getFileStatistics(userId) {
        return await FileMetadata_1.FileMetadataModel.getFileStats(userId);
    }
    /**
     * Search files
     */
    static async searchFiles(query) {
        const filter = { isDeleted: false };
        if (query.searchTerm) {
            filter.$or = [
                { originalName: { $regex: query.searchTerm, $options: 'i' } },
                { fileExtension: { $regex: query.searchTerm, $options: 'i' } },
            ];
        }
        if (query.fileType) {
            filter.mimeType = { $regex: `^${query.fileType}/`, $options: 'i' };
        }
        if (query.chatId) {
            filter.chatId = query.chatId;
        }
        if (query.uploadedBy) {
            filter.uploadedBy = query.uploadedBy;
        }
        if (query.dateFrom || query.dateTo) {
            filter.uploadedAt = {};
            if (query.dateFrom)
                filter.uploadedAt.$gte = query.dateFrom;
            if (query.dateTo)
                filter.uploadedAt.$lte = query.dateTo;
        }
        return await FileMetadata_1.FileMetadataModel.find(filter)
            .populate('uploadedBy', 'username email')
            .sort({ uploadedAt: -1 })
            .limit(query.limit || 50)
            .skip(query.skip || 0);
    }
    /**
     * Get file metadata for message attachments
     */
    static async getAttachmentMetadata(attachmentIds) {
        return await FileMetadata_1.FileMetadataModel.find({
            _id: { $in: attachmentIds },
            isDeleted: false
        }).populate('uploadedBy', 'username email');
    }
    /**
     * Clean up orphaned files (files without associated messages)
     */
    static async cleanupOrphanedFiles() {
        const orphanedFiles = await FileMetadata_1.FileMetadataModel.find({
            messageId: { $exists: false },
            uploadedAt: { $lt: new Date(Date.now() - 24 * 60 * 60 * 1000) }, // Older than 24 hours
            isDeleted: false,
        });
        let deletedCount = 0;
        for (const file of orphanedFiles) {
            const success = await this.permanentDeleteFile(file._id);
            if (success)
                deletedCount++;
        }
        return deletedCount;
    }
}
exports.FileMetadataService = FileMetadataService;
//# sourceMappingURL=FileMetadataService.js.map