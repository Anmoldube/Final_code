import { Request, Response } from "express";
declare class HealthController {
    /**
     * Health check endpoint
     */
    healthCheck: (req: Request, res: Response) => Promise<Response<any, Record<string, any>>>;
    /**
     * File access check endpoint
     */
    fileCheck: (req: Request, res: Response) => Promise<Response<any, Record<string, any>>>;
    /**
     * Time check endpoint for debugging timestamp issues
     */
    timeCheck: (req: Request, res: Response) => Promise<Response<any, Record<string, any>>>;
}
declare const _default: HealthController;
export default _default;
