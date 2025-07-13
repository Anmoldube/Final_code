"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
// import { getLocalFilePath, getStaticFilePath } from "helpers/utils";
// import { emitSocketEvent } from "socket";
// import { ProtectedRequest } from "types/app-request";
// import { ChatEventEnum } from "../../constants/index";
const Message_1 = require("../model/Message");
const timeUtils_1 = require("../../helpers/timeUtils");
const chatMessageCommonAggregator = () => {
    return [
        {
            $lookup: {
                from: "users",
                foreignField: "_id",
                localField: "sender",
                as: "sender",
                pipeline: [
                    {
                        $project: {
                            username: 1,
                            avatarUrl: 1,
                            email: 1,
                        },
                    },
                ],
            },
        },
        {
            $lookup: {
                from: "users",
                foreignField: "_id",
                localField: "readBy",
                as: "readByUsers",
                pipeline: [
                    {
                        $project: {
                            username: 1,
                            avatarUrl: 1,
                            email: 1,
                        },
                    },
                ],
            },
        },
        {
            $addFields: {
                sender: { $first: "$sender" },
                isRead: { $gt: [{ $size: "$readBy" }, 0] },
                readCount: { $size: "$readBy" },
            },
        },
    ];
};
// find message by Id
const getMessageById = (id) => {
    return Message_1.MessageModel.findById(id);
};
// get all messages of a particular Id
const getMessagesOfChatId = (chatId) => {
    return Message_1.MessageModel.find({ chatId });
};
const deleteMessageById = (id) => {
    return Message_1.MessageModel.findByIdAndDelete(id);
};
const deleteAllMessagesOfChatId = (chatId) => {
    return Message_1.MessageModel.deleteMany({ chat: chatId });
};
// get all messages aggregated
const getAllMessagesAggregated = (chatId) => {
    return Message_1.MessageModel.aggregate([
        {
            $match: {
                chat: chatId,
            },
        },
        {
            $sort: {
                createdAt: 1,
            },
        },
        ...chatMessageCommonAggregator(),
    ]);
};
const getLastMessage = (chatId) => {
    return Message_1.MessageModel.findOne({ chat: chatId }).sort({ createdAt: -1 }).exec();
};
// create a new message
const createMessage = (userId, chatId, content, attachemntFiles) => {
    // Log time info for debugging
    (0, timeUtils_1.logTimeInfo)('createMessage');
    const timestamp = (0, timeUtils_1.createValidatedTimestamp)();
    const messageData = {
        sender: userId,
        content: content,
        chat: chatId,
        attachments: attachemntFiles,
        status: Message_1.MessageStatus.PENDING, // Start with pending status
        readBy: [],
        deliveredTo: [],
        retryCount: 0,
        createdAt: timestamp,
        updatedAt: timestamp,
    };
    return Message_1.MessageModel.create(messageData);
};
// structure the messages
const getStructuredMessages = (messageId) => {
    return Message_1.MessageModel.aggregate([
        {
            $match: {
                _id: messageId,
            },
        },
        ...chatMessageCommonAggregator(),
    ]);
};
// Mark a message as read by a user
const markMessageAsRead = (messageId, userId) => {
    return Message_1.MessageModel.findByIdAndUpdate(messageId, {
        $addToSet: { readBy: userId },
        $set: {
            readAt: new Date(),
            updatedAt: new Date()
        }
    }, { new: true });
};
// Mark a message as delivered to a user
const markMessageAsDelivered = (messageId, userId) => {
    return Message_1.MessageModel.findByIdAndUpdate(messageId, {
        $addToSet: { deliveredTo: userId },
        $set: {
            deliveredAt: new Date(),
            updatedAt: new Date()
        }
    }, { new: true });
};
// Update message status
const updateMessageStatus = (messageId, status, additionalData) => {
    const updateData = {
        status,
        updatedAt: new Date(),
        ...additionalData
    };
    // Set specific timestamps based on status
    switch (status) {
        case Message_1.MessageStatus.SENT:
            updateData.sentAt = new Date();
            break;
        case Message_1.MessageStatus.DELIVERED:
            updateData.deliveredAt = updateData.deliveredAt || new Date();
            break;
        case Message_1.MessageStatus.READ:
            updateData.readAt = updateData.readAt || new Date();
            break;
        case Message_1.MessageStatus.FAILED:
            updateData.retryCount = (additionalData?.retryCount || 0) + 1;
            break;
    }
    return Message_1.MessageModel.findByIdAndUpdate(messageId, { $set: updateData }, { new: true });
};
// Get messages by status
const getMessagesByStatus = (chatId, status) => {
    return Message_1.MessageModel.find({ chat: chatId, status }).sort({ createdAt: -1 });
};
// Get failed messages for retry
const getFailedMessages = (userId) => {
    return Message_1.MessageModel.find({
        sender: userId,
        status: Message_1.MessageStatus.FAILED
    }).sort({ createdAt: -1 });
};
// Increment retry count
const incrementRetryCount = (messageId) => {
    return Message_1.MessageModel.findByIdAndUpdate(messageId, {
        $inc: { retryCount: 1 },
        $set: { updatedAt: new Date() }
    }, { new: true });
};
// Mark all messages in a chat as read by a user
const markAllMessagesAsRead = (chatId, userId) => {
    return Message_1.MessageModel.updateMany({
        chat: chatId,
        sender: { $ne: userId },
        readBy: { $ne: userId }
    }, {
        $addToSet: { readBy: userId }
    });
};
// Get unread messages count for a user in a specific chat
const getUnreadMessagesCount = async (chatId, userId) => {
    const count = await Message_1.MessageModel.countDocuments({
        chat: chatId,
        sender: { $ne: userId }, // Only count messages where sender is not the current user
        readBy: { $ne: userId } // And the current user hasn't read them
    });
    return count;
};
// Get all unread messages for a user across all chats
const getAllUnreadMessages = (userId) => {
    return Message_1.MessageModel.aggregate([
        {
            $match: {
                sender: { $ne: userId }, // Only count messages where sender is not the current user
                readBy: { $ne: userId } // And the current user hasn't read them
            }
        },
        {
            $lookup: {
                from: "chats",
                localField: "chat",
                foreignField: "_id",
                as: "chatInfo"
            }
        },
        {
            $match: {
                "chatInfo.participants": userId
            }
        },
        ...chatMessageCommonAggregator(),
        {
            $group: {
                _id: "$chat",
                unreadCount: { $sum: 1 },
                lastMessage: { $last: "$$ROOT" }
            }
        }
    ]);
};
exports.default = {
    getAllMessagesAggregated,
    createMessage,
    getStructuredMessages,
    getMessageById,
    getMessagesOfChatId,
    deleteMessageById,
    deleteAllMessagesOfChatId,
    getLastMessage,
    markMessageAsRead,
    markMessageAsDelivered,
    updateMessageStatus,
    getMessagesByStatus,
    getFailedMessages,
    incrementRetryCount,
    markAllMessagesAsRead,
    getUnreadMessagesCount,
    getAllUnreadMessages,
};
//# sourceMappingURL=messageRepo.js.map