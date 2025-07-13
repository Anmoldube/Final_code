"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.verifyJWT = void 0;
const asyncHandler_1 = __importDefault(require("../helpers/asyncHandler"));
const ApiError_1 = require("../core/ApiError");
const JWT_1 = __importDefault(require("../core/JWT"));
const userRepo_1 = __importDefault(require("../database/repositories/userRepo"));
const mongoose_1 = require("mongoose");
exports.verifyJWT = (0, asyncHandler_1.default)(async (req, res, next) => {
    const token = req.cookies?.accessToken ||
        req.header("Authorization")?.replace("Bearer ", "");
    if (!token) {
        throw new ApiError_1.BadTokenError("No token provided");
    }
    try {
        // Use validateToken instead of decodeToken to check expiration
        const decodedToken = await JWT_1.default.validateToken(token);
        const userData = await userRepo_1.default.findById(new mongoose_1.Types.ObjectId(decodedToken.sub));
        if (!userData) {
            throw new ApiError_1.AuthFailureError("User not found");
        }
        req.user = userData;
        console.log(`✅ Auth middleware: User ${userData.username} (${userData._id}) authenticated successfully`);
        next();
    }
    catch (error) {
        console.log(`❌ Auth middleware error: ${error}`);
        if (error instanceof ApiError_1.TokenExpiredError) {
            throw new ApiError_1.AccessTokenError("Access token expired");
        }
        if (error instanceof ApiError_1.BadTokenError) {
            throw new ApiError_1.AccessTokenError("Invalid access token");
        }
        throw new ApiError_1.AuthFailureError("Authentication failed");
    }
});
//# sourceMappingURL=auth.middlewares.js.map