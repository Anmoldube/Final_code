"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
const app_1 = __importDefault(require("./app"));
const config_1 = require("./config");
const timestampValidationService_1 = require("./services/timestampValidationService");
// Convert port to number to ensure proper typing
const portNumber = typeof config_1.port === "string" ? parseInt(config_1.port, 10) : config_1.port;
// Run timestamp validation on startup
async function startServer() {
    try {
        // Validate timestamps before starting the server
        await timestampValidationService_1.TimestampValidationService.runStartupValidation();
        // Listen on all network interfaces
        app_1.default.listen(portNumber, "0.0.0.0", () => {
            console.log("⚙️  server running on port " + portNumber);
            console.log("📡 Server accessible locally at http://localhost:" + portNumber);
            console.log("📡 Server accessible on LAN at http://192.168.1.6:" + portNumber);
            console.log("🌐 Other devices can connect using your PC's IP address");
        });
    }
    catch (error) {
        console.error("❌ Failed to start server:", error);
        process.exit(1);
    }
}
// Start the server
startServer();
//# sourceMappingURL=server.js.map