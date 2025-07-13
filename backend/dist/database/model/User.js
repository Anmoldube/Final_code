"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.UserModel = exports.DOCUMENT_NAME = void 0;
const mongoose_1 = require("mongoose");
exports.DOCUMENT_NAME = "User";
const schema = new mongoose_1.Schema({
    username: {
        type: mongoose_1.Schema.Types.String,
        unique: true,
        required: true,
        trim: true,
        maxlength: 200,
    },
    email: {
        type: mongoose_1.Schema.Types.String,
        unique: true,
        required: true,
        trim: true,
        maxlength: 200,
    },
    password: {
        type: mongoose_1.Schema.Types.String,
        required: true,
        trim: true,
        select: false,
        maxlength: 200,
    },
    avatarUrl: {
        type: mongoose_1.Schema.Types.String,
        trim: true,
    },
    bio: {
        type: mongoose_1.Schema.Types.String,
        trim: true,
        maxlength: 200,
    },
    status: {
        type: mongoose_1.Schema.Types.Boolean,
        default: true,
    },
    statusMessage: {
        type: mongoose_1.Schema.Types.String,
        trim: true,
        maxlength: 100,
        default: "Available"
    },
    lastSeen: {
        type: mongoose_1.Schema.Types.Date,
        default: Date.now,
    },
    roles: {
        type: [
            {
                type: mongoose_1.Schema.Types.ObjectId,
                ref: "Role",
            },
        ],
        required: true,
        select: false,
    },
    // E2EE Fields
    publicKey: {
        type: mongoose_1.Schema.Types.String,
        trim: true,
        maxlength: 2048, // RSA public key in PEM format
    },
    keyGeneratedAt: {
        type: mongoose_1.Schema.Types.Date,
    },
    keyVersion: {
        type: mongoose_1.Schema.Types.Number,
        default: 1,
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
// Add index for efficient public key lookups
schema.index({ _id: 1, publicKey: 1 });
exports.UserModel = (0, mongoose_1.model)(exports.DOCUMENT_NAME, schema);
//# sourceMappingURL=User.js.map