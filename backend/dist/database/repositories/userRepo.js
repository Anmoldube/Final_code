"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const User_1 = require("../model/User");
const Role_1 = require("../model/Role");
const ApiError_1 = require("../../core/ApiError");
class UserRepo {
    // search for existing users
    exists = async (id) => {
        const user = await User_1.UserModel.exists({ _id: id, status: true });
        return user !== null;
    };
    // find profile by id
    findById = (id) => {
        return User_1.UserModel.findOne(id)
            .populate({
            path: "roles",
            match: { status: true },
            select: { code: 1 },
        })
            .lean();
    };
    // find profile by username
    findByUsername = (username) => {
        return User_1.UserModel.findOne({ username: username })
            .populate({
            path: "roles",
            match: { status: true },
            select: { code: 1 },
        })
            .lean();
    };
    // find profile by email
    findByEmail = (email) => {
        return User_1.UserModel.findOne({ email: email })
            .populate({
            path: "roles",
            match: { status: true },
            select: { code: 1 },
        })
            .lean();
    };
    // find profile by email or username
    findByEmailOrUsername = (id) => {
        // temp
        const user = User_1.UserModel.findOne({
            $or: [{ email: id }, { username: id }],
        })
            .select("+password")
            .populate({
            path: "roles",
            match: { status: true },
            select: { code: 1, _id: 0 },
        })
            .lean()
            .exec();
        return user;
    };
    // fetch only selective fields by id
    findFieldsById = (id, ...fields) => {
        return User_1.UserModel.findOne({ _id: id, status: true })
            .select(fields.join(" "))
            .lean();
    };
    // create a new user with their keystore
    create = async (user, roleCode) => {
        const role = await Role_1.RoleModel.findOne({ code: roleCode })
            .select("+code")
            .lean();
        if (!role)
            throw new ApiError_1.InternalError("role must be specified");
        user.roles = [role];
        const createdUser = await User_1.UserModel.create(user);
        return createdUser.toObject();
    };
    // update user profile
    update = async (user, accessTokenKey, refreshTokenKey) => {
        user.updatedAt = new Date();
        await User_1.UserModel.findByIdAndUpdate(user._id, { $set: { ...user } }, { new: true }).lean();
        return { user };
    };
    // update user info only
    updateInfo = (user) => {
        user.updatedAt = new Date();
        return User_1.UserModel.findByIdAndUpdate(user._id, { $set: { ...user } }, { new: true }).lean();
    };
    // search available users
    searchAvailableUsers = (currentUser, searchTermUsernameOrEmail) => {
        return User_1.UserModel.aggregate([
            {
                $match: {
                    _id: {
                        $ne: currentUser._id, // skip the logged in user
                    },
                    status: true,
                    $or: [
                        { username: { $regex: searchTermUsernameOrEmail, $options: "i" } },
                        { email: { $regex: searchTermUsernameOrEmail, $options: "i" } },
                        { bio: { $regex: searchTermUsernameOrEmail, $options: "i" } }, // Also search in bio
                    ],
                },
            },
            {
                $project: {
                    avatarUrl: 1,
                    username: 1,
                    email: 1,
                    bio: 1, // Include bio in results
                },
            },
            {
                $sort: { username: 1 } // Sort alphabetically by username
            },
            {
                $limit: 50 // Limit results for better performance
            }
        ]);
    };
    // get all users except the current user
    getAllUsers = (currentUser) => {
        return User_1.UserModel.aggregate([
            {
                $match: {
                    _id: {
                        $ne: currentUser._id, // skip the logged in user
                    },
                    status: true,
                },
            },
            {
                $project: {
                    avatarUrl: 1,
                    username: 1,
                    email: 1,
                    bio: 1, // Include bio for more user information
                },
            },
            {
                $sort: { username: 1 } // Sort alphabetically by username
            },
            {
                $limit: 100 // Limit results for better performance in LAN environments
            }
        ]);
    };
    // Find user by ID and update with new data
    findByIdAndUpdate = async (id, updateData) => {
        updateData.updatedAt = new Date();
        return User_1.UserModel.findByIdAndUpdate(id, { $set: updateData }, { new: true })
            .populate({
            path: "roles",
            match: { status: true },
            select: { code: 1 },
        })
            .lean();
    };
    // Get user by ID with public key
    async getUserById(id) {
        return User_1.UserModel.findById(id)
            .select('+publicKey +keyVersion +keyGeneratedAt')
            .lean()
            .exec();
    }
    // Get multiple users by IDs with public keys
    async getUsersByIds(ids) {
        return User_1.UserModel.find({ _id: { $in: ids } })
            .select('username email publicKey keyVersion keyGeneratedAt')
            .lean()
            .exec();
    }
    // Update user by ID
    async updateUserById(id, updateData) {
        return User_1.UserModel.findByIdAndUpdate(id, { ...updateData, updatedAt: new Date() }, { new: true, runValidators: true })
            .select('+publicKey +keyVersion +keyGeneratedAt')
            .lean()
            .exec();
    }
    // Check if user has E2EE set up
    async hasE2EESetup(id) {
        const user = await User_1.UserModel.findById(id)
            .select('publicKey')
            .lean()
            .exec();
        return !!(user && user.publicKey);
    }
    // Get users with E2EE capability in a chat
    async getUsersWithE2EEInChat(chatId) {
        // This would need to be implemented based on your chat participants logic
        // For now, returning a placeholder
        return [];
    }
}
exports.default = new UserRepo();
//# sourceMappingURL=userRepo.js.map