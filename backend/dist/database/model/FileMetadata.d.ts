import { Document, Types, Model } from 'mongoose';
export declare const DOCUMENT_NAME = "FileMetadata";
export interface IFileMetadata extends Document {
    _id: string;
    originalName: string;
    fileName: string;
    filePath: string;
    fileUrl: string;
    mimeType: string;
    fileSize: number;
    fileExtension: string;
    uploadedBy: Types.ObjectId;
    uploadedAt: Date;
    messageId?: string;
    chatId?: string;
    thumbnailUrl?: string;
    duration?: number;
    dimensions?: {
        width: number;
        height: number;
    };
    metadata?: {
        [key: string]: any;
    };
    isDeleted: boolean;
    deletedAt?: Date;
    getFormattedSize(): string;
}
export interface IFileMetadataModel extends Model<IFileMetadata> {
    getFileStats(userId?: string): Promise<any>;
}
export declare const FileMetadataModel: IFileMetadataModel;
