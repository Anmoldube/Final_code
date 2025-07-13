import { Request, Response, NextFunction } from "express";
declare const validate: (req: Request, res: Response, next: NextFunction) => void;
export { validate };
