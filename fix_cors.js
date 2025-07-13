const fs = require("fs");
const path = require("path");

// Read the app.ts file
const appTsPath = path.join(__dirname, "backend", "src", "app.ts");
let content = fs.readFileSync(appTsPath, "utf8");

// Replace all occurrences of the old IP pattern
content = content.replace(/14\.139\.232\.148/g, "192.168.1.6");

// Also add port 3000 to the allowed origins arrays
content = content.replace(
  /"http:\/\/localhost:8080",/g,
  '"http://localhost:8080",\n        "http://localhost:3000",'
);

content = content.replace(
  /"http:\/\/10\.130\.226\.193:8080",/g,
  '"http://192.168.1.6:8080",\n        "http://192.168.1.6:3000",'
);

// Make the LAN access pattern more flexible
content = content.replace(
  /origin\.match\(\/\^http:\\\/\\\/10\\\.130\\\.226\\\.193:\\d\+\$\/\)/g,
  "origin.match(/^http:\\/\\/10\\.130\\.226\\.\\d+:\\d+$/)"
);

// Write the file back
fs.writeFileSync(appTsPath, content);

console.log("✅ CORS configuration updated successfully!");
console.log("📝 Changes made:");
console.log("  - Updated IP address from 192.168.1.6 to 192.168.1.6");
console.log("  - Added port 3000 to allowed origins");
console.log("  - Made LAN access pattern more flexible");
