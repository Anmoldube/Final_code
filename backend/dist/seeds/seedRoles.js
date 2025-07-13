"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
const colorsUtils_1 = __importDefault(require("../helpers/colorsUtils"));
const Role_1 = require("../database/model/Role");
const seedRoles = async () => {
    const roles = [
        {
            code: "ADMIN",
        },
        {
            code: "USER",
        },
    ];
    try {
        const existingRoles = await Role_1.RoleModel.find();
        if (!existingRoles.length) {
            await Role_1.RoleModel.insertMany(roles);
            colorsUtils_1.default.log("success", "Roles seeded successfully");
        }
        else {
            colorsUtils_1.default.log("info", "Roles already exists");
        }
    }
    catch (error) {
        colorsUtils_1.default.log("error", "Roles seeding failed");
    }
};
exports.default = seedRoles;
//# sourceMappingURL=seedRoles.js.map