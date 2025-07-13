import { Types } from "mongoose";
import { ProtectedRequest } from "../types/app-request";
export declare class ConversationService {
    /**
     * Update conversation metadata when a new message is sent
     */
    static updateConversationOnNewMessage(req: ProtectedRequest, chatId: Types.ObjectId, messageId: Types.ObjectId, messageText: string, senderId: Types.ObjectId, attachments?: any[]): Promise<void>;
    /**
     * Mark conversation as read for a specific user
     */
    static markConversationAsRead(req: ProtectedRequest, chatId: Types.ObjectId, userId: Types.ObjectId): Promise<void>;
    /**
     * Get all conversations for a user, sorted by last message timestamp
     */
    static getUserConversations(userId: Types.ObjectId): Promise<any[]>;
    /**
     * Determine message type based on content and attachments
     */
    private static getMessageType;
    /**
     * Get preview text for the conversation list
     */
    private static getPreviewText;
}
export default ConversationService;
