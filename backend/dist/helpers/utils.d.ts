import User from "../database/model/User";
export declare function filterUserData(user: User): Promise<Pick<User, "_id" | "username" | "avatarUrl" | "bio" | "statusMessage" | "lastSeen" | "roles">>;
export declare const getStaticFilePath: (fileName: string) => string;
export declare const getLocalFilePath: (fileName: string) => string;
export declare const removeLocalFile: (path: string) => void;
