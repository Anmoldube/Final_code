"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
const express_1 = __importDefault(require("express"));
const cors_1 = __importDefault(require("cors"));
const config_1 = require("./config");
const user_routes_1 = __importDefault(require("./routes/user.routes"));
const auth_routes_1 = __importDefault(require("./routes/auth.routes"));
const chat_routes_1 = __importDefault(require("./routes/chat.routes"));
const message_routes_1 = __importDefault(require("./routes/message.routes"));
const health_routes_1 = __importDefault(require("./routes/health.routes"));
const test_routes_1 = __importDefault(require("./routes/test.routes"));
const file_routes_1 = __importDefault(require("./routes/file.routes"));
const fileMetadata_routes_1 = __importDefault(require("./routes/fileMetadata.routes"));
require("./database"); // initialize database
const ApiError_1 = require("./core/ApiError");
const morgan_1 = __importDefault(require("morgan"));
const cookie_parser_1 = __importDefault(require("cookie-parser"));
const http_1 = require("http");
const socket_io_1 = require("socket.io");
const socket_1 = require("./socket");
const path_1 = __importDefault(require("path"));
const fs_1 = __importDefault(require("fs"));
const express_rate_limit_1 = require("express-rate-limit");
const request_ip_1 = __importDefault(require("request-ip"));
// Set timezone to UTC (consistent across all environments)
process.env.TZ = "UTC";
const app = (0, express_1.default)();
// creation of http server
const httpServer = (0, http_1.createServer)(app);
// CORS configuration helper
const corsOriginHandler = (origin, callback) => {
    // Allow requests with no origin (like mobile apps or curl requests)
    if (!origin)
        return callback(null, true);
    // Allow specific origins and any localhost port for development
    const allowedOrigins = [
        "http://192.168.1.6:5173",
        "http://192.168.1.6:8080",
        "http://192.168.1.6:3000",
        "http://localhost:5173",
        "http://localhost:8080",
        "http://localhost:3000",
        "http://localhost:3000", // Flutter web dev server
        "http://127.0.0.1:8080",
        "http://127.0.0.1:3000",
    ];
    // Allow any localhost port for Flutter web development
    const isLocalhost = origin.match(/^http:\/\/localhost:\d+$/);
    // Allow any private network IP addresses (LAN access)
    const isPrivateNetwork = origin.match(/^http:\/\/(10\.\d+\.\d+\.\d+|172\.(1[6-9]|2[0-9]|3[01])\.\d+\.\d+|192\.168\.\d+\.\d+):\d+$/);
    if (allowedOrigins.includes(origin) || isLocalhost || isPrivateNetwork) {
        return callback(null, true);
    }
    return callback(new Error("Not allowed by CORS"));
};
// Apply CORS middleware first, before any other middleware
// This ensures CORS headers are set for all responses, including error responses
app.use((0, cors_1.default)({
    origin: corsOriginHandler,
    credentials: true,
    methods: ["GET", "POST", "PUT", "DELETE", "OPTIONS"],
    allowedHeaders: ["Content-Type", "Authorization", "X-Requested-With"],
}));
// Handle OPTIONS requests explicitly for preflight
app.options("*", (0, cors_1.default)({
    origin: corsOriginHandler,
    credentials: true,
    methods: ["GET", "POST", "PUT", "DELETE", "OPTIONS"],
    allowedHeaders: ["Content-Type", "Authorization", "X-Requested-With"],
}));
// middleware to get the ip of client from the request
app.use(request_ip_1.default.mw());
// Adding a rate limiter to the server
const limiter = (0, express_rate_limit_1.rateLimit)({
    windowMs: 1 * 60 * 1000, // 1 minute
    max: 1000, // Increased limit to 1000 requests per minute
    standardHeaders: true,
    legacyHeaders: false,
    keyGenerator: (req, _) => {
        return request_ip_1.default.getClientIp(req) || ""; // Return the IP address of the client
    },
    handler: (req, res, next, options) => {
        next(new ApiError_1.RateLimitError(`You exceeded the request limit. Allowed ${options.max} requests per ${options.windowMs / 60000} minute.`));
    },
});
// Apply the rate limiter to all routes
app.use(limiter);
// express app middlewares
app.use(express_1.default.json({ limit: "16kb" }));
app.use(express_1.default.urlencoded({ extended: true, limit: "16kb" }));
app.use((0, morgan_1.default)("dev"));
app.use((0, cookie_parser_1.default)());
// HEALTH CHECK ROUTE
app.get("/health", (req, res) => {
    res.send("healthy running");
});
// Special route for handling missing avatar files
app.get("/uploads/avatars/:filename", (req, res, next) => {
    const filename = req.params.filename;
    const avatarPath = path_1.default.join(__dirname, "..", "public", "uploads", "avatars", filename);
    console.log(`Avatar request for: ${filename}`);
    console.log(`Looking at path: ${avatarPath}`);
    if (fs_1.default.existsSync(avatarPath)) {
        console.log(`Avatar found, serving: ${avatarPath}`);
        // Set proper caching headers for avatars
        res.setHeader("Cache-Control", "public, max-age=3600"); // Cache for 1 hour
        res.setHeader("ETag", require("crypto").createHash("md5").update(filename).digest("hex"));
        // If it's the default avatar (which contains an SVG data URL), serve it properly
        if (filename === "default-avatar.txt") {
            const content = fs_1.default.readFileSync(avatarPath, "utf8");
            if (content.startsWith("data:image/svg+xml;base64,")) {
                const base64Data = content.replace("data:image/svg+xml;base64,", "");
                const svgData = Buffer.from(base64Data, "base64");
                res.setHeader("Content-Type", "image/svg+xml");
                return res.send(svgData);
            }
        }
        return res.sendFile(avatarPath);
    }
    else {
        console.log(`Avatar not found, serving default`);
        const defaultAvatarPath = path_1.default.join(__dirname, "..", "public", "uploads", "avatars", "default-avatar.txt");
        if (fs_1.default.existsSync(defaultAvatarPath)) {
            // Set proper caching headers for the default avatar
            res.setHeader("Cache-Control", "public, max-age=86400"); // Cache default avatar for 24 hours
            res.setHeader("ETag", "default-avatar");
            res.header("Access-Control-Allow-Origin", req.headers.origin || ""); // Dynamic origin
            res.header("Access-Control-Allow-Credentials", "true");
            // Handle default avatar SVG data URL
            const content = fs_1.default.readFileSync(defaultAvatarPath, "utf8");
            if (content.startsWith("data:image/svg+xml;base64,")) {
                const base64Data = content.replace("data:image/svg+xml;base64,", "");
                const svgData = Buffer.from(base64Data, "base64");
                res.setHeader("Content-Type", "image/svg+xml");
                return res.send(svgData);
            }
            return res.sendFile(defaultAvatarPath);
        }
        else {
            console.log(`Default avatar not found either`);
            next(); // Continue to 404 handler
        }
    }
});
// FILE DIAGNOSTIC ROUTE
app.get("/file-check", (req, res) => {
    const filePath = req.query.path;
    if (!filePath || typeof filePath !== "string") {
        return res.status(400).json({
            error: "Missing or invalid file path parameter",
            usage: "/file-check?path=/uploads/documents/example.pdf",
        });
    }
    // Clean up the path
    const cleanPath = filePath.replace(/^\/+/, ""); // Remove leading slashes
    // Check different possible locations
    const possiblePaths = [
        path_1.default.join(__dirname, "..", "public", cleanPath),
        path_1.default.join(__dirname, "..", cleanPath),
        path_1.default.join(__dirname, "..", "public", "uploads", cleanPath),
    ];
    const results = possiblePaths.map((p) => ({
        path: p,
        exists: fs_1.default.existsSync(p),
        isFile: fs_1.default.existsSync(p) ? fs_1.default.statSync(p).isFile() : false,
        size: fs_1.default.existsSync(p) && fs_1.default.statSync(p).isFile() ? fs_1.default.statSync(p).size : null,
    }));
    // List files in the directory if the path doesn't exist
    let nearbyFiles = [];
    try {
        const dirPath = path_1.default.dirname(possiblePaths[0]);
        if (fs_1.default.existsSync(dirPath)) {
            nearbyFiles = fs_1.default.readdirSync(dirPath).slice(0, 10); // List up to 10 files
        }
    }
    catch (err) {
        console.error("Error listing directory:", err);
    }
    res.json({
        requestedPath: filePath,
        cleanPath,
        results,
        nearbyFiles,
        serverUrl: require("./config").serverUrl,
    });
});
// Routes
app.use("/auth", auth_routes_1.default); // Add auth routes at /auth path
app.use("/api/users", user_routes_1.default);
app.use("/api/chats", chat_routes_1.default);
app.use("/api/chat", chat_routes_1.default); // Alternative route for client compatibility
app.use("/api/messages", message_routes_1.default);
app.use("/api/files", file_routes_1.default);
app.use("/api/file-metadata", fileMetadata_routes_1.default);
app.use("/api/health", health_routes_1.default);
app.use("/api/test", test_routes_1.default);
// Create static routes to serve uploaded files
// Serve files from the public directory at multiple paths for compatibility
app.use("/public", express_1.default.static(path_1.default.join(__dirname, "..", "public")));
app.use("/", express_1.default.static(path_1.default.join(__dirname, "..", "public")));
// Explicitly serve the uploads directory to ensure files are accessible
app.use("/uploads", express_1.default.static(path_1.default.join(__dirname, "..", "public", "uploads"), {
    setHeaders: (res, path) => {
        // Set Cache-Control header to prevent caching issues
        res.setHeader("Cache-Control", "no-cache");
        // Log when a file is successfully served
        console.log(`Serving file: ${path}`);
    },
}));
// Serve client assets directly for development
app.use("/assets", express_1.default.static(path_1.default.join(__dirname, "..", "..", "client", "src", "assets")));
// Add a route to check if files exist and log access attempts for debugging
app.use("/uploads/*", (req, res, next) => {
    // Clean up the path to remove any leading slashes
    const cleanPath = req.path.replace(/^\/+/, "");
    // Try multiple possible file paths
    const possiblePaths = [
        path_1.default.join(__dirname, "..", "public", cleanPath),
        path_1.default.join(__dirname, "..", "public", "uploads", path_1.default.basename(cleanPath)),
        path_1.default.join(__dirname, "..", "public", req.path),
    ];
    console.log(`File access attempt: ${req.path}`);
    console.log(`Clean path: ${cleanPath}`);
    // Check all possible paths
    let fileExists = false;
    let foundPath = "";
    for (const testPath of possiblePaths) {
        console.log(`Checking path: ${testPath}`);
        if (fs_1.default.existsSync(testPath)) {
            fileExists = true;
            foundPath = testPath;
            console.log(`File found at: ${testPath}`);
            break;
        }
    }
    if (!fileExists) {
        console.error(`File not found in any location. Tried:`);
        possiblePaths.forEach((p) => console.error(`- ${p}`));
        // List files in the avatars directory for debugging
        const avatarsDir = path_1.default.join(__dirname, "..", "public", "uploads", "avatars");
        if (fs_1.default.existsSync(avatarsDir)) {
            console.log(`Files in avatars directory:`);
            fs_1.default.readdirSync(avatarsDir).forEach((file) => {
                console.log(`- ${file}`);
            });
        }
        // If the file is not found, we'll still call next() to let Express handle the 404
    }
    else {
        // If we found the file, we can optionally serve it directly
        // This is just for debugging - the static middleware should handle this normally
        // res.sendFile(foundPath);
        // return;
    }
    next();
});
// Log the static file paths for debugging
console.log("Static file paths:");
console.log("Public directory:", path_1.default.join(__dirname, "..", "public"));
console.log("Uploads directory:", path_1.default.join(__dirname, "..", "public", "uploads"));
// Create directories if they don't exist
const publicDir = path_1.default.join(__dirname, "..", "public");
const uploadsDir = path_1.default.join(publicDir, "uploads");
const dirs = [
    uploadsDir,
    path_1.default.join(uploadsDir, "images"),
    path_1.default.join(uploadsDir, "videos"),
    path_1.default.join(uploadsDir, "documents"),
    path_1.default.join(uploadsDir, "audio"),
    path_1.default.join(uploadsDir, "other"),
    path_1.default.join(uploadsDir, "avatars"),
];
// Ensure all directories exist
dirs.forEach((dir) => {
    if (!require("fs").existsSync(dir)) {
        require("fs").mkdirSync(dir, { recursive: true });
        console.log(`Created directory: ${dir}`);
    }
});
// creating a socket server
const io = new socket_io_1.Server(httpServer, {
    pingTimeout: 60000,
    pingInterval: 25000,
    cors: {
        origin: (origin, callback) => {
            // Allow requests with no origin (like mobile apps or curl requests)
            if (!origin)
                return callback(null, true);
            // Allow specific origins for LAN and localhost development
            const allowedOrigins = [
                "http://192.168.1.6:5173",
                "http://192.168.1.6:8080",
                "http://192.168.1.6:3000",
                "http://localhost:5173",
                "http://localhost:8080",
                "http://localhost:3000",
            ];
            // Allow any localhost port for Flutter web development
            const isLocalhost = origin.match(/^http:\/\/localhost:\d+$/);
            // Allow any private network IP addresses (LAN access)
            const isPrivateNetwork = origin.match(/^http:\/\/(10\.\d+\.\d+\.\d+|172\.(1[6-9]|2[0-9]|3[01])\.\d+\.\d+|192\.168\.\d+\.\d+):\d+$/);
            if (allowedOrigins.includes(origin) || isLocalhost || isPrivateNetwork) {
                return callback(null, true);
            }
            return callback(new Error("Not allowed by CORS"));
        },
        methods: ["GET", "POST", "PUT", "DELETE", "OPTIONS"],
        credentials: true,
        allowedHeaders: ["Content-Type", "Authorization", "X-Requested-With"],
    },
    allowEIO3: true,
    path: "/socket.io",
    transports: ["polling", "websocket"],
    connectTimeout: 45000,
    maxHttpBufferSize: 1e8,
});
// initialize the socket server
(0, socket_1.initSocketIo)(io);
app.set("io", io); // using set method to mount 'io' instance on app
// middleware error handlers
app.use((err, req, res, next) => {
    // Ensure CORS headers are set for error responses with dynamic origin
    const origin = req.headers.origin;
    if (origin) {
        const allowedOrigins = ["http://192.168.1.6:5173", "http://localhost:5173"];
        // Allow any localhost port for Flutter web development
        const isLocalhost = origin.match(/^http:\/\/localhost:\d+$/);
        if (allowedOrigins.includes(origin) || isLocalhost) {
            res.header("Access-Control-Allow-Origin", origin);
        }
    }
    res.header("Access-Control-Allow-Credentials", "true");
    res.header("Access-Control-Allow-Methods", "GET, POST, PUT, DELETE, OPTIONS");
    res.header("Access-Control-Allow-Headers", "Content-Type, Authorization, X-Requested-With");
    if (err instanceof ApiError_1.ApiError) {
        ApiError_1.ApiError.handle(err, res);
        if (err.type === ApiError_1.ErrorType.INTERNAL)
            console.error(`500 - ${err.message} - ${req.originalUrl} - ${req.method} - ${req.ip}` +
                "\n" +
                `Error Stack: ${err.stack}`);
    }
    else {
        console.error(`500 - ${err.message} - ${req.originalUrl} - ${req.method} - ${req.ip}` +
            "\n" +
            `Error Stack: ${err.stack}`);
        if (config_1.environment === "development") {
            return res.status(500).send(err.stack);
        }
        ApiError_1.ApiError.handle(new ApiError_1.InternalError(), res);
    }
});
exports.default = httpServer;
//# sourceMappingURL=app.js.map