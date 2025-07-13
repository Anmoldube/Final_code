"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
const messageRepo_1 = __importDefault(require("../database/repositories/messageRepo"));
const chatRepo_1 = __importDefault(require("../database/repositories/chatRepo"));
const constants_1 = require("../constants");
const socket_1 = require("../socket");
const timeUtils_1 = require("../helpers/timeUtils");
/**
 * Enhanced message service to handle read receipts and timestamps properly
 */
class MessageService {
    /**
     * Mark a message as read and emit socket events
     */
    async markMessageAsRead(messageId, userId, req) {
        try {
            (0, timeUtils_1.logTimeInfo)('markMessageAsRead');
            // Update the message
            const updatedMessage = await messageRepo_1.default.markMessageAsRead(messageId, userId);
            if (!updatedMessage) {
                throw new Error('Failed to mark message as read');
            }
            // Get the chat to notify other participants
            const chat = await chatRepo_1.default.getChatByChatId(updatedMessage.chat);
            if (chat) {
                // Notify all participants except the one who read the message
                chat.participants.forEach((participantId) => {
                    if (participantId.toString() !== userId.toString()) {
                        (0, socket_1.emitSocketEvent)(req, participantId.toString(), constants_1.ChatEventEnum.MESSAGE_READ_EVENT, {
                            messageId: messageId,
                            chatId: chat._id,
                            readBy: userId,
                            timestamp: (0, timeUtils_1.createValidatedTimestamp)(),
                            readByUser: {
                                _id: userId,
                                // You might want to populate user info here
                            }
                        });
                    }
                });
            }
            return updatedMessage;
        }
        catch (error) {
            console.error('Error in markMessageAsRead:', error);
            throw error;
        }
    }
    /**
     * Mark all messages in a chat as read
     */
    async markAllMessagesAsRead(chatId, userId, req) {
        try {
            (0, timeUtils_1.logTimeInfo)('markAllMessagesAsRead');
            // Update all unread messages
            const result = await messageRepo_1.default.markAllMessagesAsRead(chatId, userId);
            // Get the chat to notify other participants
            const chat = await chatRepo_1.default.getChatByChatId(chatId);
            if (chat && result.modifiedCount > 0) {
                // Notify all participants except the one who read the messages
                chat.participants.forEach((participantId) => {
                    if (participantId.toString() !== userId.toString()) {
                        (0, socket_1.emitSocketEvent)(req, participantId.toString(), constants_1.ChatEventEnum.MESSAGE_READ_EVENT, {
                            chatId: chatId,
                            readBy: userId,
                            allMessages: true,
                            timestamp: (0, timeUtils_1.createValidatedTimestamp)(),
                            modifiedCount: result.modifiedCount
                        });
                    }
                });
            }
            return result;
        }
        catch (error) {
            console.error('Error in markAllMessagesAsRead:', error);
            throw error;
        }
    }
    /**
     * Get unread message count with proper error handling
     */
    async getUnreadMessagesCount(chatId, userId) {
        try {
            return await messageRepo_1.default.getUnreadMessagesCount(chatId, userId);
        }
        catch (error) {
            console.error('Error in getUnreadMessagesCount:', error);
            return 0;
        }
    }
    /**
     * Create message with proper timestamp handling
     */
    async createMessage(userId, chatId, content, attachmentFiles) {
        try {
            (0, timeUtils_1.logTimeInfo)('createMessage');
            // Create message using repository
            const message = await messageRepo_1.default.createMessage(userId, chatId, content, attachmentFiles);
            return message;
        }
        catch (error) {
            console.error('Error in createMessage:', error);
            throw error;
        }
    }
}
exports.default = new MessageService();
//# sourceMappingURL=messageService.js.map