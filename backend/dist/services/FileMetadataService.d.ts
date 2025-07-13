import { IFileMetadata } from '../database/model/FileMetadata';
export declare class FileMetadataService {
    /**
     * Create file metadata record
     */
    static createFileMetadata(data: {
        originalName: string;
        fileName: string;
        filePath: string;
        mimeType: string;
        fileSize: number;
        uploadedBy: string;
        messageId?: string;
        chatId?: string;
        thumbnailUrl?: string;
        duration?: number;
        dimensions?: {
            width: number;
            height: number;
        };
        metadata?: any;
    }): Promise<IFileMetadata>;
    /**
     * Get file metadata by ID
     */
    static getFileMetadata(fileId: string): Promise<IFileMetadata | null>;
    /**
     * Get file metadata by message ID
     */
    static getFilesByMessageId(messageId: string): Promise<IFileMetadata[]>;
    /**
     * Get file metadata by chat ID
     */
    static getFilesByChatId(chatId: string, limit?: number, skip?: number): Promise<IFileMetadata[]>;
    /**
     * Get files by user ID
     */
    static getFilesByUserId(userId: string, limit?: number, skip?: number): Promise<IFileMetadata[]>;
    /**
     * Update file metadata
     */
    static updateFileMetadata(fileId: string, updates: Partial<IFileMetadata>): Promise<IFileMetadata | null>;
    /**
     * Soft delete file metadata
     */
    static deleteFileMetadata(fileId: string): Promise<boolean>;
    /**
     * Hard delete file metadata and file
     */
    static permanentDeleteFile(fileId: string): Promise<boolean>;
    /**
     * Get file statistics
     */
    static getFileStatistics(userId?: string): Promise<any>;
    /**
     * Search files
     */
    static searchFiles(query: {
        searchTerm?: string;
        fileType?: string;
        chatId?: string;
        uploadedBy?: string;
        dateFrom?: Date;
        dateTo?: Date;
        limit?: number;
        skip?: number;
    }): Promise<IFileMetadata[]>;
    /**
     * Get file metadata for message attachments
     */
    static getAttachmentMetadata(attachmentIds: string[]): Promise<IFileMetadata[]>;
    /**
     * Clean up orphaned files (files without associated messages)
     */
    static cleanupOrphanedFiles(): Promise<number>;
}
