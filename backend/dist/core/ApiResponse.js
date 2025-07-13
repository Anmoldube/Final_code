"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.NotFoundResponse = exports.AccessTokenErrorResponse = exports.SuccessResponse = exports.FailureMsgResponse = exports.SuccessMsgResponse = exports.AuthFailureResponse = exports.RateLimitResponse = exports.BadRequestResponse = exports.InternalErrorResponse = void 0;
// ENUM STATUS CODE  FOR API CONSUMERS
var StatusCode;
(function (StatusCode) {
    StatusCode["SUCCESS"] = "10000";
    StatusCode["FAILURE"] = "10001";
    StatusCode["RETRY"] = "10002";
    StatusCode["INVALID_ACCESS_TOKEN"] = "10003";
    StatusCode["RATE_LIMIT"] = "10004";
})(StatusCode || (StatusCode = {}));
// ENUM RESPONSE STATUS CODES FOR CLIENT
var ResponseStatus;
(function (ResponseStatus) {
    ResponseStatus[ResponseStatus["SUCCESS"] = 200] = "SUCCESS";
    ResponseStatus[ResponseStatus["BAD_REQUEST"] = 400] = "BAD_REQUEST";
    ResponseStatus[ResponseStatus["UNAUTHORIZED"] = 401] = "UNAUTHORIZED";
    ResponseStatus[ResponseStatus["FORBIDDEN"] = 403] = "FORBIDDEN";
    ResponseStatus[ResponseStatus["NOT_FOUND"] = 404] = "NOT_FOUND";
    ResponseStatus[ResponseStatus["INTERNAL_ERROR"] = 500] = "INTERNAL_ERROR";
    ResponseStatus[ResponseStatus["RATE_LIMIT"] = 429] = "RATE_LIMIT";
})(ResponseStatus || (ResponseStatus = {}));
class ApiResponse {
    statusCode;
    status;
    message;
    constructor(statusCode, status, message) {
        this.statusCode = statusCode;
        this.status = status;
        this.message = message;
    }
    // Prepares the HTTP response with the provided headers and sanitized response object, and sets the HTTP status code.
    prepare(res, response, headers) {
        // Ensure CORS headers are set for all responses with dynamic origin
        const origin = res.req.headers.origin;
        if (origin &&
            ["http://192.168.1.6:5173", "http://localhost:5173"].includes(origin)) {
            res.header("Access-Control-Allow-Origin", origin);
        }
        res.header("Access-Control-Allow-Credentials", "true");
        res.header("Access-Control-Allow-Methods", "GET, POST, PUT, DELETE, OPTIONS");
        res.header("Access-Control-Allow-Headers", "Content-Type, Authorization, X-Requested-With");
        // Add any additional headers
        for (const [key, value] of Object.entries(headers))
            res.append(key, value);
        return res.status(this.status).json(ApiResponse.sanitize(response));
    }
    // Sanitizes the response object by removing undefined properties and the 'status' property.
    static sanitize(response) {
        const clone = {};
        Object.assign(clone, response);
        // @ts-ignore
        delete clone.status;
        for (const i in clone)
            if (typeof clone[i] === "undefined")
                delete clone[i];
        return clone;
    }
    send(res, headers = {}) {
        return this.prepare(res, this, headers);
    }
}
class InternalErrorResponse extends ApiResponse {
    constructor(message) {
        super(StatusCode.FAILURE, ResponseStatus.INTERNAL_ERROR, message);
    }
}
exports.InternalErrorResponse = InternalErrorResponse;
class BadRequestResponse extends ApiResponse {
    constructor(message) {
        super(StatusCode.FAILURE, ResponseStatus.BAD_REQUEST, message);
    }
}
exports.BadRequestResponse = BadRequestResponse;
class RateLimitResponse extends ApiResponse {
    constructor(message) {
        super(StatusCode.RATE_LIMIT, ResponseStatus.RATE_LIMIT, message);
    }
}
exports.RateLimitResponse = RateLimitResponse;
class AuthFailureResponse extends ApiResponse {
    constructor(message) {
        super(StatusCode.FAILURE, ResponseStatus.UNAUTHORIZED, message);
    }
}
exports.AuthFailureResponse = AuthFailureResponse;
class SuccessMsgResponse extends ApiResponse {
    constructor(message) {
        super(StatusCode.SUCCESS, ResponseStatus.SUCCESS, message);
    }
}
exports.SuccessMsgResponse = SuccessMsgResponse;
class FailureMsgResponse extends ApiResponse {
    constructor(message) {
        super(StatusCode.FAILURE, ResponseStatus.SUCCESS, message);
    }
}
exports.FailureMsgResponse = FailureMsgResponse;
class SuccessResponse extends ApiResponse {
    data;
    constructor(message = "success", data) {
        super(StatusCode.SUCCESS, ResponseStatus.SUCCESS, message);
        this.data = data;
    }
    send(res, headers = {}) {
        return super.prepare(res, this, headers);
    }
}
exports.SuccessResponse = SuccessResponse;
class AccessTokenErrorResponse extends ApiResponse {
    instruction = "refresh_token";
    constructor(message = "Access token invalid") {
        super(StatusCode.INVALID_ACCESS_TOKEN, ResponseStatus.UNAUTHORIZED, message);
    }
    send(res, headers = {}) {
        headers.instruction = this.instruction;
        return super.prepare(res, this, headers);
    }
}
exports.AccessTokenErrorResponse = AccessTokenErrorResponse;
class NotFoundResponse extends ApiResponse {
    constructor(message = "Not Found") {
        super(StatusCode.FAILURE, ResponseStatus.NOT_FOUND, message);
    }
    send(res, headers = {}) {
        return super.prepare(res, this, headers);
    }
}
exports.NotFoundResponse = NotFoundResponse;
//# sourceMappingURL=ApiResponse.js.map