"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.MessageStatusService = void 0;
const mongoose_1 = require("mongoose");
const Message_1 = require("../database/model/Message");
const constants_1 = require("../constants");
const socket_1 = require("../socket");
const colorsUtils_1 = __importDefault(require("../helpers/colorsUtils"));
class MessageStatusService {
    /**
     * Update message status and emit real-time events
     */
    static async updateMessageStatus(req, messageId, newStatus, userId, failureReason) {
        try {
            const message = await Message_1.MessageModel.findById(messageId).populate('chat');
            if (!message) {
                colorsUtils_1.default.log("error", `Message not found: ${messageId}`);
                return;
            }
            const updateData = {
                status: newStatus,
                updatedAt: new Date(),
            };
            // Set specific timestamps based on status
            switch (newStatus) {
                case Message_1.MessageStatus.SENT:
                    updateData.sentAt = new Date();
                    break;
                case Message_1.MessageStatus.DELIVERED:
                    updateData.deliveredAt = new Date();
                    if (userId) {
                        // Add user to deliveredTo array if not already present
                        await Message_1.MessageModel.findByIdAndUpdate(messageId, { $addToSet: { deliveredTo: new mongoose_1.Types.ObjectId(userId) } });
                    }
                    break;
                case Message_1.MessageStatus.READ:
                    updateData.readAt = updateData.readAt || new Date();
                    if (userId) {
                        // Add user to readBy array if not already present
                        await Message_1.MessageModel.findByIdAndUpdate(messageId, { $addToSet: { readBy: new mongoose_1.Types.ObjectId(userId) } });
                    }
                    break;
                case Message_1.MessageStatus.FAILED:
                    updateData.failureReason = failureReason;
                    updateData.retryCount = (message.retryCount || 0) + 1;
                    break;
            }
            // Update the message
            const updatedMessage = await Message_1.MessageModel.findByIdAndUpdate(messageId, updateData, { new: true }).populate('sender', 'username email avatar')
                .populate('readBy', 'username')
                .populate('deliveredTo', 'username');
            if (!updatedMessage) {
                colorsUtils_1.default.log("error", `Failed to update message: ${messageId}`);
                return;
            }
            colorsUtils_1.default.log("info", `📊 Message status updated: ${messageId} -> ${newStatus}`);
            // Emit status update to all chat participants
            const chatId = message.chat.toString();
            (0, socket_1.emitSocketEvent)(req, chatId, constants_1.ChatEventEnum.MESSAGE_STATUS_UPDATE_EVENT, {
                messageId,
                status: newStatus,
                chatId,
                sentAt: updatedMessage.sentAt,
                deliveredAt: updatedMessage.deliveredAt,
                readAt: updatedMessage.readAt,
                readBy: updatedMessage.readBy,
                deliveredTo: updatedMessage.deliveredTo,
                retryCount: updatedMessage.retryCount,
                failureReason: updatedMessage.failureReason,
                timestamp: new Date().toISOString(),
            });
            // Also emit to the sender specifically for immediate UI update
            if (message.sender) {
                (0, socket_1.emitToUser)(req, message.sender.toString(), constants_1.ChatEventEnum.MESSAGE_STATUS_UPDATE_EVENT, {
                    messageId,
                    status: newStatus,
                    chatId,
                    sentAt: updatedMessage.sentAt,
                    deliveredAt: updatedMessage.deliveredAt,
                    readAt: updatedMessage.readAt,
                    readBy: updatedMessage.readBy,
                    deliveredTo: updatedMessage.deliveredTo,
                    retryCount: updatedMessage.retryCount,
                    failureReason: updatedMessage.failureReason,
                    timestamp: new Date().toISOString(),
                });
            }
        }
        catch (error) {
            colorsUtils_1.default.log("error", `Error updating message status: ${error}`);
        }
    }
    /**
     * Mark message as delivered to a specific user
     */
    static async markAsDelivered(req, messageId, userId) {
        try {
            const message = await Message_1.MessageModel.findById(messageId);
            if (!message) {
                colorsUtils_1.default.log("error", `Message not found for markAsDelivered: ${messageId}`);
                return;
            }
            // Don't mark your own messages as delivered
            if (message.sender.toString() === userId) {
                colorsUtils_1.default.log("info", `Skipping self-delivery for message: ${messageId}`);
                return;
            }
            colorsUtils_1.default.log("info", `📦 Marking message as delivered: ${messageId} to user: ${userId}`);
            // Add user to deliveredTo array if not already present
            const updated = await Message_1.MessageModel.findByIdAndUpdate(messageId, {
                $addToSet: { deliveredTo: new mongoose_1.Types.ObjectId(userId) },
                $set: {
                    deliveredAt: new Date(),
                    updatedAt: new Date()
                }
            }, { new: true }).populate('deliveredTo', 'username');
            if (!updated)
                return;
            // Check if message should be marked as delivered to all recipients
            const chat = await Message_1.MessageModel.findById(messageId).populate('chat');
            if (chat) {
                // Logic to determine if all recipients have received the message
                // This would depend on your chat participant logic
                const shouldUpdateStatus = this.shouldUpdateToDelivered(updated, chat.chat);
                if (shouldUpdateStatus && updated.status !== Message_1.MessageStatus.DELIVERED) {
                    await this.updateMessageStatus(req, messageId, Message_1.MessageStatus.DELIVERED);
                }
            }
            // Emit delivery confirmation
            (0, socket_1.emitSocketEvent)(req, message.chat.toString(), constants_1.ChatEventEnum.MESSAGE_DELIVERED_EVENT, {
                messageId,
                deliveredTo: userId,
                deliveredAt: updated.deliveredAt,
                allDeliveredTo: updated.deliveredTo,
                timestamp: new Date().toISOString(),
            });
            // Also emit status update to ensure UI updates
            (0, socket_1.emitSocketEvent)(req, message.chat.toString(), constants_1.ChatEventEnum.MESSAGE_STATUS_UPDATE_EVENT, {
                messageId,
                status: Message_1.MessageStatus.DELIVERED,
                chatId: message.chat.toString(),
                deliveredAt: updated.deliveredAt,
                deliveredTo: updated.deliveredTo,
                timestamp: new Date().toISOString(),
            });
            colorsUtils_1.default.log("info", `✅ Message delivery events emitted for: ${messageId}`);
        }
        catch (error) {
            colorsUtils_1.default.log("error", `Error marking message as delivered: ${error}`);
        }
    }
    /**
     * Mark message as read by a specific user
     */
    static async markAsRead(req, messageId, userId) {
        try {
            const message = await Message_1.MessageModel.findById(messageId).populate('chat');
            if (!message) {
                colorsUtils_1.default.log("error", `Message not found for markAsRead: ${messageId}`);
                return;
            }
            // Don't mark your own messages as read
            if (message.sender.toString() === userId) {
                colorsUtils_1.default.log("info", `Skipping self-read for message: ${messageId}`);
                return;
            }
            colorsUtils_1.default.log("info", `📖 Marking message as read: ${messageId} by user: ${userId}`);
            // Add user to readBy array if not already present
            const updated = await Message_1.MessageModel.findByIdAndUpdate(messageId, {
                $addToSet: { readBy: new mongoose_1.Types.ObjectId(userId) },
                $set: {
                    readAt: new Date(),
                    updatedAt: new Date(),
                    status: Message_1.MessageStatus.READ // Always update status to READ when someone reads it
                }
            }, { new: true }).populate('readBy', 'username')
                .populate('chat');
            if (!updated) {
                colorsUtils_1.default.log("error", `Failed to update message: ${messageId}`);
                return;
            }
            colorsUtils_1.default.log("info", `✅ Message marked as read successfully: ${messageId}`);
            // Emit read confirmation to the chat
            (0, socket_1.emitSocketEvent)(req, message.chat.toString(), constants_1.ChatEventEnum.MESSAGE_READ_EVENT, {
                messageId,
                readBy: userId,
                readAt: updated.readAt,
                allReadBy: updated.readBy,
                timestamp: new Date().toISOString(),
            });
            // Also emit status update to ensure UI updates
            (0, socket_1.emitSocketEvent)(req, message.chat.toString(), constants_1.ChatEventEnum.MESSAGE_STATUS_UPDATE_EVENT, {
                messageId,
                status: Message_1.MessageStatus.READ,
                chatId: message.chat.toString(),
                readAt: updated.readAt,
                readBy: updated.readBy,
                timestamp: new Date().toISOString(),
            });
            // Emit directly to message sender for immediate update
            (0, socket_1.emitSocketEvent)(req, message.sender.toString(), constants_1.ChatEventEnum.MESSAGE_STATUS_UPDATE_EVENT, {
                messageId,
                status: Message_1.MessageStatus.READ,
                chatId: message.chat.toString(),
                readAt: updated.readAt,
                readBy: updated.readBy,
                timestamp: new Date().toISOString(),
            });
        }
        catch (error) {
            colorsUtils_1.default.log("error", `Error marking message as read: ${error}`);
        }
    }
    /**
     * Retry failed message
     */
    static async retryMessage(req, messageId) {
        try {
            const message = await Message_1.MessageModel.findById(messageId);
            if (!message || message.status !== Message_1.MessageStatus.FAILED) {
                return false;
            }
            // Reset message status to pending for retry
            await this.updateMessageStatus(req, messageId, Message_1.MessageStatus.PENDING);
            colorsUtils_1.default.log("info", `🔄 Message retry initiated: ${messageId}`);
            return true;
        }
        catch (error) {
            colorsUtils_1.default.log("error", `Error retrying message: ${error}`);
            return false;
        }
    }
    /**
     * Get message status statistics for a chat
     */
    static async getChatMessageStats(chatId) {
        try {
            const stats = await Message_1.MessageModel.aggregate([
                { $match: { chat: new mongoose_1.Types.ObjectId(chatId) } },
                {
                    $group: {
                        _id: '$status',
                        count: { $sum: 1 }
                    }
                }
            ]);
            return stats.reduce((acc, stat) => {
                acc[stat._id] = stat.count;
                return acc;
            }, {});
        }
        catch (error) {
            colorsUtils_1.default.log("error", `Error getting chat message stats: ${error}`);
            return {};
        }
    }
    /**
     * Helper method to determine if message should be marked as delivered
     */
    static shouldUpdateToDelivered(message, chat) {
        // This is a simplified logic - you might want to implement more complex logic
        // based on your chat participant structure
        return message.deliveredTo && message.deliveredTo.length > 0;
    }
    /**
     * Helper method to determine if message should be marked as read
     */
    static shouldUpdateToRead(message, chat) {
        // This is a simplified logic - you might want to implement more complex logic
        // based on your chat participant structure
        return message.readBy && message.readBy.length > 0;
    }
}
exports.MessageStatusService = MessageStatusService;
exports.default = MessageStatusService;
//# sourceMappingURL=messageStatusService.js.map