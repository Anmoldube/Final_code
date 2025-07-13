import { Types } from "mongoose";
export declare class DefaultGroupService {
    private static readonly DEFAULT_GROUP_ID;
    private static readonly DEFAULT_GROUP_NAME;
    /**
     * Initialize the default group on server startup
     */
    static initializeDefaultGroup(): Promise<void>;
    /**
     * Add a user to the default group
     */
    static addUserToDefaultGroup(userId: Types.ObjectId): Promise<boolean>;
    /**
     * Get the default group
     */
    static getDefaultGroup(): Promise<any>;
    /**
     * Get the default group ID
     */
    static getDefaultGroupId(): string;
    /**
     * Get the default group name
     */
    static getDefaultGroupName(): string;
    /**
     * Check if a group is the default group
     */
    static isDefaultGroup(groupId: string | Types.ObjectId): boolean;
    /**
     * Remove a user from the default group (optional - for user deletion scenarios)
     */
    static removeUserFromDefaultGroup(userId: Types.ObjectId): Promise<boolean>;
}
export default DefaultGroupService;
