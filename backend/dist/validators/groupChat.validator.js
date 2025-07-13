"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.updateGroupChatValidator = exports.createGroupChatValidator = void 0;
const express_validator_1 = require("express-validator");
const createGroupChatValidator = () => {
    return [
        (0, express_validator_1.body)("name").trim().notEmpty().withMessage("group name not provided"),
        (0, express_validator_1.body)("participants")
            .isArray({
            min: 2,
            max: 100,
        })
            .withMessage("participants must be between between 2 members and max of 100 participants"),
    ];
};
exports.createGroupChatValidator = createGroupChatValidator;
const updateGroupChatValidator = () => {
    return [
        (0, express_validator_1.param)("chatId").notEmpty().withMessage("chatId not provided"),
        (0, express_validator_1.body)("newParticipantId")
            .trim()
            .notEmpty()
            .withMessage("new participantId not provided"),
    ];
};
exports.updateGroupChatValidator = updateGroupChatValidator;
//# sourceMappingURL=groupChat.validator.js.map