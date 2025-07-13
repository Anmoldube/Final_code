"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.JwtPayload = void 0;
const jsonwebtoken_1 = require("jsonwebtoken");
const ApiError_1 = require("./ApiError");
const config_1 = require("../config");
class JwtPayload {
    aud;
    sub;
    iss;
    iat;
    exp;
    constructor(issuer, audience, subject, validity) {
        this.iss = issuer;
        this.aud = audience;
        this.sub = subject;
        this.iat = Math.floor(Date.now() / 1000);
        this.exp = this.iat + validity;
    }
}
exports.JwtPayload = JwtPayload;
// create token from jwt
const generateToken = async (payload) => {
    if (!config_1.tokenInfo.jwtSecretKey)
        throw new ApiError_1.InternalError("required jwt secret key");
    return new Promise((resolve, reject) => {
        (0, jsonwebtoken_1.sign)({ ...payload }, config_1.tokenInfo.jwtSecretKey, (err, token) => {
            if (err)
                reject(err);
            resolve(token);
        });
    });
};
// verify and return the decoded token payload
const validateToken = async (token) => {
    if (!token)
        throw new ApiError_1.InternalError("no token provided");
    try {
        return new Promise((resolve, reject) => {
            (0, jsonwebtoken_1.verify)(token, config_1.tokenInfo.jwtSecretKey, (err, decoded) => {
                if (err)
                    reject(err);
                resolve(decoded);
            });
        });
    }
    catch (e) {
        if (e && e.name === "TokenExpiredError")
            throw new ApiError_1.TokenExpiredError();
        // throws error if other error occurs
        throw new ApiError_1.BadTokenError();
    }
};
// return the decoded token payload even if token is expired
const decodeToken = async (token) => {
    if (!token)
        throw new ApiError_1.InternalError("no token provided");
    try {
        const options = {
            ignoreExpiration: true,
        };
        return new Promise((resolve, reject) => {
            (0, jsonwebtoken_1.verify)(token, config_1.tokenInfo.jwtSecretKey, options, (err, decoded) => {
                if (err)
                    reject(err);
                resolve(decoded);
            });
        });
    }
    catch (error) {
        throw new ApiError_1.BadTokenError();
    }
};
exports.default = {
    generateToken,
    validateToken,
    decodeToken,
};
//# sourceMappingURL=JWT.js.map