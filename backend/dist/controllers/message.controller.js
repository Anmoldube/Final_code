"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.getAllUnreadMessages = exports.getUnreadMessagesCount = exports.markAllMessagesAsRead = exports.markMessageAsRead = exports.deleteMessage = exports.sendMessage = exports.getAllMessages = void 0;
const ApiError_1 = require("../core/ApiError");
const ApiResponse_1 = require("../core/ApiResponse");
const mongoose_1 = require("mongoose");
const chatRepo_1 = __importDefault(require("../database/repositories/chatRepo"));
const messageRepo_1 = __importDefault(require("../database/repositories/messageRepo"));
const asyncHandler_1 = __importDefault(require("../helpers/asyncHandler"));
const utils_1 = require("../helpers/utils");
const socket_1 = require("../socket");
const constants_1 = require("../constants");
const messageService_1 = __importDefault(require("../services/messageService"));
const timeUtils_1 = require("../helpers/timeUtils");
const messageStatusService_1 = __importDefault(require("../services/messageStatusService"));
const Message_1 = require("../database/model/Message");
const conversationService_1 = __importDefault(require("../services/conversationService"));
const FileMetadataService_1 = require("../services/FileMetadataService");
exports.getAllMessages = (0, asyncHandler_1.default)(async (req, res) => {
    const { chatId } = req.params;
    const currentUser = req.user;
    // retrieve the chat of corresponding chatId
    const selectedChat = await chatRepo_1.default.getChatByChatId(new mongoose_1.Types.ObjectId(chatId));
    // if not chat found throw an error
    if (!selectedChat) {
        throw new ApiError_1.NotFoundError("no chat found to retrieve messages");
    }
    // check for existance of current user in the chats
    const isParticipant = selectedChat.participants?.some((participantId) => participantId.toString() === currentUser?._id.toString());
    if (!isParticipant) {
        console.log(`❌ Chat ownership check failed:`);
        console.log(`Chat ID: ${chatId}`);
        console.log(`Current User ID: ${currentUser?._id}`);
        console.log(`Participants: ${selectedChat.participants?.map(p => p.toString())}`);
        throw new ApiError_1.AuthFailureError("you don't own the chat !");
    }
    console.log(`✅ Chat ownership verified for user ${currentUser?._id} in chat ${chatId}`);
    // get all the messages in aggreated form
    const messages = await messageRepo_1.default.getAllMessagesAggregated(new mongoose_1.Types.ObjectId(chatId));
    if (!messages) {
        throw new ApiError_1.InternalError("error while retrieving messages");
    }
    return new ApiResponse_1.SuccessResponse("messages retrieved successfully", messages).send(res);
});
// send a message
exports.sendMessage = (0, asyncHandler_1.default)(async (req, res) => {
    const { content } = req.body;
    const { chatId } = req.params;
    const currentUserId = req.user?._id;
    const files = req.files || {
        attachments: [],
    };
    if (!chatId) {
        throw new ApiError_1.BadRequestError("no chat id provided");
    }
    if (!content && !files.attachments?.length) {
        throw new ApiError_1.BadRequestError("no content provided");
    }
    const selectedChat = await chatRepo_1.default.getChatByChatId(new mongoose_1.Types.ObjectId(chatId));
    if (!selectedChat) {
        throw new ApiError_1.NotFoundError("No chat found");
    }
    // hold the files sent by user and creating url to access to it
    const attachmentFiles = [];
    // Process file attachments and save metadata
    for (let index = 0; index < (files.attachments?.length || 0); index++) {
        const attachment = files.attachments[index];
        // Get the file type from the mimetype
        const fileType = getFileTypeFromMimetype(attachment.mimetype);
        // Create the file path with the file type directory
        const filePath = `${fileType}/${attachment.filename}`;
        // Create the basic attachment object
        const attachmentObj = {
            url: (0, utils_1.getStaticFilePath)(filePath),
            localPath: (0, utils_1.getLocalFilePath)(filePath),
            originalName: attachment.originalname, // Store the original filename
            type: attachment.mimetype // Store the MIME type
        };
        console.log(`File attachment ${index}:`, {
            filename: attachment.filename,
            mimetype: attachment.mimetype,
            fileType,
            url: attachmentObj.url,
            localPath: attachmentObj.localPath,
            fileSize: attachment.size
        });
        // Save file metadata to database (will update with messageId after message creation)
        try {
            console.log(`🔄 Attempting to save file metadata for ${attachment.filename}...`);
            const fileMetadata = await FileMetadataService_1.FileMetadataService.createFileMetadata({
                originalName: attachment.originalname,
                fileName: attachment.filename,
                filePath: filePath,
                mimeType: attachment.mimetype,
                fileSize: attachment.size || 0,
                uploadedBy: currentUserId.toString(),
                chatId: chatId,
                metadata: {
                    category: fileType.replace('s', ''), // Remove the 's' from 'images', 'videos', etc.
                    isEncrypted: false,
                }
            });
            console.log(`✅ File metadata saved for ${attachment.filename}:`, fileMetadata._id);
            // Add the file metadata ID to the attachment object
            attachmentObj.fileMetadataId = fileMetadata._id.toString();
        }
        catch (error) {
            console.error(`❌ Error saving file metadata for ${attachment.filename}:`, error);
            console.error(`Error details:`, error.message);
            console.error(`Stack trace:`, error.stack);
            console.error(`Data being saved:`, {
                originalName: attachment.originalname,
                fileName: attachment.filename,
                filePath: filePath,
                mimeType: attachment.mimetype,
                fileSize: attachment.size || 0,
                uploadedBy: currentUserId.toString(),
                chatId: chatId,
            });
            // Continue without metadata ID - the file will still work
        }
        attachmentFiles.push(attachmentObj);
    }
    // Helper function to determine file type based on mimetype
    function getFileTypeFromMimetype(mimetype) {
        const mainType = mimetype.split('/')[0];
        switch (mainType) {
            case 'image':
                return 'images';
            case 'video':
                return 'videos';
            case 'audio':
                return 'audio';
            case 'application':
                if (mimetype.includes('pdf') || mimetype.includes('word') ||
                    mimetype.includes('excel') || mimetype.includes('text')) {
                    return 'documents';
                }
                return 'other';
            default:
                return 'other';
        }
    }
    // Prepare the message content
    const messageContent = content || "";
    // Log the attachment files for debugging
    console.log("Attachment files:", attachmentFiles.map(file => ({
        url: file.url,
        originalName: file.originalName
    })));
    let message;
    try {
        // create a new message with attachmentsFiles (starts as PENDING)
        message = await messageRepo_1.default.createMessage(new mongoose_1.Types.ObjectId(currentUserId), new mongoose_1.Types.ObjectId(chatId), messageContent, attachmentFiles);
        // Update message status to SENT since it was successfully created
        await messageStatusService_1.default.updateMessageStatus(req, message._id.toString(), Message_1.MessageStatus.SENT);
        // Update file metadata with messageId
        console.log(`🔄 Updating file metadata with messageId: ${message._id.toString()}`);
        for (const attachment of attachmentFiles) {
            if (attachment.fileMetadataId) {
                try {
                    await FileMetadataService_1.FileMetadataService.updateFileMetadata(attachment.fileMetadataId, {
                        messageId: message._id.toString()
                    });
                    console.log(`✅ Updated file metadata ${attachment.fileMetadataId} with messageId`);
                }
                catch (error) {
                    console.error(`❌ Error updating file metadata with messageId:`, error);
                }
            }
        }
        // updating the last message of the chat
        const updatedChat = await chatRepo_1.default.updateChatFields(new mongoose_1.Types.ObjectId(chatId), { lastMessage: message._id });
        // Update conversation metadata for WhatsApp-like sorting
        await conversationService_1.default.updateConversationOnNewMessage(req, new mongoose_1.Types.ObjectId(chatId), message._id, messageContent, new mongoose_1.Types.ObjectId(currentUserId), attachmentFiles);
        // structure the message
        const structuredMessage = await messageRepo_1.default.getStructuredMessages(message._id);
        if (!structuredMessage.length) {
            throw new ApiError_1.InternalError("error creating message: " + message._id);
        }
        // emit socket event to chat room to receive current message (excluding sender)
        console.log(`📡 Broadcasting message to chat room: ${chatId} (excluding sender)`);
        const io = req.app.get("io");
        if (io) {
            // Safe check for adapter and rooms
            let room = null;
            if (io.adapter && io.adapter.rooms) {
                room = io.adapter.rooms.get(chatId);
            }
            if (room) {
                room.forEach((socketId) => {
                    const socket = io.sockets.sockets.get(socketId);
                    // Only emit to sockets that don't belong to the message sender
                    if (socket && socket.user && socket.user._id.toString() !== currentUserId.toString()) {
                        socket.emit(constants_1.ChatEventEnum.MESSAGE_RECEIVED_EVENT, structuredMessage[0]);
                        console.log(`📡 Sent message to socket ${socketId} (user: ${socket.user._id})`);
                    }
                });
            }
            else {
                // Fallback: emit to all connected sockets if room is not available
                console.log(`⚠️ Room ${chatId} not found, using fallback broadcast`);
                if (io.sockets && io.sockets.sockets) {
                    io.sockets.sockets.forEach((socket) => {
                        if (socket.user && socket.user._id.toString() !== currentUserId.toString()) {
                            socket.emit(constants_1.ChatEventEnum.MESSAGE_RECEIVED_EVENT, structuredMessage[0]);
                            console.log(`📡 Sent message to socket ${socket.id} (user: ${socket.user._id}) via fallback`);
                        }
                    });
                }
            }
        }
        // Fallback: Send to participants not in chat room (excluding sender)
        console.log("📡 Checking for participants not in chat room");
        if (io) {
            // Safe check for adapter and rooms
            let room = null;
            let clientsInRoom = [];
            if (io.adapter && io.adapter.rooms) {
                room = io.adapter.rooms.get(chatId);
                clientsInRoom = room ? Array.from(room) : [];
            }
            updatedChat.participants.forEach((participantId) => {
                const participantIdStr = participantId.toString();
                // Skip the message sender
                if (participantIdStr === currentUserId.toString()) {
                    return;
                }
                // Check if participant has any socket connected to the chat room
                let participantInRoom = false;
                if (io.sockets && io.sockets.sockets) {
                    for (const [socketId, socket] of io.sockets.sockets) {
                        if (socket.user && socket.user._id.toString() === participantIdStr &&
                            clientsInRoom.includes(socketId)) {
                            participantInRoom = true;
                            break;
                        }
                    }
                }
                // Only send direct message if participant is not in the chat room
                if (!participantInRoom) {
                    console.log(`📡 Sending direct message to offline participant: ${participantIdStr}`);
                    (0, socket_1.emitToUser)(req, participantIdStr, constants_1.ChatEventEnum.MESSAGE_RECEIVED_EVENT, structuredMessage[0]);
                }
            });
        }
        // Emit SENT status confirmation to sender
        (0, socket_1.emitToUser)(req, currentUserId.toString(), constants_1.ChatEventEnum.MESSAGE_SENT_EVENT, {
            messageId: message._id.toString(),
            status: Message_1.MessageStatus.SENT,
            sentAt: new Date().toISOString(),
        });
        return new ApiResponse_1.SuccessResponse("message sent successfully", structuredMessage[0]).send(res);
    }
    catch (error) {
        console.error("Error sending message:", error);
        // If message was created but failed to send, mark as FAILED
        if (message && message._id) {
            await messageStatusService_1.default.updateMessageStatus(req, message._id.toString(), Message_1.MessageStatus.FAILED, undefined, (error instanceof Error ? error.message : String(error)));
        }
        throw new ApiError_1.InternalError("Failed to send message");
    }
});
// delete message
exports.deleteMessage = (0, asyncHandler_1.default)(async (req, res) => {
    const { messageId } = req.params;
    const currentUserId = req.user?._id;
    if (!messageId) {
        throw new ApiError_1.BadRequestError("no message id provided");
    }
    const existingMessage = await messageRepo_1.default.getMessageById(new mongoose_1.Types.ObjectId(messageId));
    if (!existingMessage)
        throw new ApiError_1.BadRequestError("invalid message id, message not found");
    // fetch the existing chat
    const existingChat = await chatRepo_1.default.getChatByChatId(existingMessage?.chat);
    if (!existingChat)
        throw new ApiError_1.InternalError("Internal Error: chat not found");
    // if the existing chat participants includes the current userId
    if (!existingChat?.participants?.some((participantId) => participantId.toString() === currentUserId.toString())) {
        throw new ApiError_1.AuthFailureError("you don't own the message");
    }
    // check if for currentUserId presence in the message sender
    if (!(existingMessage.sender.toString() === currentUserId.toString()))
        throw new ApiError_1.AuthFailureError("you don't own the message ");
    // delete the attachments of the message from the local folder
    if (existingMessage &&
        existingMessage.attachments &&
        existingMessage.attachments.length > 0) {
        existingMessage.attachments.forEach(({ localPath }) => {
            (0, utils_1.removeLocalFile)(localPath);
        });
    }
    // delete the message from database
    const deletedMsg = await messageRepo_1.default.deleteMessageById(existingMessage._id);
    if (!deletedMsg)
        throw new ApiError_1.InternalError("Internal Error: Couldn't delete message");
    // update the last message of the chat
    let lastMessage;
    if (existingChat?.lastMessage?.toString() === existingMessage._id.toString()) {
        lastMessage = await messageRepo_1.default.getLastMessage(existingChat._id);
        await chatRepo_1.default.updateChatFields(existingChat._id, {
            $set: {
                lastMessage: lastMessage?._id,
            },
        });
    }
    // emit delete message event to chat room
    (0, socket_1.emitSocketEvent)(req, existingChat._id.toString(), // Send to the chat room instead of individual users
    constants_1.ChatEventEnum.MESSAGE_DELETE_EVENT, {
        messageId: existingMessage._id,
        chatId: existingChat._id.toString(),
        // chatLastMessage: lastMessage.content || "attachment",
    });
    return new ApiResponse_1.SuccessMsgResponse("message deleted successfully").send(res);
});
// Mark a message as read
exports.markMessageAsRead = (0, asyncHandler_1.default)(async (req, res) => {
    const { messageId } = req.params;
    const currentUserId = req.user?._id;
    if (!messageId) {
        throw new ApiError_1.BadRequestError("No message id provided");
    }
    (0, timeUtils_1.logTimeInfo)('markMessageAsRead');
    const existingMessage = await messageRepo_1.default.getMessageById(new mongoose_1.Types.ObjectId(messageId));
    if (!existingMessage) {
        throw new ApiError_1.NotFoundError("Message not found");
    }
    // Check if user is part of the chat
    const existingChat = await chatRepo_1.default.getChatByChatId(existingMessage.chat);
    if (!existingChat) {
        throw new ApiError_1.NotFoundError("Chat not found");
    }
    if (!existingChat.participants.some((participantId) => participantId.toString() === currentUserId.toString())) {
        throw new ApiError_1.AuthFailureError("You are not a participant of this chat");
    }
    // Don't mark your own messages as read
    if (existingMessage.sender.toString() === currentUserId.toString()) {
        return new ApiResponse_1.SuccessResponse("No need to mark your own message as read", {
            messageId,
            alreadyRead: true
        }).send(res);
    }
    // Check if already read
    if (existingMessage.readBy.some(id => id.toString() === currentUserId.toString())) {
        return new ApiResponse_1.SuccessResponse("Message already marked as read", {
            messageId,
            alreadyRead: true
        }).send(res);
    }
    // Use message service to mark as read and emit events
    const updatedMessage = await messageService_1.default.markMessageAsRead(existingMessage._id, currentUserId, req);
    return new ApiResponse_1.SuccessResponse("Message marked as read", {
        messageId,
        readBy: updatedMessage.readBy,
        readCount: updatedMessage.readBy.length
    }).send(res);
});
// Mark all messages in a chat as read
exports.markAllMessagesAsRead = (0, asyncHandler_1.default)(async (req, res) => {
    const { chatId } = req.params;
    const currentUserId = req.user?._id;
    if (!chatId) {
        throw new ApiError_1.BadRequestError("No chat id provided");
    }
    (0, timeUtils_1.logTimeInfo)('markAllMessagesAsRead');
    const existingChat = await chatRepo_1.default.getChatByChatId(new mongoose_1.Types.ObjectId(chatId));
    if (!existingChat) {
        throw new ApiError_1.NotFoundError("Chat not found");
    }
    if (!existingChat.participants.some((participantId) => participantId.toString() === currentUserId.toString())) {
        throw new ApiError_1.AuthFailureError("You are not a participant of this chat");
    }
    // Use message service to mark all messages as read and emit events
    const result = await messageService_1.default.markAllMessagesAsRead(existingChat._id, currentUserId, req);
    return new ApiResponse_1.SuccessResponse("All messages marked as read", {
        chatId,
        modifiedCount: result.modifiedCount
    }).send(res);
});
// Get unread messages count for a user
exports.getUnreadMessagesCount = (0, asyncHandler_1.default)(async (req, res) => {
    const { chatId } = req.params;
    const currentUserId = req.user?._id;
    if (!chatId) {
        throw new ApiError_1.BadRequestError("No chat id provided");
    }
    const existingChat = await chatRepo_1.default.getChatByChatId(new mongoose_1.Types.ObjectId(chatId));
    if (!existingChat) {
        throw new ApiError_1.NotFoundError("Chat not found");
    }
    if (!existingChat.participants.some((participantId) => participantId.toString() === currentUserId.toString())) {
        throw new ApiError_1.AuthFailureError("You are not a participant of this chat");
    }
    const count = await messageRepo_1.default.getUnreadMessagesCount(existingChat._id, currentUserId);
    return new ApiResponse_1.SuccessResponse("Unread messages count retrieved", {
        chatId,
        unreadCount: count
    }).send(res);
});
// Get all unread messages for a user across all chats
exports.getAllUnreadMessages = (0, asyncHandler_1.default)(async (req, res) => {
    const currentUserId = req.user?._id;
    const unreadMessages = await messageRepo_1.default.getAllUnreadMessages(currentUserId);
    return new ApiResponse_1.SuccessResponse("All unread messages retrieved", unreadMessages).send(res);
});
//# sourceMappingURL=message.controller.js.map