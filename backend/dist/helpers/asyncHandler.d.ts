import { Request, Response, NextFunction } from "express";
type AsyncFunction = (req: Request, res: Response, next: NextFunction) => Promise<any>;
declare const _default: (execution: AsyncFunction) => (req: Request, res: Response, next: NextFunction) => void;
export default _default;
