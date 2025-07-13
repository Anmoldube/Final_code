import { Schema, model, Document, Types, Model } from 'mongoose';
import { getCurrentTimestamp, validateAndFixTimestamp } from '../../utils/timeUtils';

export const DOCUMENT_NAME = "FileMetadata";

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
  duration?: number; // For video/audio files
  dimensions?: {
    width: number;
    height: number;
  }; // For images/videos
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

const schema = new Schema<IFileMetadata>({
  originalName: {
    type: String,
    required: true,
    trim: true,
  },
  fileName: {
    type: String,
    required: true,
    unique: true,
  },
  filePath: {
    type: String,
    required: true,
  },
  fileUrl: {
    type: String,
    required: true,
  },
  mimeType: {
    type: String,
    required: true,
  },
  fileSize: {
    type: Number,
    required: true,
    min: 0,
  },
  fileExtension: {
    type: String,
    required: true,
    lowercase: true,
  },
  uploadedBy: {
    type: Schema.Types.ObjectId,
    ref: 'User',
    required: true,
  },
  uploadedAt: {
    type: Date,
    default: getCurrentTimestamp,
    set: (value: any) => validateAndFixTimestamp(value),
  },
  messageId: {
    type: Schema.Types.ObjectId,
    ref: 'Message',
  },
  chatId: {
    type: Schema.Types.ObjectId,
    ref: 'Chat',
  },
  thumbnailUrl: {
    type: String,
  },
  duration: {
    type: Number,
    min: 0,
  },
  dimensions: {
    width: {
      type: Number,
      min: 0,
    },
    height: {
      type: Number,
      min: 0,
    },
  },
  metadata: {
    type: Schema.Types.Mixed,
    default: {},
  },
  isDeleted: {
    type: Boolean,
    default: false,
  },
  deletedAt: {
    type: Date,
    set: (value: any) => value ? validateAndFixTimestamp(value) : value,
  },
}, {
  timestamps: {
    createdAt: true,
    updatedAt: true,
    currentTime: getCurrentTimestamp
  },
  toJSON: {
    transform: function(doc, ret) {
      ret.id = ret._id;
      delete ret._id;
      delete ret.__v;
      return ret;
    }
  }
});

// Add pre-save middleware to validate timestamps
schema.pre('save', function(next) {
  if (this.uploadedAt) {
    this.uploadedAt = validateAndFixTimestamp(this.uploadedAt);
  }
  if (this.deletedAt) {
    this.deletedAt = validateAndFixTimestamp(this.deletedAt);
  }
  next();
});

// Indexes for better performance
schema.index({ uploadedBy: 1, uploadedAt: -1 });
schema.index({ messageId: 1 });
schema.index({ chatId: 1 });
schema.index({ fileName: 1 });
schema.index({ isDeleted: 1 });

// Virtual for file type category
schema.virtual('fileCategory').get(function(this: IFileMetadata) {
  if (this.mimeType.startsWith('image/')) return 'image';
  if (this.mimeType.startsWith('video/')) return 'video';
  if (this.mimeType.startsWith('audio/')) return 'audio';
  if (this.mimeType.includes('pdf')) return 'pdf';
  if (this.mimeType.includes('word') || this.mimeType.includes('document')) return 'document';
  if (this.mimeType.includes('text/')) return 'text';
  return 'other';
});

// Method to get formatted file size
schema.methods.getFormattedSize = function(this: IFileMetadata): string {
  const bytes = this.fileSize;
  const sizes = ['B', 'KB', 'MB', 'GB'];
  if (bytes === 0) return '0 B';
  const i = Math.floor(Math.log(bytes) / Math.log(1024));
  return Math.round(bytes / Math.pow(1024, i) * 100) / 100 + ' ' + sizes[i];
};

// Static method to get file statistics
schema.statics.getFileStats = async function(userId?: string) {
  const match = userId ? { uploadedBy: userId, isDeleted: false } : { isDeleted: false };
  
  return await this.aggregate([
    { $match: match },
    {
      $group: {
        _id: null,
        totalFiles: { $sum: 1 },
        totalSize: { $sum: '$fileSize' },
        imageCount: {
          $sum: {
            $cond: [{ $regexMatch: { input: '$mimeType', regex: /^image\// } }, 1, 0]
          }
        },
        videoCount: {
          $sum: {
            $cond: [{ $regexMatch: { input: '$mimeType', regex: /^video\// } }, 1, 0]
          }
        },
        documentCount: {
          $sum: {
            $cond: [{ $regexMatch: { input: '$mimeType', regex: /application\// } }, 1, 0]
          }
        },
      }
    }
  ]);
};

export const FileMetadataModel = model<IFileMetadata, IFileMetadataModel>(DOCUMENT_NAME, schema);