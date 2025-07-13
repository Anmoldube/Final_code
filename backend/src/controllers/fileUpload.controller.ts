import { Request, Response } from "express";
import { ProtectedRequest } from "../types/app-request";
import { BadRequestError, InternalError } from "../core/ApiError";
import { SuccessResponse } from "../core/ApiResponse";
import asyncHandler from "../helpers/asyncHandler";
import multer from "multer";
import path from "path";
import fs from "fs";

// Configure multer for file uploads
const storage = multer.diskStorage({
  destination: (req, file, cb) => {
    const uploadPath = path.join(__dirname, "..", "..", "public", "uploads", "temp");
    
    // Ensure temp directory exists
    if (!fs.existsSync(uploadPath)) {
      fs.mkdirSync(uploadPath, { recursive: true });
    }
    
    cb(null, uploadPath);
  },
  filename: (req, file, cb) => {
    // Generate unique filename with timestamp
    const uniqueSuffix = Date.now() + '-' + Math.round(Math.random() * 1E9);
    const ext = path.extname(file.originalname);
    const name = path.basename(file.originalname, ext);
    cb(null, `${name}-${uniqueSuffix}${ext}`);
  }
});

const upload = multer({
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
function getFileCategory(mimeType: string): string {
  if (mimeType.startsWith('image/')) return 'images';
  if (mimeType.startsWith('video/')) return 'videos';
  if (mimeType.startsWith('audio/')) return 'audio';
  if (mimeType.includes('pdf')) return 'documents';
  if (mimeType.includes('document') || mimeType.includes('text') || 
      mimeType.includes('spreadsheet') || mimeType.includes('presentation')) {
    return 'documents';
  }
  return 'files';
}

// Regular file upload (non-encrypted)
export const uploadFile = asyncHandler(
  async (req: ProtectedRequest, res: Response) => {
    const uploadMiddleware = upload.single('file');
    
    uploadMiddleware(req, res, async (err) => {
      if (err) {
        console.error('❌ File upload error:', err);
        throw new BadRequestError('File upload failed: ' + err.message);
      }

      if (!req.file) {
        throw new BadRequestError('No file uploaded');
      }

      try {
        const category = getFileCategory(req.file.mimetype);
        const finalDir = path.join(__dirname, "..", "..", "public", "uploads", category);
        
        // Ensure category directory exists
        if (!fs.existsSync(finalDir)) {
          fs.mkdirSync(finalDir, { recursive: true });
        }

        const finalPath = path.join(finalDir, req.file.filename);
        
        // Move file from temp to final location
        fs.renameSync(req.file.path, finalPath);

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

        return new SuccessResponse("File uploaded successfully", {
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

      } catch (error) {
        // Clean up temp file if it exists
        if (req.file && fs.existsSync(req.file.path)) {
          fs.unlinkSync(req.file.path);
        }
        
        console.error('❌ File processing error:', error);
        throw new InternalError('Failed to process uploaded file');
      }
    });
  }
);

// Get file info
export const getFileInfo = asyncHandler(
  async (req: Request, res: Response) => {
    const { filename } = req.params;
    
    if (!filename) {
      throw new BadRequestError('Filename is required');
    }

    // Search for file in all categories
    const categories = ['images', 'videos', 'audio', 'documents', 'files'];
    let fileInfo = null;

    for (const category of categories) {
      const filePath = path.join(__dirname, "..", "..", "public", "uploads", category, filename);
      
      if (fs.existsSync(filePath)) {
        const stats = fs.statSync(filePath);
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
      throw new BadRequestError('File not found');
    }

    return new SuccessResponse("File info retrieved successfully", fileInfo).send(res);
  }
);

// Delete file
export const deleteFile = asyncHandler(
  async (req: ProtectedRequest, res: Response) => {
    const { filename } = req.params;
    
    if (!filename) {
      throw new BadRequestError('Filename is required');
    }

    // Search for file in all categories
    const categories = ['images', 'videos', 'audio', 'documents', 'files'];
    let fileDeleted = false;

    for (const category of categories) {
      const filePath = path.join(__dirname, "..", "..", "public", "uploads", category, filename);
      
      if (fs.existsSync(filePath)) {
        fs.unlinkSync(filePath);
        fileDeleted = true;
        console.log(`🗑️ File deleted successfully: ${filename}`);
        break;
      }
    }

    if (!fileDeleted) {
      throw new BadRequestError('File not found');
    }

    return new SuccessResponse("File deleted successfully", { filename }).send(res);
  }
);