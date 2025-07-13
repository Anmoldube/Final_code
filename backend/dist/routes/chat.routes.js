"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const express_1 = require("express");
const auth_middlewares_1 = require("../middlewares/auth.middlewares");
const chat_controller_1 = require("../controllers/chat.controller");
const mongoId_validator_1 = require("../validators/mongoId.validator");
const validate_1 = require("..//validators/validate");
const groupChat_validator_1 = require("../validators/groupChat.validator");
const router = (0, express_1.Router)();
// authentication middleware for routes
router.use(auth_middlewares_1.verifyJWT);
// route to get searched users
router.route("/users").get(chat_controller_1.searchAvailableusers);
// route to create chat
router
    .route("/c/:receiverId")
    .post((0, mongoId_validator_1.mongoIdPathValidator)("receiverId"), validate_1.validate, chat_controller_1.createOrGetExistingChat);
// route to create new group chat
router
    .route("/group")
    .post((0, groupChat_validator_1.createGroupChatValidator)(), validate_1.validate, chat_controller_1.createGroupChat);
// route to fetch a group chat details
router
    .route("/group/:chatId")
    .get((0, mongoId_validator_1.mongoIdPathValidator)("chatId"), validate_1.validate, chat_controller_1.getGroupChatDetails)
    // add new user to group chat
    .put((0, groupChat_validator_1.updateGroupChatValidator)(), validate_1.validate, chat_controller_1.addNewUserToGroup);
// route to get existingUserChats
router.route("/").get(chat_controller_1.getCurrentUserChats);
// route to get conversations (WhatsApp-like sorted list)
router.route("/conversations").get(chat_controller_1.getConversations);
// route to mark conversation as read
router
    .route("/:chatId/read")
    .post((0, mongoId_validator_1.mongoIdPathValidator)("chatId"), validate_1.validate, chat_controller_1.markConversationAsRead);
router
    .route("/:chatId")
    .delete((0, mongoId_validator_1.mongoIdPathValidator)("chatId"), validate_1.validate, chat_controller_1.deleteChat);
exports.default = router;
//# sourceMappingURL=chat.routes.js.map