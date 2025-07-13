import { Types } from "mongoose";
export declare const DOCUMENT_NAME = "Message";
export declare enum MessageStatus {
    PENDING = "pending",
    SENDING = "sending",
    SENT = "sent",
    DELIVERED = "delivered",
    READ = "read",
    FAILED = "failed"
}
export default interface Message {
    _id: Types.ObjectId;
    sender: Types.ObjectId;
    content?: string;
    attachments?: {
        url: string;
        localPath: string;
        originalName?: string;
        type?: string;
        size?: number;
        fileMetadataId?: Types.ObjectId;
    }[];
    chat: Types.ObjectId;
    status: MessageStatus;
    readBy: Types.ObjectId[];
    deliveredTo: Types.ObjectId[];
    sentAt?: Date;
    deliveredAt?: Date;
    readAt?: Date;
    retryCount: number;
    failureReason?: string;
    createdAt: Date;
    updatedAt: Date;
}
export declare const MessageModel: import("mongoose").Model<Message, {}, {}, {}, import("mongoose").Document<unknown, {}, Message, {}> & Message & Required<{
    _id: Types.ObjectId;
}> & {
    __v: number;
}, any>;
