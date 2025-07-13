import { MessageStatus } from "../database/model/Message";
import { Request } from "express";
export declare class MessageStatusService {
    /**
     * Update message status and emit real-time events
     */
    static updateMessageStatus(req: Request, messageId: string, newStatus: MessageStatus, userId?: string, failureReason?: string): Promise<void>;
    /**
     * Mark message as delivered to a specific user
     */
    static markAsDelivered(req: Request, messageId: string, userId: string): Promise<void>;
    /**
     * Mark message as read by a specific user
     */
    static markAsRead(req: Request, messageId: string, userId: string): Promise<void>;
    /**
     * Retry failed message
     */
    static retryMessage(req: Request, messageId: string): Promise<boolean>;
    /**
     * Get message status statistics for a chat
     */
    static getChatMessageStats(chatId: string): Promise<any>;
    /**
     * Helper method to determine if message should be marked as delivered
     */
    private static shouldUpdateToDelivered;
    /**
     * Helper method to determine if message should be marked as read
     */
    private static shouldUpdateToRead;
}
export default MessageStatusService;
