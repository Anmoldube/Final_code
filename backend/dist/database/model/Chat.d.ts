import { Types } from "mongoose";
export declare const DOCUMENT_NAME = "Chat";
export default interface Chat {
    _id: Types.ObjectId;
    name: string;
    isGroupChat: boolean;
    isDefault?: boolean;
    lastMessage?: Types.ObjectId;
    lastMessageText?: string;
    lastMessageTimestamp?: Date;
    lastMessageSender?: Types.ObjectId;
    lastMessageType?: 'text' | 'image' | 'video' | 'audio' | 'document' | 'other';
    participants: Types.ObjectId[];
    admin: Types.ObjectId;
    unreadCount?: Map<string, number>;
    createdAt?: Date;
    updatedAt?: Date;
}
export type UpdateChatFields = Partial<Chat>;
export declare const ChatModel: import("mongoose").Model<Chat, {}, {}, {}, import("mongoose").Document<unknown, {}, Chat, {}> & Chat & Required<{
    _id: Types.ObjectId;
}> & {
    __v: number;
}, any>;
