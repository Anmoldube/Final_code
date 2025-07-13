"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const express_1 = require("express");
const auth_middlewares_1 = require("../middlewares/auth.middlewares");
const mongoId_validator_1 = require("../validators/mongoId.validator");
const validate_1 = require("../validators/validate");
const message_controller_1 = require("../controllers/message.controller");
const messages_validator_1 = require("../validators/messages.validator");
const multer_middlwares_1 = require("../middlewares/multer.middlwares");
const router = (0, express_1.Router)();
// verify the jwt token with the verifyJWT middleware for all comming request at this route
router.use(auth_middlewares_1.verifyJWT);
// Get all unread messages across all chats
router.route("/unread").get(message_controller_1.getAllUnreadMessages);
router
    .route("/:chatId")
    .get((0, mongoId_validator_1.mongoIdPathValidator)("chatId"), validate_1.validate, message_controller_1.getAllMessages)
    .post((0, mongoId_validator_1.mongoIdPathValidator)("chatId"), (0, messages_validator_1.messagesValidator)(), validate_1.validate, multer_middlwares_1.upload.fields([{ name: "attachments", maxCount: 5 }]), message_controller_1.sendMessage);
// Mark all messages in a chat as read
router
    .route("/:chatId/read")
    .post((0, mongoId_validator_1.mongoIdPathValidator)("chatId"), validate_1.validate, message_controller_1.markAllMessagesAsRead);
// Get unread messages count for a specific chat
router
    .route("/:chatId/unread")
    .get((0, mongoId_validator_1.mongoIdPathValidator)("chatId"), validate_1.validate, message_controller_1.getUnreadMessagesCount);
// Delete a message
router
    .route("/:messageId")
    .delete((0, mongoId_validator_1.mongoIdPathValidator)("messageId"), validate_1.validate, message_controller_1.deleteMessage);
// Mark a specific message as read
router
    .route("/:messageId/read")
    .post((0, mongoId_validator_1.mongoIdPathValidator)("messageId"), validate_1.validate, message_controller_1.markMessageAsRead);
exports.default = router;
//# sourceMappingURL=message.routes.js.map