"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.MessageModel = exports.MessageStatus = exports.DOCUMENT_NAME = void 0;
const mongoose_1 = require("mongoose");
const timeUtils_1 = require("../../utils/timeUtils");
exports.DOCUMENT_NAME = "Message";
var MessageStatus;
(function (MessageStatus) {
    MessageStatus["PENDING"] = "pending";
    MessageStatus["SENDING"] = "sending";
    MessageStatus["SENT"] = "sent";
    MessageStatus["DELIVERED"] = "delivered";
    MessageStatus["READ"] = "read";
    MessageStatus["FAILED"] = "failed";
})(MessageStatus || (exports.MessageStatus = MessageStatus = {}));
const schema = new mongoose_1.Schema({
    sender: {
        type: mongoose_1.Schema.Types.ObjectId,
        ref: "User",
        required: true,
    },
    content: {
        type: mongoose_1.Schema.Types.String,
        trim: false,
        maxlength: 100000,
    },
    attachments: {
        type: [
            {
                url: {
                    type: mongoose_1.Schema.Types.String,
                    trim: true,
                },
                localPath: {
                    type: mongoose_1.Schema.Types.String,
                    trim: true,
                },
                originalName: {
                    type: mongoose_1.Schema.Types.String,
                    trim: true,
                },
                type: {
                    type: mongoose_1.Schema.Types.String,
                    trim: true,
                },
                size: {
                    type: mongoose_1.Schema.Types.Number,
                },
                fileMetadataId: {
                    type: mongoose_1.Schema.Types.ObjectId,
                    ref: "FileMetadata",
                },
            },
        ],
        default: [],
        // maxlength: 30, // max length to send a limited attachment
    },
    chat: {
        type: mongoose_1.Schema.Types.ObjectId,
        ref: "Chat",
        required: true,
    },
    status: {
        type: mongoose_1.Schema.Types.String,
        enum: Object.values(MessageStatus),
        default: MessageStatus.PENDING,
        required: true,
    },
    readBy: {
        type: [mongoose_1.Schema.Types.ObjectId],
        ref: "User",
        default: [],
    },
    deliveredTo: {
        type: [mongoose_1.Schema.Types.ObjectId],
        ref: "User",
        default: [],
    },
    sentAt: {
        type: mongoose_1.Schema.Types.Date,
    },
    deliveredAt: {
        type: mongoose_1.Schema.Types.Date,
    },
    readAt: {
        type: mongoose_1.Schema.Types.Date,
    },
    retryCount: {
        type: mongoose_1.Schema.Types.Number,
        default: 0,
        min: 0,
    },
    failureReason: {
        type: mongoose_1.Schema.Types.String,
        trim: true,
    },
    createdAt: {
        type: mongoose_1.Schema.Types.Date,
        default: timeUtils_1.getCurrentTimestamp,
        set: (value) => (0, timeUtils_1.validateAndFixTimestamp)(value),
    },
    updatedAt: {
        type: mongoose_1.Schema.Types.Date,
        default: timeUtils_1.getCurrentTimestamp,
        set: (value) => (0, timeUtils_1.validateAndFixTimestamp)(value),
    },
});
// Add pre-save middleware to update the updatedAt field
schema.pre('save', function (next) {
    if (this.isModified() && !this.isNew) {
        this.updatedAt = (0, timeUtils_1.getCurrentTimestamp)();
    }
    // Always validate timestamps on save
    if (this.createdAt) {
        this.createdAt = (0, timeUtils_1.validateAndFixTimestamp)(this.createdAt);
    }
    if (this.updatedAt) {
        this.updatedAt = (0, timeUtils_1.validateAndFixTimestamp)(this.updatedAt);
    }
    next();
});
// Add pre-update middleware to update the updatedAt field
schema.pre(['findOneAndUpdate', 'updateOne', 'updateMany'], function () {
    this.set({ updatedAt: (0, timeUtils_1.getCurrentTimestamp)() });
});
// Add indexes for efficient queries
schema.index({ chat: 1, createdAt: -1 });
schema.index({ sender: 1, createdAt: -1 });
schema.index({ status: 1, createdAt: -1 });
schema.index({ chat: 1, status: 1 });
schema.index({ readBy: 1 });
schema.index({ deliveredTo: 1 });
exports.MessageModel = (0, mongoose_1.model)(exports.DOCUMENT_NAME, schema);
//# sourceMappingURL=Message.js.map