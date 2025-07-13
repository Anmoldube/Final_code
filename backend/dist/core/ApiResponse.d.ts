import { Response } from "express";
declare enum StatusCode {
    SUCCESS = "10000",
    FAILURE = "10001",
    RETRY = "10002",
    INVALID_ACCESS_TOKEN = "10003",
    RATE_LIMIT = "10004"
}
declare enum ResponseStatus {
    SUCCESS = 200,
    BAD_REQUEST = 400,
    UNAUTHORIZED = 401,
    FORBIDDEN = 403,
    NOT_FOUND = 404,
    INTERNAL_ERROR = 500,
    RATE_LIMIT = 429
}
declare abstract class ApiResponse {
    protected statusCode: StatusCode;
    protected status: ResponseStatus;
    protected message: string;
    constructor(statusCode: StatusCode, status: ResponseStatus, message: string);
    protected prepare<T extends ApiResponse>(res: Response, response: T, headers: {
        [key: string]: string;
    }): Response;
    private static sanitize;
    send(res: Response, headers?: {
        [key: string]: string;
    }): Response;
}
export declare class InternalErrorResponse extends ApiResponse {
    constructor(message: string);
}
export declare class BadRequestResponse extends ApiResponse {
    constructor(message: string);
}
export declare class RateLimitResponse extends ApiResponse {
    constructor(message: string);
}
export declare class AuthFailureResponse extends ApiResponse {
    constructor(message: string);
}
export declare class SuccessMsgResponse extends ApiResponse {
    constructor(message: string);
}
export declare class FailureMsgResponse extends ApiResponse {
    constructor(message: string);
}
export declare class SuccessResponse<T> extends ApiResponse {
    private data;
    constructor(message: string | undefined, data: T);
    send(res: Response, headers?: {
        [key: string]: string;
    }): Response;
}
export declare class AccessTokenErrorResponse extends ApiResponse {
    private instruction;
    constructor(message?: string);
    send(res: Response, headers?: {
        [key: string]: string;
    }): Response;
}
export declare class NotFoundResponse extends ApiResponse {
    constructor(message?: string);
    send(res: Response, headers?: {
        [key: string]: string;
    }): Response;
}
export {};
