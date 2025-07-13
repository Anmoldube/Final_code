import { Types } from "mongoose";
export declare const DOCUMENT_NAME = "Role";
export declare enum RoleCode {
    ADMIN = "ADMIN",
    USER = "USER"
}
export default interface Role {
    _id: Types.ObjectId;
    code: string;
    status?: boolean;
    createdAt?: Date;
    updatedAt?: Date;
}
export declare const RoleModel: import("mongoose").Model<Role, {}, {}, {}, import("mongoose").Document<unknown, {}, Role, {}> & Role & Required<{
    _id: Types.ObjectId;
}> & {
    __v: number;
}, any>;
