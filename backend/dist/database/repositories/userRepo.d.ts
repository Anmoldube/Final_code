import { Aggregate, Types } from "mongoose";
import User from "../model/User";
declare class UserRepo {
    exists: (id: Types.ObjectId) => Promise<boolean>;
    findById: (id: Types.ObjectId) => Promise<User | null>;
    findByUsername: (username: string) => Promise<User | null>;
    findByEmail: (email: string) => Promise<User | null>;
    findByEmailOrUsername: (id: string) => Promise<User | null>;
    findFieldsById: (id: Types.ObjectId, ...fields: string[]) => Promise<User | null>;
    create: (user: User, roleCode: string) => Promise<User>;
    update: (user: User, accessTokenKey: string, refreshTokenKey: string) => Promise<{
        user: User;
    }>;
    updateInfo: (user: User) => Promise<any>;
    searchAvailableUsers: (currentUser: User, searchTermUsernameOrEmail: string) => Aggregate<any>;
    getAllUsers: (currentUser: User) => Aggregate<any>;
    findByIdAndUpdate: (id: Types.ObjectId, updateData: Partial<User>) => Promise<User | null>;
    getUserById(id: Types.ObjectId): Promise<User | null>;
    getUsersByIds(ids: Types.ObjectId[]): Promise<User[]>;
    updateUserById(id: Types.ObjectId, updateData: Partial<User>): Promise<User | null>;
    hasE2EESetup(id: Types.ObjectId): Promise<boolean>;
    getUsersWithE2EEInChat(chatId: Types.ObjectId): Promise<User[]>;
}
declare const _default: UserRepo;
export default _default;
