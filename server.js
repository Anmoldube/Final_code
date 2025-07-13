const express = require("express");
const cors = require("cors");
const path = require("path");
const fs = require("fs");
const os = require("os");

const app = express();
const PORT = process.env.PORT || 3000;

// Enable CORS for all origins
app.use(
  cors({
    origin: "*",
    methods: ["GET", "POST", "PUT", "DELETE", "OPTIONS"],
    allowedHeaders: ["Content-Type", "Authorization"],
  })
);

// Serve static files from Flutter build directory
const buildPath = path.join(__dirname, "build", "web");

// Check if build directory exists
if (!fs.existsSync(buildPath)) {
  console.error("❌ Build directory not found!");
  console.error("Please run: flutter build web");
  process.exit(1);
}

app.use(express.static(buildPath));

// Handle all routes by serving index.html (for Flutter router)
app.get("*", (req, res) => {
  res.sendFile(path.join(buildPath, "index.html"));
});

// Get local IP address
function getLocalIP() {
  const interfaces = os.networkInterfaces();
  for (const name of Object.keys(interfaces)) {
    for (const interface of interfaces[name]) {
      if (interface.family === "IPv4" && !interface.internal) {
        return interface.address;
      }
    }
  }
  return "127.0.0.1";
}

app.listen(PORT, "0.0.0.0", () => {
  const localIP = getLocalIP();
  console.log("\n🚀 Flutter Web App Server Started!");
  console.log("=" * 40);
  console.log(`📱 Local access: http://localhost:${PORT}`);
  console.log(`🌐 LAN access: http://${localIP}:${PORT}`);
  console.log(`📁 Serving: ${buildPath}`);
  console.log("🔧 Press Ctrl+C to stop");
  console.log("=" * 40);
});
