"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.emitToUser = exports.emitSocketEvent = exports.initSocketIo = void 0;
const cookie_1 = __importDefault(require("cookie"));
const constants_1 = require("../constants");
const ApiError_1 = require("../core/ApiError");
const JWT_1 = __importDefault(require("../core/JWT"));
const userRepo_1 = __importDefault(require("../database/repositories/userRepo"));
const chatRepo_1 = __importDefault(require("../database/repositories/chatRepo"));
const colorsUtils_1 = __importDefault(require("../helpers/colorsUtils"));
const mongoose_1 = require("mongoose");
const messageStatusService_1 = __importDefault(require("../services/messageStatusService"));
const defaultGroupService_1 = __importDefault(require("../services/defaultGroupService"));
// handles the join chat event ie; when a user join a room
const mountJoinChatEvent = (socket) => {
    socket.on(constants_1.ChatEventEnum.JOIN_CHAT_EVENT, (chatId) => {
        colorsUtils_1.default.log("info", `👥 User ${socket.user?._id} manually joining chat room: ${chatId}`);
        socket.join(chatId); // join the user to a chat between or group chat
        colorsUtils_1.default.log("info", `✅ User ${socket.user?._id} successfully joined chat room: ${chatId}`);
    });
};
// handles the join user groups event - joins user to all their groups including default
const mountJoinUserGroupsEvent = (socket) => {
    socket.on(constants_1.ChatEventEnum.JOIN_USER_GROUPS_EVENT, async (userId) => {
        try {
            if (!socket.user || socket.user._id.toString() !== userId) {
                colorsUtils_1.default.log("warning", `⚠️ Unauthorized join_user_groups attempt for user: ${userId}`);
                return;
            }
            colorsUtils_1.default.log("info", `🔗 User ${userId} requesting to join all their groups`);
            // Get all user chats including the default group
            const userChats = await chatRepo_1.default.getCurrentUserAllChats(new mongoose_1.Types.ObjectId(userId));
            if (userChats && userChats.length > 0) {
                userChats.forEach((chat) => {
                    const chatId = chat._id.toString();
                    socket.join(chatId);
                    if (defaultGroupService_1.default.isDefaultGroup(chatId)) {
                        colorsUtils_1.default.log("info", `🏠 User ${userId} joined DEFAULT group room: ${chatId} (${chat.name})`);
                    }
                    else {
                        colorsUtils_1.default.log("info", `📍 User ${userId} joined chat room: ${chatId} (${chat.name || 'Unnamed chat'})`);
                    }
                });
                colorsUtils_1.default.log("success", `✅ User ${userId} successfully joined ${userChats.length} chat rooms`);
                // Send confirmation back to client
                socket.emit('user_groups_joined', {
                    success: true,
                    groupCount: userChats.length,
                    groups: userChats.map((chat) => ({
                        id: chat._id.toString(),
                        name: chat.name,
                        isDefault: chat.isDefault || false
                    }))
                });
            }
            else {
                colorsUtils_1.default.log("info", `📭 User ${userId} has no groups to join`);
                socket.emit('user_groups_joined', {
                    success: true,
                    groupCount: 0,
                    groups: []
                });
            }
        }
        catch (error) {
            colorsUtils_1.default.log("error", `❌ Error joining user groups: ${error}`);
            socket.emit('user_groups_joined', {
                success: false,
                error: 'Failed to join user groups'
            });
        }
    });
};
// handle the start Typing event
const mountStartTypingEvent = (socket) => {
    socket.on(constants_1.ChatEventEnum.START_TYPING_EVENT, (chatId) => {
        socket.in(chatId).emit(constants_1.ChatEventEnum.START_TYPING_EVENT, chatId);
    });
};
// handle the stop Typing event
const mountStopTypingEvent = (socket) => {
    socket.on(constants_1.ChatEventEnum.STOP_TYPING_EVENT, (chatId) => {
        socket.in(chatId).emit(constants_1.ChatEventEnum.STOP_TYPING_EVENT, chatId);
    });
};
// handle the message read event
const mountMessageReadEvent = (socket, io) => {
    socket.on(constants_1.ChatEventEnum.MESSAGE_READ_EVENT, async (data) => {
        try {
            // Validate data exists and is not undefined
            if (!data) {
                colorsUtils_1.default.log("warning", "Message read event received with undefined data");
                return;
            }
            // Ensure data is an object - safe parsing
            let messageData;
            if (typeof data === 'string') {
                try {
                    messageData = JSON.parse(data);
                }
                catch (parseError) {
                    colorsUtils_1.default.log("error", `Failed to parse message data: ${parseError}`);
                    return;
                }
            }
            else if (typeof data === 'object') {
                messageData = data;
            }
            else {
                colorsUtils_1.default.log("warning", `Invalid message data type: ${typeof data}`);
                return;
            }
            colorsUtils_1.default.log("info", `📖 Message read event. Data: ${JSON.stringify(messageData)}`);
            if (messageData && messageData.messageId && socket.user?._id) {
                // Use the new message status service
                const req = { app: { get: () => io } };
                await messageStatusService_1.default.markAsRead(req, messageData.messageId, socket.user._id.toString());
            }
            else {
                colorsUtils_1.default.log("warning", "Message read event missing required data");
            }
        }
        catch (error) {
            console.error('Error processing message read event:', error);
            socket.emit(constants_1.ChatEventEnum.SOCKET_ERROR_EVENT, "Failed to process message read event");
        }
    });
};
// handle the message delivered event
const mountMessageDeliveredEvent = (socket, io) => {
    socket.on(constants_1.ChatEventEnum.MESSAGE_DELIVERED_EVENT, async (data) => {
        try {
            if (!data || !data.messageId || !socket.user?._id) {
                colorsUtils_1.default.log("warning", "Message delivered event missing required data");
                return;
            }
            colorsUtils_1.default.log("info", `📬 Message delivered event: ${data.messageId}`);
            const req = { app: { get: () => io } };
            await messageStatusService_1.default.markAsDelivered(req, data.messageId, socket.user._id.toString());
        }
        catch (error) {
            console.error('Error processing message delivered event:', error);
            socket.emit(constants_1.ChatEventEnum.SOCKET_ERROR_EVENT, "Failed to process message delivered event");
        }
    });
};
// handle message retry event
const mountMessageRetryEvent = (socket, io) => {
    socket.on('messageRetry', async (data) => {
        try {
            if (!data || !data.messageId) {
                colorsUtils_1.default.log("warning", "Message retry event missing messageId");
                return;
            }
            colorsUtils_1.default.log("info", `🔄 Message retry event: ${data.messageId}`);
            const req = { app: { get: () => io } };
            const success = await messageStatusService_1.default.retryMessage(req, data.messageId);
            if (success) {
                socket.emit('messageRetrySuccess', { messageId: data.messageId });
            }
            else {
                socket.emit('messageRetryFailed', { messageId: data.messageId });
            }
        }
        catch (error) {
            console.error('Error processing message retry event:', error);
            socket.emit(constants_1.ChatEventEnum.SOCKET_ERROR_EVENT, "Failed to process message retry event");
        }
    });
};
// Auto-join user to all their chats
const autoJoinUserChats = async (socket, userId) => {
    try {
        const userChats = await chatRepo_1.default.getCurrentUserAllChats(userId);
        colorsUtils_1.default.log("info", `🔗 Auto-joining user ${userId} to ${userChats.length} chats`);
        if (userChats && userChats.length > 0) {
            userChats.forEach((chat) => {
                const chatId = chat._id.toString();
                socket.join(chatId);
                colorsUtils_1.default.log("info", `📍 User ${userId} joined chat room: ${chatId} (${chat.name || 'Unnamed chat'})`);
            });
        }
        else {
            colorsUtils_1.default.log("info", `📭 User ${userId} has no existing chats to join`);
        }
    }
    catch (error) {
        colorsUtils_1.default.log("error", `❌ Error auto-joining user chats: ${error}`);
    }
};
// function to initialize the socket io
const initSocketIo = (io) => {
    io.on("connection", async (socket) => {
        try {
            // get the token from the cookies, handshake auth, or authorization header
            const cookieHeader = socket.handshake.headers?.cookie;
            const cookies = cookieHeader ? cookie_1.default.parse(cookieHeader) : {};
            let token = cookies?.accessToken ||
                socket.handshake.auth?.token ||
                socket.handshake.headers?.authorization?.replace('Bearer ', '');
            if (!token) {
                colorsUtils_1.default.log("error", "❌ Socket connection failed: Token not found");
                throw new ApiError_1.BadTokenError("Token not found");
            }
            colorsUtils_1.default.log("info", "🔐 Socket auth token found, validating...");
            const decodedToken = await JWT_1.default.validateToken(token);
            const userId = new mongoose_1.Types.ObjectId(decodedToken.sub);
            const user = await userRepo_1.default.findById(userId);
            if (!user) {
                colorsUtils_1.default.log("error", `❌ Invalid token - user not found: ${userId}`);
                throw new ApiError_1.BadTokenError("Invalid token");
            }
            socket.user = user;
            socket.join(user._id.toString());
            colorsUtils_1.default.log("info", `👤 User ${user.username} (${user._id}) joined personal room`);
            // Auto-join user to all their chats
            await autoJoinUserChats(socket, userId);
            // Send connection confirmation with user data
            socket.emit(constants_1.ChatEventEnum.CONNECTED_EVENT, {
                userId: user._id.toString(),
                username: user.username,
                message: "Connected successfully"
            });
            colorsUtils_1.default.log("info", `🤝 User connected successfully: ${user.username} (${user._id.toString()})`);
            // Mount event handlers
            mountJoinChatEvent(socket);
            mountJoinUserGroupsEvent(socket);
            mountStartTypingEvent(socket);
            mountStopTypingEvent(socket);
            mountMessageReadEvent(socket, io);
            mountMessageDeliveredEvent(socket, io);
            mountMessageRetryEvent(socket, io);
            // Message events with error handling
            socket.on(constants_1.ChatEventEnum.MESSAGE_RECEIVED_EVENT, (message) => {
                try {
                    console.log("Message received event:", message);
                    socket.to(message.chat).emit(constants_1.ChatEventEnum.MESSAGE_RECEIVED_EVENT, message);
                }
                catch (error) {
                    console.error('Error in message received event:', error);
                    socket.emit(constants_1.ChatEventEnum.SOCKET_ERROR_EVENT, "Failed to process received message");
                }
            });
            // Handle disconnection
            socket.on("disconnect", () => {
                colorsUtils_1.default.log("info", `User disconnected: ${socket.user?._id}`);
                if (socket.user?._id) {
                    socket.leave(socket.user._id.toString());
                }
            });
            // Error handling
            socket.on("error", (error) => {
                console.error("Socket error:", error);
                socket.emit(constants_1.ChatEventEnum.SOCKET_ERROR_EVENT, "An error occurred");
            });
        }
        catch (error) {
            console.error("Socket connection error:", error);
            socket.emit(constants_1.ChatEventEnum.SOCKET_ERROR_EVENT, "Failed to establish socket connection");
            socket.disconnect(true);
        }
    });
};
exports.initSocketIo = initSocketIo;
const emitSocketEvent = (req, roomId, event, payload) => {
    try {
        const io = req.app.get("io");
        if (!io) {
            colorsUtils_1.default.log("error", "❌ Socket.io instance not found in app");
            return;
        }
        // Safe check for adapter and rooms
        let clientCount = 0;
        let room = null;
        if (io.adapter && io.adapter.rooms) {
            room = io.adapter.rooms.get(roomId);
            clientCount = room ? room.size : 0;
        }
        colorsUtils_1.default.log("info", `📡 Emitting '${event}' to room '${roomId}' (${clientCount} clients)`);
        console.log(`📦 Event payload:`, {
            event,
            roomId,
            payloadKeys: Object.keys(payload || {}),
            clientsInRoom: clientCount
        });
        if (clientCount === 0) {
            // If no clients in room, try to find user's socket and emit directly
            colorsUtils_1.default.log("warning", `⚠️ No clients in room '${roomId}', searching for user socket...`);
            let foundSocket = false;
            if (io.sockets && io.sockets.sockets) {
                for (const [socketId, socket] of io.sockets.sockets) {
                    if (socket.user && socket.user._id.toString() === roomId) {
                        colorsUtils_1.default.log("info", `🎯 Found user socket ${socketId}, emitting directly`);
                        socket.emit(event, payload);
                        foundSocket = true;
                    }
                }
            }
            if (!foundSocket) {
                colorsUtils_1.default.log("error", `❌ User ${roomId} not found in connected sockets`);
            }
        }
        else {
            io.in(roomId).emit(event, payload);
        }
    }
    catch (error) {
        colorsUtils_1.default.log("error", `❌ Error emitting socket event: ${error}`);
    }
};
exports.emitSocketEvent = emitSocketEvent;
// Helper function to emit to specific user by ID
const emitToUser = (req, userId, event, payload) => {
    try {
        const io = req.app.get("io");
        if (!io) {
            colorsUtils_1.default.log("error", "❌ Socket.io instance not found in app");
            return;
        }
        let userFound = false;
        // Find all sockets for this user and emit to each
        if (io.sockets && io.sockets.sockets) {
            for (const [socketId, socket] of io.sockets.sockets) {
                if (socket.user && socket.user._id.toString() === userId) {
                    colorsUtils_1.default.log("info", `🎯 Emitting '${event}' directly to user ${userId} socket ${socketId}`);
                    socket.emit(event, payload);
                    userFound = true;
                }
            }
        }
        if (!userFound) {
            colorsUtils_1.default.log("warning", `⚠️ User ${userId} not found in connected sockets for event '${event}'`);
        }
    }
    catch (error) {
        colorsUtils_1.default.log("error", `❌ Error emitting to user: ${error}`);
    }
};
exports.emitToUser = emitToUser;
//# sourceMappingURL=index.js.map