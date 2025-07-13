"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const ApiResponse_1 = require("../core/ApiResponse");
const timeUtils_1 = require("../helpers/timeUtils");
class HealthController {
    /**
     * Health check endpoint
     */
    healthCheck = async (req, res) => {
        const healthData = {
            status: "ok",
            timestamp: new Date().toISOString(),
            uptime: process.uptime(),
            serverUrl: process.env.SERVER_URL,
            clientIp: req.ip || req.connection.remoteAddress,
            message: "Server is running and accessible on LAN"
        };
        return new ApiResponse_1.SuccessResponse("Health check successful", healthData).send(res);
    };
    /**
     * File access check endpoint
     */
    fileCheck = async (req, res) => {
        const path = req.query.path || "/uploads/test.txt";
        const fileData = {
            status: "ok",
            timestamp: new Date().toISOString(),
            path: path,
            serverUrl: process.env.SERVER_URL,
            fullUrl: `${process.env.SERVER_URL}${path}`,
            message: "File access check successful"
        };
        return new ApiResponse_1.SuccessResponse("File check successful", fileData).send(res);
    };
    /**
     * Time check endpoint for debugging timestamp issues
     */
    timeCheck = async (req, res) => {
        const timeInfo = (0, timeUtils_1.getServerTimeInfo)();
        const currentDate = new Date();
        const timeData = {
            status: "ok",
            serverTime: timeInfo,
            isValidTimestamp: (0, timeUtils_1.isValidTimestamp)(currentDate),
            nodeVersion: process.version,
            platform: process.platform,
            env: {
                TZ: process.env.TZ,
                NODE_ENV: process.env.NODE_ENV,
            },
            message: "Time check completed",
            warnings: []
        };
        // Add warnings for potential issues
        if (!(0, timeUtils_1.isValidTimestamp)(currentDate)) {
            timeData.warnings.push("Server timestamp appears to be invalid (too far in future/past)");
        }
        if (currentDate.getFullYear() > 2024) {
            timeData.warnings.push(`Server year is ${currentDate.getFullYear()}, which may be incorrect`);
        }
        return new ApiResponse_1.SuccessResponse("Time check successful", timeData).send(res);
    };
}
exports.default = new HealthController();
//# sourceMappingURL=health.controller.js.map