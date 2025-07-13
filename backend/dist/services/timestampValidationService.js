"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.TimestampValidationService = void 0;
const timeUtils_1 = require("../utils/timeUtils");
const Message_1 = require("../database/model/Message");
const FileMetadata_1 = require("../database/model/FileMetadata");
/**
 * Service to validate and fix timestamps on application startup
 */
class TimestampValidationService {
    /**
     * Validate system time and log warnings if issues are found
     */
    static validateSystemTime() {
        const validation = (0, timeUtils_1.validateSystemTime)();
        if (!validation.isValid) {
            console.error('🚨 SYSTEM TIME ISSUE:', validation.message);
            console.error('Please fix your system clock before proceeding!');
        }
        else {
            console.log('✅ System time validation passed:', validation.message);
        }
    }
    /**
     * Check and fix any future timestamps in the database
     */
    static async fixDatabaseTimestamps() {
        console.log('🔍 Checking for invalid timestamps in database...');
        try {
            await this.fixMessageTimestamps();
            await this.fixFileMetadataTimestamps();
            console.log('✅ Database timestamp validation completed');
        }
        catch (error) {
            console.error('❌ Error during database timestamp validation:', error);
        }
    }
    /**
     * Fix message timestamps that are in the future
     */
    static async fixMessageTimestamps() {
        const now = (0, timeUtils_1.getCurrentTimestamp)();
        const maxFutureTime = new Date(now.getTime() + (24 * 60 * 60 * 1000)); // 1 day from now
        // Find messages with future timestamps
        const futureMessages = await Message_1.MessageModel.find({
            $or: [
                { createdAt: { $gt: maxFutureTime } },
                { updatedAt: { $gt: maxFutureTime } }
            ]
        }).limit(100); // Process in batches
        if (futureMessages.length > 0) {
            console.warn(`⚠️  Found ${futureMessages.length} messages with future timestamps`);
            for (const message of futureMessages) {
                const originalCreatedAt = message.createdAt;
                const originalUpdatedAt = message.updatedAt;
                // Fix the timestamps
                if (message.createdAt > maxFutureTime) {
                    message.createdAt = now;
                }
                if (message.updatedAt > maxFutureTime) {
                    message.updatedAt = now;
                }
                await message.save();
                (0, timeUtils_1.logTimestampWarning)(`Message ${message._id}`, { createdAt: originalCreatedAt, updatedAt: originalUpdatedAt }, { createdAt: message.createdAt, updatedAt: message.updatedAt });
            }
            console.log(`✅ Fixed ${futureMessages.length} message timestamps`);
        }
        else {
            console.log('✅ No future message timestamps found');
        }
    }
    /**
     * Fix file metadata timestamps that are in the future
     */
    static async fixFileMetadataTimestamps() {
        const now = (0, timeUtils_1.getCurrentTimestamp)();
        const maxFutureTime = new Date(now.getTime() + (24 * 60 * 60 * 1000)); // 1 day from now
        // Find file metadata with future timestamps
        const futureFiles = await FileMetadata_1.FileMetadataModel.find({
            $or: [
                { uploadedAt: { $gt: maxFutureTime } },
                { createdAt: { $gt: maxFutureTime } },
                { updatedAt: { $gt: maxFutureTime } }
            ]
        }).limit(100); // Process in batches
        if (futureFiles.length > 0) {
            console.warn(`⚠️  Found ${futureFiles.length} file metadata with future timestamps`);
            for (const file of futureFiles) {
                const originalUploadedAt = file.uploadedAt;
                const originalCreatedAt = file.createdAt;
                const originalUpdatedAt = file.updatedAt;
                // Fix the timestamps
                if (file.uploadedAt > maxFutureTime) {
                    file.uploadedAt = now;
                }
                if (file.createdAt > maxFutureTime) {
                    file.createdAt = now;
                }
                if (file.updatedAt > maxFutureTime) {
                    file.updatedAt = now;
                }
                await file.save();
                (0, timeUtils_1.logTimestampWarning)(`FileMetadata ${file._id}`, { uploadedAt: originalUploadedAt, createdAt: originalCreatedAt, updatedAt: originalUpdatedAt }, { uploadedAt: file.uploadedAt, createdAt: file.createdAt, updatedAt: file.updatedAt });
            }
            console.log(`✅ Fixed ${futureFiles.length} file metadata timestamps`);
        }
        else {
            console.log('✅ No future file metadata timestamps found');
        }
    }
    /**
     * Run complete timestamp validation on startup
     */
    static async runStartupValidation() {
        console.log('\n🕐 Running timestamp validation on startup...');
        console.log('='.repeat(50));
        // Check system time first
        this.validateSystemTime();
        // Fix database timestamps
        await this.fixDatabaseTimestamps();
        console.log('='.repeat(50));
        console.log('🕐 Timestamp validation completed\n');
    }
}
exports.TimestampValidationService = TimestampValidationService;
//# sourceMappingURL=timestampValidationService.js.map