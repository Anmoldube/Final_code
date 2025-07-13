"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.ChatModel = exports.DOCUMENT_NAME = void 0;
const mongoose_1 = require("mongoose");
exports.DOCUMENT_NAME = "Chat";
// define the schema for corresponding document interface
const schema = new mongoose_1.Schema({
    name: {
        type: mongoose_1.Schema.Types.String,
        required: true,
        trim: true,
        maxlength: 200,
    },
    isGroupChat: {
        type: mongoose_1.Schema.Types.Boolean,
        default: false,
        required: true,
    },
    lastMessage: {
        type: mongoose_1.Schema.Types.ObjectId,
        ref: "Message",
    },
    lastMessageText: {
        type: mongoose_1.Schema.Types.String,
        maxlength: 500,
    },
    lastMessageTimestamp: {
        type: mongoose_1.Schema.Types.Date,
    },
    lastMessageSender: {
        type: mongoose_1.Schema.Types.ObjectId,
        ref: "User",
    },
    lastMessageType: {
        type: mongoose_1.Schema.Types.String,
        enum: ['text', 'image', 'video', 'audio', 'document', 'other'],
        default: 'text',
    },
    participants: {
        type: [
            {
                type: mongoose_1.Schema.Types.ObjectId,
                ref: "User",
            },
        ],
        required: true,
    },
    unreadCount: {
        type: Map,
        of: mongoose_1.Schema.Types.Number,
        default: new Map(),
    },
    admin: {
        type: mongoose_1.Schema.Types.ObjectId,
        ref: "User",
        required: true,
    },
    isDefault: {
        type: mongoose_1.Schema.Types.Boolean,
        default: false,
    },
    createdAt: {
        type: mongoose_1.Schema.Types.Date,
        default: Date.now,
    },
    updatedAt: {
        type: mongoose_1.Schema.Types.Date,
        default: Date.now,
    },
});
// Index for efficient sorting by last message timestamp
schema.index({ lastMessageTimestamp: -1 });
schema.index({ participants: 1, lastMessageTimestamp: -1 });
// Pre-save middleware to update timestamps
schema.pre('save', function (next) {
    if (this.isModified() && !this.isNew) {
        this.updatedAt = new Date();
    }
    next();
});
exports.ChatModel = (0, mongoose_1.model)(exports.DOCUMENT_NAME, schema);
//# sourceMappingURL=Chat.js.map