"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
const express_1 = require("express");
const ApiResponse_1 = require("../core/ApiResponse");
const asyncHandler_1 = __importDefault(require("../helpers/asyncHandler"));
const auth_middlewares_1 = require("../middlewares/auth.middlewares");
const chatRepo_1 = __importDefault(require("../database/repositories/chatRepo"));
const socket_1 = require("../socket");
const constants_1 = require("../constants");
const defaultGroupService_1 = __importDefault(require("../services/defaultGroupService"));
const testRouter = (0, express_1.Router)();
// Test endpoint to check socket connectivity
testRouter.post("/socket-test", auth_middlewares_1.verifyJWT, (0, asyncHandler_1.default)(async (req, res) => {
    const currentUserId = req.user?._id;
    const io = req.app.get("io");
    // Get connected socket info
    let socketInfo = {
        totalConnectedSockets: 0,
        userSocketFound: false,
        userRooms: [],
        allRooms: []
    };
    if (io) {
        socketInfo.totalConnectedSockets = io.sockets.sockets.size;
        // Check if user has active socket connection
        for (const [socketId, socket] of io.sockets.sockets) {
            if (socket.user && socket.user._id.toString() === currentUserId.toString()) {
                socketInfo.userSocketFound = true;
                socketInfo.userRooms = Array.from(socket.rooms);
                break;
            }
        }
        // Get all rooms for debugging
        socketInfo.allRooms = Array.from(io.adapter.rooms.keys());
    }
    // Get user's chats to test auto-join
    const userChats = await chatRepo_1.default.getCurrentUserAllChats(currentUserId);
    // Test emitting to user's personal room
    (0, socket_1.emitSocketEvent)(req, currentUserId.toString(), constants_1.ChatEventEnum.NOTIFICATION_EVENT, {
        message: "Socket test notification to personal room",
        timestamp: new Date().toISOString(),
        type: "personal_test"
    });
    // Test emitting to each chat room
    const chatRoomTests = userChats.map((chat) => {
        (0, socket_1.emitSocketEvent)(req, chat._id.toString(), constants_1.ChatEventEnum.NOTIFICATION_EVENT, {
            message: `Test message to chat: ${chat.name || 'Unnamed chat'}`,
            chatId: chat._id.toString(),
            timestamp: new Date().toISOString(),
            type: "chat_test"
        });
        return {
            chatId: chat._id.toString(),
            chatName: chat.name || 'Unnamed chat',
            participantCount: chat.participants?.length || 0
        };
    });
    return new ApiResponse_1.SuccessResponse("Socket test completed", {
        userId: currentUserId.toString(),
        userChats: userChats.length,
        socketInfo,
        chatRoomTests,
        timestamp: new Date().toISOString()
    }).send(res);
}));
// Test endpoint to get user's chat rooms info
testRouter.get("/my-chats", auth_middlewares_1.verifyJWT, (0, asyncHandler_1.default)(async (req, res) => {
    const currentUserId = req.user?._id;
    const userChats = await chatRepo_1.default.getCurrentUserAllChats(currentUserId);
    const chatInfo = userChats.map((chat) => ({
        id: chat._id.toString(),
        name: chat.name,
        isGroupChat: chat.isGroupChat,
        isDefault: chat.isDefault || false,
        participantCount: chat.participants?.length || 0,
        participants: chat.participants?.map((p) => ({
            id: p._id?.toString(),
            username: p.username,
            email: p.email
        })) || []
    }));
    return new ApiResponse_1.SuccessResponse("User chats retrieved", {
        userId: currentUserId.toString(),
        totalChats: userChats.length,
        chats: chatInfo
    }).send(res);
}));
// Debug endpoint for default group
testRouter.get("/default-group", auth_middlewares_1.verifyJWT, (0, asyncHandler_1.default)(async (req, res) => {
    const currentUserId = req.user?._id;
    // Get default group info
    const defaultGroup = await defaultGroupService_1.default.getDefaultGroup();
    // Check if current user is in default group
    const isUserInDefaultGroup = await chatRepo_1.default.isUserInDefaultGroup(currentUserId);
    // Try to add user to default group
    const addResult = await defaultGroupService_1.default.addUserToDefaultGroup(currentUserId);
    // Get updated default group info
    const updatedDefaultGroup = await defaultGroupService_1.default.getDefaultGroup();
    return new ApiResponse_1.SuccessResponse("Default group debug info", {
        userId: currentUserId.toString(),
        defaultGroupExists: !!defaultGroup,
        defaultGroupInfo: defaultGroup ? {
            id: defaultGroup._id.toString(),
            name: defaultGroup.name,
            isDefault: defaultGroup.isDefault,
            isGroupChat: defaultGroup.isGroupChat,
            participantCount: defaultGroup.participants?.length || 0,
            participants: defaultGroup.participants?.map((p) => p.toString()) || []
        } : null,
        wasUserInDefaultGroup: !!isUserInDefaultGroup,
        userAddedToDefaultGroup: addResult,
        updatedDefaultGroupInfo: updatedDefaultGroup ? {
            id: updatedDefaultGroup._id.toString(),
            name: updatedDefaultGroup.name,
            participantCount: updatedDefaultGroup.participants?.length || 0,
            userIsNowInGroup: updatedDefaultGroup.participants?.some((p) => p.toString() === currentUserId.toString()) || false
        } : null,
        defaultGroupId: defaultGroupService_1.default.getDefaultGroupId(),
        defaultGroupName: defaultGroupService_1.default.getDefaultGroupName()
    }).send(res);
}));
// Force create default group endpoint
testRouter.post("/create-default-group", auth_middlewares_1.verifyJWT, (0, asyncHandler_1.default)(async (req, res) => {
    try {
        await defaultGroupService_1.default.initializeDefaultGroup();
        const defaultGroup = await defaultGroupService_1.default.getDefaultGroup();
        return new ApiResponse_1.SuccessResponse("Default group creation attempted", {
            success: !!defaultGroup,
            defaultGroup: defaultGroup ? {
                id: defaultGroup._id.toString(),
                name: defaultGroup.name,
                isDefault: defaultGroup.isDefault,
                isGroupChat: defaultGroup.isGroupChat,
                participantCount: defaultGroup.participants?.length || 0
            } : null
        }).send(res);
    }
    catch (error) {
        return new ApiResponse_1.SuccessResponse("Default group creation failed", {
            success: false,
            error: typeof error === "object" && error !== null && "message" in error ? error.message : String(error)
        }).send(res);
    }
}));
exports.default = testRouter;
//# sourceMappingURL=test.routes.js.map