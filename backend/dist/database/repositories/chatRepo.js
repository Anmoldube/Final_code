"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const Chat_1 = require("../model/Chat");
// common aggregation pipeline functions to construct chat schema with common lookups
const commonChatAggregation = () => {
    return [
        {
            // lookup for the participants present
            $lookup: {
                from: "users",
                foreignField: "_id",
                localField: "participants",
                as: "participants",
                pipeline: [
                    {
                        $project: {
                            password: 0,
                            status: 0,
                            createdAt: 0,
                            updatedAt: 0,
                            roles: 0,
                        },
                    },
                ],
            },
        },
        {
            // lookup for the group chats
            $lookup: {
                from: "messages",
                foreignField: "_id",
                localField: "lastMessage",
                as: "lastMessage",
                pipeline: [
                    {
                        // get details of the sender
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
                        $addFields: {
                            sender: { $first: "$sender" },
                        },
                    },
                ],
            },
        },
        {
            $addFields: {
                lastMessage: { $first: "$lastMessage" },
            },
        },
    ];
};
// function retrieves an existing one-to-one chat between two users.
const getExistingOneToOneChat = async (userId, receiverId) => {
    return await Chat_1.ChatModel.aggregate([
        {
            $match: {
                isGroupChat: false,
                $and: [
                    {
                        participants: { $elemMatch: { $eq: userId } },
                    },
                    {
                        participants: { $elemMatch: { $eq: receiverId } },
                    },
                ],
            },
        },
        ...commonChatAggregation(),
    ]);
};
// create a new one to one chat
const createNewOneToOneChat = (userId, receiverId) => {
    return Chat_1.ChatModel.create({
        name: "One on one chat",
        participants: [userId, receiverId], // add user and receiver id to the participants
        admin: userId,
    });
};
// create a new group chat
const createNewGroupChat = (currentUserId, groupName, members) => {
    return Chat_1.ChatModel.create({
        name: groupName,
        isGroupChat: true,
        participants: members,
        admin: currentUserId,
    });
};
// retrieve chat by chatId
const getChatByChatId = (chatId) => {
    return Chat_1.ChatModel.findById(chatId).lean();
};
// retrieve a chat by chatId
const getChatByChatIdAggregated = (chatId) => {
    return Chat_1.ChatModel.aggregate([
        {
            $match: {
                _id: chatId,
            },
        },
        ...commonChatAggregation(),
    ]);
};
// get current user chats
const getCurrentUserAllChats = (currentUserId) => {
    return Chat_1.ChatModel.aggregate([
        {
            $match: {
                participants: { $elemMatch: { $eq: currentUserId } }, // get all the chats of the current user
            },
        },
        {
            $sort: {
                lastMessageTimestamp: -1, // Sort by last message timestamp first
                updatedAt: -1,
            },
        },
        ...commonChatAggregation(),
        {
            $addFields: {
                // Add user-specific unread count
                unreadCount: {
                    $ifNull: [
                        {
                            $getField: {
                                field: { $toString: currentUserId },
                                input: "$unreadCount",
                            },
                        },
                        0,
                    ],
                },
            },
        },
    ]);
};
// get aggregated groupChat
const getAggregatedGroupChat = (chatId) => {
    return Chat_1.ChatModel.aggregate([
        {
            $match: {
                _id: chatId,
                isGroupChat: true,
            },
        },
        ...commonChatAggregation(),
    ]);
};
// update the fields in the chat
const updateChatFields = (chatId, queryFields) => {
    return Chat_1.ChatModel.findByIdAndUpdate(chatId, queryFields, { new: true });
};
// delete a chat by id
const deleteChatById = (chatId) => {
    return Chat_1.ChatModel.findByIdAndDelete(chatId);
};
// get default group
const getDefaultGroup = () => {
    return Chat_1.ChatModel.findOne({ isDefault: true }).populate('participants', 'username email avatarUrl');
};
// check if user is in default group
const isUserInDefaultGroup = (userId) => {
    return Chat_1.ChatModel.findOne({
        isDefault: true,
        participants: { $elemMatch: { $eq: userId } }
    });
};
exports.default = {
    commonChatAggregation,
    getExistingOneToOneChat,
    createNewOneToOneChat,
    createNewGroupChat,
    getChatByChatId,
    getChatByChatIdAggregated,
    getCurrentUserAllChats,
    getAggregatedGroupChat,
    updateChatFields,
    deleteChatById,
    getDefaultGroup,
    isUserInDefaultGroup,
};
//# sourceMappingURL=chatRepo.js.map