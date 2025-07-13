import { Aggregate, Types } from "mongoose";
import Message, { MessageStatus } from "../model/Message";
declare const _default: {
    getAllMessagesAggregated: (chatId: Types.ObjectId) => Aggregate<any>;
    createMessage: (userId: Types.ObjectId, chatId: Types.ObjectId, content: string, attachemntFiles: {
        url: string;
        localPath: string;
    }[]) => Promise<any>;
    getStructuredMessages: (messageId: Types.ObjectId) => Aggregate<any[]>;
    getMessageById: (id: Types.ObjectId) => Promise<Message | null>;
    getMessagesOfChatId: (chatId: Types.ObjectId) => Promise<Array<Message>>;
    deleteMessageById: (id: Types.ObjectId) => Promise<Message | null>;
    deleteAllMessagesOfChatId: (chatId: Types.ObjectId) => Promise<any>;
    getLastMessage: (chatId: Types.ObjectId) => Promise<any>;
    markMessageAsRead: (messageId: Types.ObjectId, userId: Types.ObjectId) => Promise<Message | null>;
    markMessageAsDelivered: (messageId: Types.ObjectId, userId: Types.ObjectId) => Promise<Message | null>;
    updateMessageStatus: (messageId: Types.ObjectId, status: MessageStatus, additionalData?: any) => Promise<Message | null>;
    getMessagesByStatus: (chatId: Types.ObjectId, status: MessageStatus) => Promise<Message[]>;
    getFailedMessages: (userId: Types.ObjectId) => Promise<Message[]>;
    incrementRetryCount: (messageId: Types.ObjectId) => Promise<Message | null>;
    markAllMessagesAsRead: (chatId: Types.ObjectId, userId: Types.ObjectId) => Promise<any>;
    getUnreadMessagesCount: (chatId: Types.ObjectId, userId: Types.ObjectId) => Promise<number>;
    getAllUnreadMessages: (userId: Types.ObjectId) => Aggregate<any>;
};
export default _default;
