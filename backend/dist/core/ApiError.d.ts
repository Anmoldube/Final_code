import { Response } from "express";
export declare enum ErrorType {
    BAD_TOKEN = "BadTokenError",
    TOKEN_EXPIRED = "TokenExpiredError",
    UNAUTHORIZED = "AuthFailureError",
    ACCESS_TOKEN = "AccessTokenError",
    INTERNAL = "InternalError",
    NOT_FOUND = "NotFoundError",
    NO_ENTRY = "NoEntryError",
    NO_DATA = "NoDataError",
    BAD_REQUEST = "BadRequestError",
    RATE_LIMIT = "RateLimitError",
    FORBIDDEN = "ForbiddenError"
}
export declare abstract class ApiError extends Error {
    type: ErrorType;
    message: string;
    stack: string;
    constructor(type: ErrorType, message?: string, stack?: string);
    static handle(err: ApiError, res: Response): Response;
}
export declare class InternalError extends ApiError {
    constructor(message?: string);
}
export declare class BadRequestError extends ApiError {
    constructor(message?: string);
}
export declare class RateLimitError extends ApiError {
    constructor(message?: string);
}
export declare class AuthFailureError extends ApiError {
    constructor(message?: string);
}
export declare class BadTokenError extends ApiError {
    constructor(message?: string);
}
export declare class TokenExpiredError extends ApiError {
    constructor(message?: string);
}
export declare class NoDataError extends ApiError {
    constructor(message?: string);
}
export declare class NotFoundError extends ApiError {
    constructor(message?: string);
}
export declare class AccessTokenError extends ApiError {
    constructor(message?: string);
}
