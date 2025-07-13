"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.AccessTokenError = exports.NotFoundError = exports.NoDataError = exports.TokenExpiredError = exports.BadTokenError = exports.AuthFailureError = exports.RateLimitError = exports.BadRequestError = exports.InternalError = exports.ApiError = exports.ErrorType = void 0;
const config_1 = require("../config");
const ApiResponse_1 = require("./ApiResponse");
var ErrorType;
(function (ErrorType) {
    ErrorType["BAD_TOKEN"] = "BadTokenError";
    ErrorType["TOKEN_EXPIRED"] = "TokenExpiredError";
    ErrorType["UNAUTHORIZED"] = "AuthFailureError";
    ErrorType["ACCESS_TOKEN"] = "AccessTokenError";
    ErrorType["INTERNAL"] = "InternalError";
    ErrorType["NOT_FOUND"] = "NotFoundError";
    ErrorType["NO_ENTRY"] = "NoEntryError";
    ErrorType["NO_DATA"] = "NoDataError";
    ErrorType["BAD_REQUEST"] = "BadRequestError";
    ErrorType["RATE_LIMIT"] = "RateLimitError";
    ErrorType["FORBIDDEN"] = "ForbiddenError";
})(ErrorType || (exports.ErrorType = ErrorType = {}));
class ApiError extends Error {
    type;
    message;
    stack;
    constructor(type, message = "error", stack = "") {
        super(type);
        this.type = type;
        this.message = message;
        this.stack = stack;
        if (stack) {
            this.stack = stack;
        }
        else {
            Error.captureStackTrace(this, this.constructor);
        }
    }
    static handle(err, res) {
        switch (err.type) {
            case ErrorType.INTERNAL:
                return new ApiResponse_1.InternalErrorResponse(err.message).send(res);
            case ErrorType.BAD_REQUEST:
                return new ApiResponse_1.BadRequestResponse(err.message).send(res);
            case ErrorType.ACCESS_TOKEN:
                return new ApiResponse_1.AccessTokenErrorResponse(err.message).send(res);
            case ErrorType.NOT_FOUND:
            case ErrorType.NO_ENTRY:
            case ErrorType.NO_DATA:
                return new ApiResponse_1.NotFoundResponse(err.message).send(res);
            case ErrorType.TOKEN_EXPIRED:
            case ErrorType.BAD_TOKEN:
            case ErrorType.UNAUTHORIZED:
                return new ApiResponse_1.AuthFailureResponse(err.message).send(res);
            case ErrorType.RATE_LIMIT:
                return new ApiResponse_1.RateLimitResponse(err.message).send(res);
            // do not send failure message in production as it may send sensitive data
            default: {
                let message = err.message;
                if (config_1.environment === "production")
                    message = "something went wrong";
                return new ApiResponse_1.InternalErrorResponse(message).send(res);
            }
        }
    }
}
exports.ApiError = ApiError;
class InternalError extends ApiError {
    constructor(message = "Internal Error") {
        super(ErrorType.INTERNAL, message);
    }
}
exports.InternalError = InternalError;
class BadRequestError extends ApiError {
    constructor(message = "Bad Request Error") {
        super(ErrorType.BAD_REQUEST, message);
    }
}
exports.BadRequestError = BadRequestError;
class RateLimitError extends ApiError {
    constructor(message = "Rate Limit Error") {
        super(ErrorType.RATE_LIMIT, message);
    }
}
exports.RateLimitError = RateLimitError;
class AuthFailureError extends ApiError {
    constructor(message = "invalid credentials") {
        super(ErrorType.UNAUTHORIZED, message);
    }
}
exports.AuthFailureError = AuthFailureError;
class BadTokenError extends ApiError {
    constructor(message = "Bad Token Error") {
        super(ErrorType.BAD_TOKEN, message);
    }
}
exports.BadTokenError = BadTokenError;
class TokenExpiredError extends ApiError {
    constructor(message = "Token Expired Error") {
        super(ErrorType.TOKEN_EXPIRED, message);
    }
}
exports.TokenExpiredError = TokenExpiredError;
class NoDataError extends ApiError {
    constructor(message = "No Data Error") {
        super(ErrorType.NO_DATA, message);
    }
}
exports.NoDataError = NoDataError;
class NotFoundError extends ApiError {
    constructor(message = "Not Found") {
        super(ErrorType.NOT_FOUND, message);
    }
}
exports.NotFoundError = NotFoundError;
class AccessTokenError extends ApiError {
    constructor(message = "Access Token Error") {
        super(ErrorType.ACCESS_TOKEN, message);
    }
}
exports.AccessTokenError = AccessTokenError;
//# sourceMappingURL=ApiError.js.map