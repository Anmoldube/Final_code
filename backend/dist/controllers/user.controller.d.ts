import { Request, Response } from "express";
declare const signUp: (req: Request, res: Response, next: import("express").NextFunction) => void;
declare const login: (req: Request, res: Response, next: import("express").NextFunction) => void;
declare const logout: (req: Request, res: Response, next: import("express").NextFunction) => void;
declare const updateProfile: (req: Request, res: Response, next: import("express").NextFunction) => void;
declare const updateAvatar: (req: Request, res: Response, next: import("express").NextFunction) => void;
declare const refreshToken: (req: Request, res: Response, next: import("express").NextFunction) => void;
declare const changePassword: (req: Request, res: Response, next: import("express").NextFunction) => void;
export { signUp, login, logout, refreshToken, updateProfile, updateAvatar, changePassword };
