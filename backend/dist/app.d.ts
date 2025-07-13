import "./database";
import { Server as HttpServer } from "http";
declare const httpServer: HttpServer<typeof import("http").IncomingMessage, typeof import("http").ServerResponse>;
export default httpServer;
