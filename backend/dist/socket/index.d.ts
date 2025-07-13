import User from "../database/model/User";
import { ChatEventEnum } from "../constants";
import { Request } from "express";
declare module "socket.io" {
    interface Socket {
        user?: User;
    }
}
declare const initSocketIo: (io: any) => void;
declare const emitSocketEvent: (req: Request, roomId: string, event: ChatEventEnum, payload: any) => void;
declare const emitToUser: (req: Request, userId: string, event: ChatEventEnum, payload: any) => void;
export { initSocketIo, emitSocketEvent, emitToUser };
