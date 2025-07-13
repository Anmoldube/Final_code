"use strict";
var __createBinding = (this && this.__createBinding) || (Object.create ? (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    var desc = Object.getOwnPropertyDescriptor(m, k);
    if (!desc || ("get" in desc ? !m.__esModule : desc.writable || desc.configurable)) {
      desc = { enumerable: true, get: function() { return m[k]; } };
    }
    Object.defineProperty(o, k2, desc);
}) : (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    o[k2] = m[k];
}));
var __setModuleDefault = (this && this.__setModuleDefault) || (Object.create ? (function(o, v) {
    Object.defineProperty(o, "default", { enumerable: true, value: v });
}) : function(o, v) {
    o["default"] = v;
});
var __importStar = (this && this.__importStar) || (function () {
    var ownKeys = function(o) {
        ownKeys = Object.getOwnPropertyNames || function (o) {
            var ar = [];
            for (var k in o) if (Object.prototype.hasOwnProperty.call(o, k)) ar[ar.length] = k;
            return ar;
        };
        return ownKeys(o);
    };
    return function (mod) {
        if (mod && mod.__esModule) return mod;
        var result = {};
        if (mod != null) for (var k = ownKeys(mod), i = 0; i < k.length; i++) if (k[i] !== "default") __createBinding(result, mod, k[i]);
        __setModuleDefault(result, mod);
        return result;
    };
})();
Object.defineProperty(exports, "__esModule", { value: true });
exports.validateTokenData = exports.createTokens = exports.splitAccessToken = void 0;
const mongoose_1 = require("mongoose");
const config_1 = require("../../config");
const ApiError_1 = require("../../core/ApiError");
const JWT_1 = __importStar(require("../../core/JWT"));
const splitAccessToken = (token) => {
    if (!token)
        throw new ApiError_1.AuthFailureError("missing authorization token");
    if (!token.startsWith("Bearer "))
        throw new ApiError_1.AuthFailureError("inalid authorization token");
    return token.split(" ")[1];
};
exports.splitAccessToken = splitAccessToken;
const createTokens = async (user) => {
    const accessToken = await JWT_1.default.generateToken(new JWT_1.JwtPayload(config_1.tokenInfo.issuer, config_1.tokenInfo.audience, user._id.toString(), config_1.tokenInfo.accessTokenValidity));
    if (!accessToken)
        throw new ApiError_1.InternalError("Error creating access token");
    const refreshToken = await JWT_1.default.generateToken(new JWT_1.JwtPayload(config_1.tokenInfo.issuer, config_1.tokenInfo.audience, user._id.toString(), config_1.tokenInfo.refreshTokenValidity));
    if (!refreshToken)
        throw new Error("Error creating refresh token");
    return {
        accessToken,
        refreshToken,
    };
};
exports.createTokens = createTokens;
const validateTokenData = (payload) => {
    if (!payload ||
        !payload.iss ||
        !payload.aud ||
        !payload.sub ||
        payload.iss !== config_1.tokenInfo.issuer ||
        payload.aud !== config_1.tokenInfo.audience ||
        !mongoose_1.Types.ObjectId.isValid(payload.sub))
        throw new ApiError_1.AuthFailureError("invalid access token");
    return true;
};
exports.validateTokenData = validateTokenData;
//# sourceMappingURL=authUtils.js.map