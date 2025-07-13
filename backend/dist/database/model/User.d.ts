import { Types } from "mongoose";
import Role from "./Role";
export declare const DOCUMENT_NAME = "User";
export default interface User {
    _id: Types.ObjectId;
    username: string;
    email: string;
    password: string;
    avatarUrl?: string;
    bio?: string;
    status?: boolean;
    statusMessage?: string;
    lastSeen?: Date;
    roles: Role[];
    publicKey?: string;
    keyGeneratedAt?: Date;
    keyVersion?: number;
    createdAt?: Date;
    updatedAt?: Date;
}
export declare const UserModel: import("mongoose").Model<User, {}, {}, {}, import("mongoose").Document<unknown, {}, User, {}> & User & Required<{
    _id: Types.ObjectId;
}> & {
    __v: number;
}, any>;
