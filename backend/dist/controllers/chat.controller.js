"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.markConversationAsRead = exports.getConversations = exports.deleteChat = exports.addNewUserToGroup = exports.getGroupChatDetails = exports.createGroupChat = exports.getCurrentUserChats = exports.createOrGetExistingChat = exports.searchAvailableusers = void 0;
const asyncHandler_1 = __importDefault(require("../helpers/asyncHandler"));
const userRepo_1 = __importDefault(require("../database/repositories/userRepo"));
const ApiError_1 = require("../core/ApiError");
const chatRepo_1 = __importDefault(require("../database/repositories/chatRepo"));
const ApiResponse_1 = require("../core/ApiResponse");
const mongoose_1 = require("mongoose");
const socket_1 = require("../socket");
const constants_1 = require("../constants");
const utils_1 = require("../helpers/utils");
const messageRepo_1 = __importDefault(require("../database/repositories/messageRepo"));
const conversationService_1 = __importDefault(require("../services/conversationService"));
// search available users
const searchAvailableusers = (0, asyncHandler_1.default)(async (req, res) => {
    const userId = req.query.userId; // the search param can include either a username or email of the user to be searched
    const query = req.query.q; // Also accept 'q' parameter for search query
    // Use userId or query parameter for search
    const searchTerm = userId || query;
    console.log(`🔍 Searching for users with term: "${searchTerm}"`);
    console.log(`🔍 Current user: ${req.user?.username} (${req.user?._id})`);
    // If search term is provided, search for specific users
    // If not, list all users (except the current user)
    const users = searchTerm
        ? await userRepo_1.default.searchAvailableUsers(req.user, searchTerm)
        : await userRepo_1.default.getAllUsers(req.user);
    console.log(`🔍 Found ${users.length} users`);
    if (!users.length) {
        // Don't throw error, just return empty array with success response
        return new ApiResponse_1.SuccessResponse("no users found", {
            users: [],
        }).send(res);
    }
    return new ApiResponse_1.SuccessResponse("found Users", {
        users,
    }).send(res);
});
exports.searchAvailableusers = searchAvailableusers;
// Get existing oneToOne chat
// method to create or return existing chat
const createOrGetExistingChat = (0, asyncHandler_1.default)(async (req, res) => {
    const { receiverId } = req.params;
    const currentUserId = req.user?._id;
    // check for valid receiver id;
    const receiver = await userRepo_1.default.findById(new mongoose_1.Types.ObjectId(receiverId));
    if (!receiver) {
        throw new ApiError_1.BadRequestError("receiver does not exist");
    }
    // check whether a user is requesting to chat with himself or not
    if (receiver._id.toString() === currentUserId.toString()) {
        throw new ApiError_1.BadRequestError("you cannot chat with yourself");
    }
    // search a chats with partipants including user and receiver id
    const chat = await chatRepo_1.default.getExistingOneToOneChat(currentUserId, new mongoose_1.Types.ObjectId(receiverId));
    // if chat found return it
    if (chat.length) {
        return new ApiResponse_1.SuccessResponse("chat retrieved successfully", {
            existing: true,
            ...chat[0],
        }).send(res);
    }
    // else create a new chat
    const newChatInstance = await chatRepo_1.default.createNewOneToOneChat(currentUserId, new mongoose_1.Types.ObjectId(receiverId));
    // chat of the created chat to get the chat instance data
    const newChatId = newChatInstance._id;
    // structure the chat as per common aggregation
    const createdChat = await chatRepo_1.default.getChatByChatIdAggregated(newChatId);
    if (!createdChat.length) {
        throw new ApiError_1.InternalError("unable to create a chat one to one chat instance");
    }
    // logic to emit socket event about the new chat added to all participants
    createdChat[0]?.participants?.forEach((participant) => {
        // emit socket event to all participants including the current user
        (0, socket_1.emitToUser)(req, participant._id?.toString(), constants_1.ChatEventEnum.NEW_CHAT_EVENT, createdChat[0]);
    });
    // send a successful response of created chat
    return new ApiResponse_1.SuccessResponse("chat created successfully", {
        existing: false,
        ...createdChat[0],
    }).send(res);
});
exports.createOrGetExistingChat = createOrGetExistingChat;
// get all chat of logged in user
const getCurrentUserChats = async (req, res) => {
    const currentUserId = req.user?._id;
    const chats = await chatRepo_1.default.getCurrentUserAllChats(currentUserId);
    return new ApiResponse_1.SuccessResponse("user chats fetched successfully", chats || []).send(res);
};
exports.getCurrentUserChats = getCurrentUserChats;
// create a group chat
const createGroupChat = (0, asyncHandler_1.default)(async (req, res) => {
    const { name, participants } = req.body;
    const currentUserId = req.user?._id;
    // check participants for current user
    if (participants?.includes(currentUserId.toString())) {
        throw new ApiError_1.BadRequestError("invalid participants, container the current user");
    }
    // check for duplicate participants
    const members = [...new Set([...participants, req.user._id.toString()])];
    // check for valid participants
    if (members.length < 3) {
        throw new ApiError_1.BadRequestError("invalid participants length");
    }
    // create a new group chat
    const createdGroupChat = await chatRepo_1.default.createNewGroupChat(currentUserId, name, members);
    // get the aggregated chat
    const chatRes = await chatRepo_1.default.getAggregatedGroupChat(createdGroupChat._id);
    console.log("🔍 Raw aggregated chat result:", JSON.stringify(chatRes, null, 2));
    // aggreate method return results in an array
    const groupChat = chatRes[0];
    console.log("🔍 Final group chat object:", JSON.stringify(groupChat, null, 2));
    // emit socket to all participants about the new group chat
    console.log("🔍 Group chat participants:", groupChat?.participants?.map((p) => ({
        id: p._id?.toString(),
        username: p.username,
        email: p.email
    })));
    groupChat?.participants?.forEach((participant) => {
        const participantId = participant._id?.toString();
        console.log(`📡 Emitting NEW_CHAT_EVENT to participant: ${participant.username} (${participantId})`);
        // Use direct user emission for more reliability
        (0, socket_1.emitToUser)(req, participantId, constants_1.ChatEventEnum.NEW_CHAT_EVENT, groupChat);
    });
    // return a success response
    return new ApiResponse_1.SuccessResponse("group chat created successfully", groupChat).send(res);
});
exports.createGroupChat = createGroupChat;
const getGroupChatDetails = (0, asyncHandler_1.default)(async (req, res) => {
    const { chatId } = req.params;
    const chatRes = await chatRepo_1.default.getAggregatedGroupChat(new mongoose_1.Types.ObjectId(chatId));
    const groupChatDetails = chatRes[0];
    if (!groupChatDetails) {
        throw new ApiError_1.NoDataError("group chat not found!");
    }
    return new ApiResponse_1.SuccessResponse("group chat fetched successfully", groupChatDetails).send(res);
});
exports.getGroupChatDetails = getGroupChatDetails;
// add new user to the group chat
const addNewUserToGroup = (0, asyncHandler_1.default)(async (req, res) => {
    const { chatId } = req.params;
    const { newParticipantId } = req.body;
    const currentUserId = req.user?._id;
    if (!chatId) {
        throw new ApiError_1.BadRequestError("no chatId provided");
    }
    // check if groupchat exists
    const existingGroupChat = await chatRepo_1.default.getChatByChatId(new mongoose_1.Types.ObjectId(chatId));
    if (!existingGroupChat) {
        throw new ApiError_1.NotFoundError("no group chat found ");
    }
    // check if the adder is admin
    if (existingGroupChat.admin?.toString() !== currentUserId?.toString()) {
        throw new ApiError_1.BadRequestError("only admin's can add new user");
    }
    const existingParticipants = existingGroupChat.participants;
    // check if new participants exists in the group
    if (existingParticipants.some((participant) => participant.toString() === newParticipantId)) {
        throw new ApiError_1.BadRequestError("user already exists in the group");
    }
    // add the new user
    await chatRepo_1.default.updateChatFields(new mongoose_1.Types.ObjectId(chatId), {
        $push: { participants: newParticipantId },
    });
    // get the aggregated chat
    const aggregatedChat = await chatRepo_1.default.getAggregatedGroupChat(new mongoose_1.Types.ObjectId(chatId));
    const updatedChat = aggregatedChat[0];
    if (!updatedChat) {
        throw new ApiError_1.InternalError("Internal Server Error");
    }
    return new ApiResponse_1.SuccessResponse("participant added successfully", updatedChat).send(res);
});
exports.addNewUserToGroup = addNewUserToGroup;
// delete oneToOne chat
const deleteChat = (0, asyncHandler_1.default)(async (req, res) => {
    const { chatId } = req.params;
    const currentUserId = req.user?._id;
    // check if chatId exists
    const existingChat = await chatRepo_1.default.getChatByChatId(new mongoose_1.Types.ObjectId(chatId));
    if (!existingChat) {
        throw new ApiError_1.NotFoundError("chat not found");
    }
    // check if chat is group chat if group chat only admins can delete it
    if (!existingChat.isGroupChat) {
        if (existingChat.admin.toString() !== currentUserId.toString()) {
            throw new ApiError_1.AuthFailureError("only admins can delete the group ");
        }
    }
    if (!existingChat?.participants?.some((participantId) => participantId.toString() === currentUserId.toString())) {
        throw new ApiError_1.AuthFailureError("you cannot delete other's chat");
    }
    // delete the chat
    await chatRepo_1.default.deleteChatById(existingChat._id);
    // get all the messages and delete the attachments and messages
    const existingMessages = await messageRepo_1.default.getMessagesOfChatId(existingChat._id);
    let attachments = [];
    // Get the attachments from each message object
    existingMessages.forEach((message) => {
        if (message.attachments && message.attachments.length > 0) {
            attachments.push(message.attachments);
        }
    });
    // delete the attachments from the local folder
    attachments.forEach((attachment) => {
        attachment.forEach(({ localPath }) => {
            (0, utils_1.removeLocalFile)(localPath);
        });
    });
    // delete all the messages
    await messageRepo_1.default.deleteAllMessagesOfChatId(existingChat._id);
    // emit socket events to all participants of current deleted chat
    existingChat.participants.forEach((participantId) => {
        if (participantId.toString() === currentUserId.toString())
            return;
        // emit socket event to rest of the users
        (0, socket_1.emitSocketEvent)(req, participantId.toString(), constants_1.ChatEventEnum.LEAVE_CHAT_EVENT, existingChat);
    });
    return new ApiResponse_1.SuccessMsgResponse("chat delete successfully").send(res);
});
exports.deleteChat = deleteChat;
// Get conversations sorted by last message timestamp (WhatsApp-like)
const getConversations = (0, asyncHandler_1.default)(async (req, res) => {
    const currentUserId = req.user?._id;
    try {
        const conversations = await conversationService_1.default.getUserConversations(currentUserId);
        return new ApiResponse_1.SuccessResponse("conversations retrieved successfully", conversations).send(res);
    }
    catch (error) {
        console.error("Error getting conversations:", error);
        return new ApiResponse_1.SuccessResponse("conversations retrieved successfully", []).send(res);
    }
});
exports.getConversations = getConversations;
// Mark conversation as read
const markConversationAsRead = (0, asyncHandler_1.default)(async (req, res) => {
    const { chatId } = req.params;
    const currentUserId = req.user?._id;
    if (!chatId) {
        throw new ApiError_1.BadRequestError("Chat ID is required");
    }
    try {
        await conversationService_1.default.markConversationAsRead(req, new mongoose_1.Types.ObjectId(chatId), currentUserId);
        return new ApiResponse_1.SuccessResponse("conversation marked as read", { chatId, userId: currentUserId }).send(res);
    }
    catch (error) {
        console.error("Error marking conversation as read:", error);
        throw new ApiError_1.InternalError("Failed to mark conversation as read");
    }
});
exports.markConversationAsRead = markConversationAsRead;
//# sourceMappingURL=chat.controller.js.map