import { Request, Response } from "express";
export declare const getAllMessages: (req: Request, res: Response, next: import("express").NextFunction) => void;
export declare const sendMessage: (req: Request, res: Response, next: import("express").NextFunction) => void;
export declare const deleteMessage: (req: Request, res: Response, next: import("express").NextFunction) => void;
export declare const markMessageAsRead: (req: Request, res: Response, next: import("express").NextFunction) => void;
export declare const markAllMessagesAsRead: (req: Request, res: Response, next: import("express").NextFunction) => void;
export declare const getUnreadMessagesCount: (req: Request, res: Response, next: import("express").NextFunction) => void;
export declare const getAllUnreadMessages: (req: Request, res: Response, next: import("express").NextFunction) => void;
