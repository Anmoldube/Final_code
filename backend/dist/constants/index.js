"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.ChatEventEnum = void 0;
var ChatEventEnum;
(function (ChatEventEnum) {
    ChatEventEnum["CONNECTED_EVENT"] = "connected";
    ChatEventEnum["DISCONNECTED_EVENT"] = "disconnected";
    ChatEventEnum["JOIN_CHAT_EVENT"] = "joinChat";
    ChatEventEnum["JOIN_USER_GROUPS_EVENT"] = "join_user_groups";
    ChatEventEnum["LEAVE_CHAT_EVENT"] = "leaveChat";
    ChatEventEnum["UPDATE_GROUP_NAME_EVENT"] = "updateGroupName";
    ChatEventEnum["MESSAGE_RECEIVED_EVENT"] = "messageReceived";
    ChatEventEnum["MESSAGE_DELETE_EVENT"] = "messageDeleted";
    ChatEventEnum["NEW_CHAT_EVENT"] = "newChatEvent";
    ChatEventEnum["SOCKET_ERROR_EVENT"] = "socketError";
    ChatEventEnum["START_TYPING_EVENT"] = "startTyping";
    ChatEventEnum["STOP_TYPING_EVENT"] = "stopTyping";
    ChatEventEnum["MESSAGE_READ_EVENT"] = "messageRead";
    ChatEventEnum["MESSAGE_DELIVERED_EVENT"] = "messageDelivered";
    ChatEventEnum["MESSAGE_STATUS_UPDATE_EVENT"] = "messageStatusUpdate";
    ChatEventEnum["MESSAGE_SENT_EVENT"] = "messageSent";
    ChatEventEnum["MESSAGE_FAILED_EVENT"] = "messageFailed";
    ChatEventEnum["NOTIFICATION_EVENT"] = "notification";
    ChatEventEnum["CONVERSATION_UPDATED"] = "conversationUpdated";
    ChatEventEnum["CONVERSATION_READ"] = "conversationRead";
})(ChatEventEnum || (exports.ChatEventEnum = ChatEventEnum = {}));
//# sourceMappingURL=index.js.map