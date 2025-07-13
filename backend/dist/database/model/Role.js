"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.RoleModel = exports.RoleCode = exports.DOCUMENT_NAME = void 0;
const mongoose_1 = require("mongoose");
exports.DOCUMENT_NAME = "Role";
var RoleCode;
(function (RoleCode) {
    RoleCode["ADMIN"] = "ADMIN";
    RoleCode["USER"] = "USER";
})(RoleCode || (exports.RoleCode = RoleCode = {}));
const schema = new mongoose_1.Schema({
    code: {
        type: mongoose_1.Schema.Types.String,
        required: true,
        enum: Object.values(RoleCode),
    },
    status: { type: mongoose_1.Schema.Types.Boolean, default: true },
    createdAt: { type: mongoose_1.Schema.Types.Date, default: Date.now },
    updatedAt: { type: mongoose_1.Schema.Types.Date, default: Date.now },
});
// future version add indexing
exports.RoleModel = (0, mongoose_1.model)(exports.DOCUMENT_NAME, schema);
//# sourceMappingURL=Role.js.map