"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.connection = void 0;
const mongoose_1 = __importDefault(require("mongoose"));
const config_1 = require("../config");
const colorsUtils_1 = __importDefault(require("../helpers/colorsUtils"));
const seedRoles_1 = __importDefault(require("../seeds/seedRoles"));
const defaultGroupService_1 = __importDefault(require("../services/defaultGroupService"));
// db con URI
const dbURI = `${config_1.db.url}/${config_1.db.name}`;
// additional configuration option for db
const options = {
    minPoolSize: config_1.db.minPoolSize,
    maxPoolSize: config_1.db.maxPoolSize,
    connectTimeoutMS: 60000,
    socketTimeoutMS: 45000,
};
mongoose_1.default.set("strictQuery", true);
function setRunValidators() {
    this.setOptions({ runValidators: true });
}
// create a connection to the database
mongoose_1.default
    .plugin((schema) => {
    schema.pre("findOneAndUpdate", setRunValidators);
    schema.pre("updateMany", setRunValidators);
    schema.pre("updateOne", setRunValidators);
    schema.pre("update", setRunValidators);
})
    .connect(dbURI, options)
    .then(() => {
    colorsUtils_1.default.log("success", "🛢  mongoose connection done");
})
    .catch((e) => {
    console.error("mongoose connection error: " + e.message);
});
// connection events
mongoose_1.default.connection.on("connected", () => {
    colorsUtils_1.default.log("success", "🔗 mongoose connection opened : " + mongoose_1.default.connection.host);
});
// seed the roles and initialize default group once db is opened
mongoose_1.default.connection.once("open", async () => {
    await (0, seedRoles_1.default)();
    await defaultGroupService_1.default.initializeDefaultGroup();
});
mongoose_1.default.connection.on("disconnected", () => {
    colorsUtils_1.default.log("warning", "mongoose connection disconnected");
});
exports.connection = mongoose_1.default.connection;
//# sourceMappingURL=index.js.map