# 🌐 Flutter Chat App - LAN Setup Guide

## 📋 Overview

This guide will help you set up the Flutter Chat App to run on your local network (LAN) so other users can access and test it from their devices.

**Your LAN IP:** `192.168.1.6`
**Frontend URL:** `http://192.168.1.6:3000`
**Backend URL:** `http://192.168.1.6:5000`

## 🚀 Quick Start

### Option 1: Complete Setup (First Time)

```bash
# Run this for first-time setup or after code changes
start_lan_complete.bat
```

### Option 2: Quick Start (Already Built)

```bash
# Run this if you've already built the app
start_lan_quick.bat
```

## 🔥 Firewall Configuration

### Allow LAN Access

```bash
# Run as Administrator
configure_firewall.bat
```

### Remove Firewall Rules (Optional)

```bash
# Run as Administrator
remove_firewall_rules.bat
```

## 📱 Access URLs

### For Users on Your LAN:

- **Main App:** http://192.168.1.6:3000
- **API Endpoint:** http://192.168.1.6:5000

### For Local Development:

- **Main App:** http://localhost:3000
- **API Endpoint:** http://localhost:5000

## 🛠️ Manual Setup Steps

### 1. Prerequisites

- Node.js (v16 or higher)
- Flutter SDK
- MongoDB (running locally)

### 2. Install Dependencies

```bash
# Frontend dependencies
npm install

# Backend dependencies
cd backend
npm install
cd ..
```

### 3. Build Flutter Web App

```bash
flutter build web
```

### 4. Start Backend Server

```bash
cd backend
npm run dev
```

### 5. Start Frontend Server

```bash
npm start
```

## 🔧 Configuration Details

### Backend Configuration

- **Port:** 5000
- **Host:** 0.0.0.0 (all interfaces)
- **CORS:** Configured for LAN access
- **Database:** MongoDB on localhost:27017

### Frontend Configuration

- **Port:** 3000
- **Host:** 0.0.0.0 (all interfaces)
- **API Base URL:** http://192.168.1.6:5000

## 🌐 Network Requirements

### Firewall Ports

- **Port 3000:** Frontend server
- **Port 5000:** Backend API server
- **Port 27017:** MongoDB (if external access needed)

### Network Access

- All devices must be on the same LAN/WiFi network
- Your PC's IP address: `192.168.1.6`
- Subnet: Typically `10.1.0.x` or `192.168.x.x`

## 📱 Testing from Other Devices

### Mobile Devices (iOS/Android)

1. Connect to the same WiFi network
2. Open browser and go to: `http://192.168.1.6:3000`

### Other Computers

1. Connect to the same network
2. Open any browser and go to: `http://192.168.1.6:3000`

### Tablets

1. Connect to the same WiFi network
2. Open browser and go to: `http://192.168.1.6:3000`

## 🐛 Troubleshooting

### Can't Access from Other Devices?

1. **Check Firewall:** Run `configure_firewall.bat` as Administrator
2. **Verify Network:** Ensure all devices are on same network
3. **Test Connectivity:** Ping `192.168.1.6` from other devices
4. **Check Servers:** Ensure both frontend and backend are running

### Backend Connection Issues?

1. **MongoDB:** Ensure MongoDB is running on localhost:27017
2. **Port Conflicts:** Check if port 5000 is already in use
3. **CORS Errors:** Backend is configured for LAN access

### Frontend Build Issues?

1. **Flutter SDK:** Ensure Flutter is properly installed
2. **Dependencies:** Run `flutter pub get`
3. **Build Cache:** Try `flutter clean` then `flutter build web`

## 📊 Server Status Check

### Check if Servers are Running

```bash
# Check port 3000 (Frontend)
netstat -an | findstr :3000

# Check port 5000 (Backend)
netstat -an | findstr :5000
```

### Test API Endpoint

```bash
# Test backend health
curl http://192.168.1.6:5000/health
```

## 🔒 Security Notes

### Development Mode

- CORS is set to allow all origins (`*`)
- No HTTPS (using HTTP for simplicity)
- Firewall rules allow LAN access

### Production Considerations

- Enable HTTPS
- Restrict CORS to specific origins
- Use proper authentication
- Configure proper firewall rules

## 📞 Support

### Common Commands

```bash
# Stop all Node.js processes
taskkill /f /im node.exe

# Check Flutter version
flutter --version

# Check Node.js version
node --version

# List network interfaces
ipconfig
```

### Log Files

- Backend logs: Check the backend terminal window
- Frontend logs: Check browser developer console
- System logs: Windows Event Viewer

## 🎯 Success Indicators

### ✅ Everything Working When:

1. Backend server shows: "server running on port 5000"
2. Frontend server shows: "LAN access: http://192.168.1.6:3000"
3. Other devices can load the app at `http://192.168.1.6:3000`
4. Chat functionality works between devices
5. Real-time messaging works via WebSocket

---

**Happy Testing! 🎉**

Share the URL `http://192.168.1.6:3000` with your team members for testing.
