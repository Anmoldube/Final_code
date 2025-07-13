import { Types } from "mongoose";
import { Request } from "express";
/**
 * Enhanced message service to handle read receipts and timestamps properly
 */
declare class MessageService {
    /**
     * Mark a message as read and emit socket events
     */
    markMessageAsRead(messageId: Types.ObjectId, userId: Types.ObjectId, req: Request): Promise<import("../database/model/Message").default>;
    /**
     * Mark all messages in a chat as read
     */
    markAllMessagesAsRead(chatId: Types.ObjectId, userId: Types.ObjectId, req: Request): Promise<any>;
    /**
     * Get unread message count with proper error handling
     */
    getUnreadMessagesCount(chatId: Types.ObjectId, userId: Types.ObjectId): Promise<number>;
    /**
     * Create message with proper timestamp handling
     */
    createMessage(userId: Types.ObjectId, chatId: Types.ObjectId, content: string, attachmentFiles: {
        url: string;
        localPath: string;
    }[]): Promise<any>;
}
declare const _default: MessageService;
export default _default;
