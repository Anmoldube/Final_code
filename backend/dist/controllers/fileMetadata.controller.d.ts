import { Request, Response } from 'express';
export declare class FileMetadataController {
    /**
     * Get file metadata by ID
     */
    static getFileMetadata: (req: Request, res: Response, next: import("express").NextFunction) => void;
    /**
     * Get files by message ID
     */
    static getFilesByMessage: (req: Request, res: Response, next: import("express").NextFunction) => void;
    /**
     * Get files by chat ID
     */
    static getFilesByChat: (req: Request, res: Response, next: import("express").NextFunction) => void;
    /**
     * Get files by user ID
     */
    static getFilesByUser: (req: Request, res: Response, next: import("express").NextFunction) => void;
    /**
     * Get current user's files
     */
    static getCurrentUserFiles: (req: Request, res: Response, next: import("express").NextFunction) => void;
    /**
     * Update file metadata
     */
    static updateFileMetadata: (req: Request, res: Response, next: import("express").NextFunction) => void;
    /**
     * Delete file metadata (soft delete)
     */
    static deleteFileMetadata: (req: Request, res: Response, next: import("express").NextFunction) => void;
    /**
     * Get file statistics
     */
    static getFileStatistics: (req: Request, res: Response, next: import("express").NextFunction) => void;
    /**
     * Search files
     */
    static searchFiles: (req: Request, res: Response, next: import("express").NextFunction) => void;
    /**
     * Get attachment metadata for multiple files
     */
    static getAttachmentMetadata: (req: Request, res: Response, next: import("express").NextFunction) => void;
    /**
     * Clean up orphaned files
     */
    static cleanupOrphanedFiles: (req: Request, res: Response, next: import("express").NextFunction) => void;
}
