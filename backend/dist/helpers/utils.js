"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.removeLocalFile = exports.getLocalFilePath = exports.getStaticFilePath = void 0;
exports.filterUserData = filterUserData;
const lodash_1 = __importDefault(require("lodash"));
const fs_1 = __importDefault(require("fs"));
const colorsUtils_1 = __importDefault(require("./colorsUtils"));
const config_1 = require("../config");
async function filterUserData(user) {
    const data = lodash_1.default.pick(user, ["_id", "username", "roles", "avatarUrl", "bio", "statusMessage", "lastSeen"]);
    return data;
}
const getStaticFilePath = (fileName) => {
    // Handle null or undefined filenames
    if (!fileName) {
        console.error("getStaticFilePath called with null or undefined filename");
        return `${config_1.serverUrl}/uploads/other/file-not-found`;
    }
    // Log the incoming filename for debugging
    console.log(`getStaticFilePath called with: ${fileName}`);
    // Clean up any double slashes in the path
    const cleanFileName = fileName.replace(/\/\//g, '/');
    // Extract file type from the path if it exists
    const filePathParts = cleanFileName.split('/');
    const fileType = filePathParts.length > 1 ? filePathParts[0] : getFileTypeFromName(cleanFileName);
    // If the filename already includes a path, use it directly
    if (cleanFileName.includes('/')) {
        // Make sure we don't have public/ in the URL
        const path = cleanFileName.replace(/^public\//, '');
        const url = `${config_1.serverUrl}/uploads/${path}`;
        console.log(`Generated URL (with path): ${url}`);
        return url;
    }
    // Generate URL with file type directory
    const url = `${config_1.serverUrl}/uploads/${fileType}/${cleanFileName}`;
    console.log(`Generated URL (with type): ${url}`);
    return url;
};
exports.getStaticFilePath = getStaticFilePath;
const getLocalFilePath = (fileName) => {
    // Handle null or undefined filenames
    if (!fileName) {
        console.error("getLocalFilePath called with null or undefined filename");
        return `public/uploads/other/file-not-found`;
    }
    // Log the incoming filename for debugging
    console.log(`getLocalFilePath called with: ${fileName}`);
    // Clean up any double slashes in the path
    const cleanFileName = fileName.replace(/\/\//g, '/');
    // Extract file type from the path if it exists
    const filePathParts = cleanFileName.split('/');
    const fileType = filePathParts.length > 1 ? filePathParts[0] : getFileTypeFromName(cleanFileName);
    // If the filename already includes a path, use it directly
    if (cleanFileName.includes('/')) {
        // Make sure we don't have public/ in the path twice
        const path = cleanFileName.replace(/^public\//, '');
        const localPath = `public/uploads/${path}`;
        console.log(`Generated local path (with path): ${localPath}`);
        return localPath;
    }
    // Generate local path with file type directory
    const localPath = `public/uploads/${fileType}/${cleanFileName}`;
    console.log(`Generated local path (with type): ${localPath}`);
    return localPath;
};
exports.getLocalFilePath = getLocalFilePath;
// Helper function to determine file type based on file extension
function getFileTypeFromName(fileName) {
    const extension = fileName.split('.').pop()?.toLowerCase();
    if (!extension)
        return 'other';
    const imageExtensions = ['jpg', 'jpeg', 'png', 'gif', 'webp', 'svg', 'bmp'];
    const videoExtensions = ['mp4', 'webm', 'ogg', 'mov', 'avi', 'mkv'];
    const audioExtensions = ['mp3', 'wav', 'ogg', 'aac', 'flac'];
    const documentExtensions = ['pdf', 'doc', 'docx', 'xls', 'xlsx', 'ppt', 'pptx', 'txt', 'csv'];
    if (imageExtensions.includes(extension))
        return 'images';
    if (videoExtensions.includes(extension))
        return 'videos';
    if (audioExtensions.includes(extension))
        return 'audio';
    if (documentExtensions.includes(extension))
        return 'documents';
    return 'other';
}
;
// function to remove the local attachment files from the server
const removeLocalFile = (path) => {
    fs_1.default.unlink(path, (err) => {
        if (err)
            colorsUtils_1.default.log("error", "failed to remove file - path : " + path);
        colorsUtils_1.default.log("success", "file removed path: " + path);
    });
};
exports.removeLocalFile = removeLocalFile;
//# sourceMappingURL=utils.js.map