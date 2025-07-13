"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.changePassword = exports.updateAvatar = exports.updateProfile = exports.refreshToken = exports.logout = exports.login = exports.signUp = void 0;
const asyncHandler_1 = __importDefault(require("../helpers/asyncHandler"));
const userRepo_1 = __importDefault(require("../database/repositories/userRepo"));
const ApiError_1 = require("../core/ApiError");
const Role_1 = require("../database/model/Role");
const bcrypt_1 = __importDefault(require("bcrypt"));
const authUtils_1 = require("./auth/authUtils");
const utils_1 = require("../helpers/utils");
const ApiResponse_1 = require("../core/ApiResponse");
const config_1 = require("../config");
const multer_1 = require("../helpers/multer");
const fs_1 = __importDefault(require("fs"));
const path_1 = __importDefault(require("path"));
const JWT_1 = __importDefault(require("../core/JWT"));
const defaultGroupService_1 = __importDefault(require("../services/defaultGroupService"));
const signUp = (0, asyncHandler_1.default)(async (req, res) => {
    const { email, username, password } = req.body;
    const existingUserEmail = await userRepo_1.default.findByEmail(email);
    if (existingUserEmail) {
        throw new ApiError_1.BadRequestError("email already exists");
    }
    const existingUserUsername = await userRepo_1.default.findByUsername(username);
    if (existingUserUsername) {
        throw new ApiError_1.BadRequestError("username already exists");
    }
    const hashedPassword = await bcrypt_1.default.hash(password, 10);
    // create a new user
    const user = await userRepo_1.default.create({
        username,
        email,
        password: hashedPassword,
        avatarUrl: `https://s3bucket.bytenode.xyz/staticbucketstorage/public/images/avatar${
        // random number between 0 and 40
        Math.floor(Math.random() * (40 - 1 + 1)) + 1}.avif`,
    }, Role_1.RoleCode.USER);
    const tokens = await (0, authUtils_1.createTokens)(user);
    const userData = await (0, utils_1.filterUserData)(user);
    // Add user to default group
    await defaultGroupService_1.default.addUserToDefaultGroup(user._id);
    const options = {
        httpOnly: true,
        secure: config_1.environment === "production",
        sameSite: config_1.environment === "production" ? "strict" : "lax",
        maxAge: Number(config_1.cookieValidity),
    };
    res
        .cookie("accessToken", tokens.accessToken, options)
        .cookie("refreshToken", tokens.refreshToken, options);
    new ApiResponse_1.SuccessResponse("signup successful", {
        user: userData,
        tokens,
    }).send(res);
});
exports.signUp = signUp;
const login = (0, asyncHandler_1.default)(async (req, res) => {
    const { userId, email, password } = req.body;
    if (!password)
        throw new ApiError_1.BadRequestError("Password is required");
    if (!userId && !email)
        throw new ApiError_1.BadRequestError("User ID or email is required");
    const user = await userRepo_1.default.findByEmailOrUsername(userId || email);
    if (!user)
        throw new ApiError_1.BadRequestError("Invalid email/username");
    const match = await bcrypt_1.default.compare(password, user.password);
    if (!match)
        throw new ApiError_1.AuthFailureError("Invalid credentials");
    const { password: pass, status, ...filteredUser } = user;
    const tokens = await (0, authUtils_1.createTokens)(user);
    // Add user to default group (in case they weren't added during registration)
    await defaultGroupService_1.default.addUserToDefaultGroup(user._id);
    const options = {
        httpOnly: true,
        secure: config_1.environment === "production",
        sameSite: config_1.environment === "production" ? "strict" : "lax",
        maxAge: Number(config_1.cookieValidity),
    };
    res
        .cookie("accessToken", tokens.accessToken, options)
        .cookie("refreshToken", tokens.refreshToken, options);
    new ApiResponse_1.SuccessResponse("login successful", {
        user: filteredUser,
        tokens,
    }).send(res);
});
exports.login = login;
const logout = (0, asyncHandler_1.default)(async (req, res) => {
    const options = {
        httpOnly: true,
        secure: config_1.environment === "production",
        sameSite: config_1.environment === "production" ? "strict" : "lax",
    };
    res.clearCookie("accessToken", options).clearCookie("refreshToken", options);
    new ApiResponse_1.SuccessResponse("logout successful", {}).send(res, {});
});
exports.logout = logout;
const updateProfile = (0, asyncHandler_1.default)(async (req, res) => {
    const userId = req.user._id;
    const { username, bio, statusMessage } = req.body;
    const updateData = {};
    // Only update fields that are provided
    if (username)
        updateData.username = username;
    if (bio !== undefined)
        updateData.bio = bio;
    if (statusMessage !== undefined)
        updateData.statusMessage = statusMessage;
    // Update lastSeen timestamp
    updateData.lastSeen = new Date();
    // Check if username already exists (if changing username)
    if (username) {
        const existingUser = await userRepo_1.default.findByUsername(username);
        if (existingUser && existingUser._id.toString() !== userId.toString()) {
            throw new ApiError_1.BadRequestError('Username already taken');
        }
    }
    // Update user
    const updatedUser = await userRepo_1.default.findByIdAndUpdate(userId, updateData);
    if (!updatedUser)
        throw new ApiError_1.NotFoundError('User not found');
    // Return updated user data
    const userData = await (0, utils_1.filterUserData)(updatedUser);
    // Add the status message to the response
    if (statusMessage !== undefined) {
        userData.statusMessage = statusMessage;
    }
    new ApiResponse_1.SuccessResponse('Profile updated successfully', { user: userData }).send(res);
});
exports.updateProfile = updateProfile;
const updateAvatar = (0, asyncHandler_1.default)(async (req, res) => {
    const userId = req.user._id;
    console.log("Update avatar request received", { userId, file: req.file });
    // Check if file was uploaded
    if (!req.file) {
        throw new ApiError_1.BadRequestError('No image file provided');
    }
    // Get the file path and create a URL
    const avatarUrl = (0, multer_1.getFileUrl)(req.file.filename, 'avatar');
    console.log("Generated avatar URL:", avatarUrl);
    // Get the current user to check if they have an existing avatar
    const currentUser = await userRepo_1.default.findById(userId);
    if (!currentUser)
        throw new ApiError_1.NotFoundError('User not found');
    // If user has an existing avatar that's not the default, delete it
    if (currentUser.avatarUrl && !currentUser.avatarUrl.includes('s3bucket.bytenode.xyz')) {
        try {
            // Extract filename from URL
            const urlParts = currentUser.avatarUrl.split('/');
            const oldFilename = urlParts[urlParts.length - 1];
            // Remove any query parameters
            const cleanFilename = oldFilename.split('?')[0];
            const oldFilePath = path_1.default.join(__dirname, '../../public/uploads/avatars', cleanFilename);
            console.log("Attempting to delete old avatar:", oldFilePath);
            // Check if file exists before attempting to delete
            if (fs_1.default.existsSync(oldFilePath)) {
                fs_1.default.unlinkSync(oldFilePath);
                console.log("Old avatar deleted successfully");
            }
            else {
                console.log("Old avatar file not found, skipping deletion");
            }
        }
        catch (error) {
            console.error('Error deleting old avatar:', error);
            // Continue even if deletion fails
        }
    }
    // Update user with new avatar URL
    console.log("Updating user with new avatar URL:", avatarUrl);
    const updatedUser = await userRepo_1.default.findByIdAndUpdate(userId, { avatarUrl });
    if (!updatedUser)
        throw new ApiError_1.NotFoundError('User not found');
    // Return updated user data with the new avatar URL
    const userData = await (0, utils_1.filterUserData)(updatedUser);
    // Add the avatar URL directly to the response
    userData.avatarUrl = avatarUrl;
    console.log("Avatar updated successfully for user:", userId);
    new ApiResponse_1.SuccessResponse('Avatar updated successfully', {
        user: userData,
        avatarUrl
    }).send(res);
});
exports.updateAvatar = updateAvatar;
// Refresh token endpoint
const refreshToken = (0, asyncHandler_1.default)(async (req, res) => {
    // Get refresh token from request body or cookies
    let refreshTokenValue = req.body.refreshToken || req.cookies.refreshToken;
    if (!refreshTokenValue) {
        throw new ApiError_1.AuthFailureError("No token provided");
    }
    try {
        // Verify the refresh token
        const payload = await JWT_1.default.validateToken(refreshTokenValue);
        // Find the user
        const user = await userRepo_1.default.findById(new (require("mongoose").Types.ObjectId)(payload.sub));
        if (!user) {
            throw new ApiError_1.AuthFailureError("Invalid token");
        }
        // Create new tokens
        const tokens = await (0, authUtils_1.createTokens)(user);
        const userData = await (0, utils_1.filterUserData)(user);
        const options = {
            httpOnly: true,
            secure: config_1.environment === "production",
            sameSite: config_1.environment === "production" ? "strict" : "lax",
            maxAge: Number(config_1.cookieValidity),
        };
        res
            .cookie("accessToken", tokens.accessToken, options)
            .cookie("refreshToken", tokens.refreshToken, options);
        new ApiResponse_1.SuccessResponse("Token refreshed successfully", {
            user: userData,
            tokens: {
                accessToken: tokens.accessToken,
                refreshToken: tokens.refreshToken,
            },
        }).send(res);
    }
    catch (error) {
        throw new ApiError_1.AuthFailureError("Invalid or expired refresh token");
    }
});
exports.refreshToken = refreshToken;
const changePassword = (0, asyncHandler_1.default)(async (req, res) => {
    const userId = req.user._id;
    const { currentPassword, newPassword } = req.body;
    if (!currentPassword || !newPassword) {
        throw new ApiError_1.BadRequestError("Both current and new passwords are required");
    }
    if (newPassword.length < 6) {
        throw new ApiError_1.BadRequestError("New password must be at least 6 characters long");
    }
    // Get current user
    const user = await userRepo_1.default.findById(userId);
    if (!user) {
        throw new ApiError_1.NotFoundError("User not found");
    }
    // Verify current password
    const isCurrentPasswordValid = await bcrypt_1.default.compare(currentPassword, user.password);
    if (!isCurrentPasswordValid) {
        throw new ApiError_1.BadRequestError("Current password is incorrect");
    }
    // Hash new password
    const hashedNewPassword = await bcrypt_1.default.hash(newPassword, 10);
    // Update password
    await userRepo_1.default.findByIdAndUpdate(userId, { password: hashedNewPassword });
    new ApiResponse_1.SuccessResponse("Password changed successfully", {}).send(res);
});
exports.changePassword = changePassword;
//# sourceMappingURL=user.controller.js.map