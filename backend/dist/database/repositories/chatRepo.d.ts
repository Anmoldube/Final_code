import { PipelineStage, Types } from "mongoose";
import Chat from "../model/Chat";
declare const _default: {
    commonChatAggregation: () => PipelineStage[];
    getExistingOneToOneChat: (userId: Types.ObjectId, receiverId: Types.ObjectId) => Promise<any>;
    createNewOneToOneChat: (userId: Types.ObjectId, receiverId: Types.ObjectId) => Promise<any>;
    createNewGroupChat: (currentUserId: Types.ObjectId, groupName: string, members: Types.ObjectId[]) => Promise<any>;
    getChatByChatId: (chatId: Types.ObjectId) => import("mongoose").Query<(import("mongoose").FlattenMaps<{
        _id: Types.ObjectId;
        name: string;
        isGroupChat: boolean;
        isDefault?: boolean | undefined;
        lastMessage?: Types.ObjectId | undefined;
        lastMessageText?: string | undefined;
        lastMessageTimestamp?: Date | undefined;
        lastMessageSender?: Types.ObjectId | undefined;
        lastMessageType?: "text" | "image" | "video" | "audio" | "document" | "other" | undefined;
        participants: Types.ObjectId[];
        admin: Types.ObjectId;
        unreadCount?: {
            clear: () => void;
            delete: (key: string) => boolean;
            forEach: (callbackfn: (value: number, key: string, map: Map<string, number>) => void, thisArg?: any) => void;
            get: (key: string) => number | undefined;
            has: (key: string) => boolean;
            set: (key: string, value: number) => Map<string, number>;
            readonly size: number;
            entries: () => MapIterator<[string, number]>;
            keys: () => MapIterator<string>;
            values: () => MapIterator<number>;
            [Symbol.iterator]: () => MapIterator<[string, number]>;
            readonly [Symbol.toStringTag]: string;
        } | undefined;
        createdAt?: Date | undefined;
        updatedAt?: Date | undefined;
    }> & Required<{
        _id: Types.ObjectId;
    }> & {
        __v: number;
    }) | null, import("mongoose").Document<unknown, {}, Chat, {}> & Chat & Required<{
        _id: Types.ObjectId;
    }> & {
        __v: number;
    }, {}, Chat, "findOne", {}>;
    getChatByChatIdAggregated: (chatId: Types.ObjectId) => Promise<any>;
    getCurrentUserAllChats: (currentUserId: Types.ObjectId) => Promise<any>;
    getAggregatedGroupChat: (chatId: Types.ObjectId) => Promise<any>;
    updateChatFields: (chatId: Types.ObjectId, queryFields: object) => Promise<any>;
    deleteChatById: (chatId: Types.ObjectId) => Promise<any>;
    getDefaultGroup: () => Promise<any>;
    isUserInDefaultGroup: (userId: Types.ObjectId) => Promise<any>;
};
export default _default;
