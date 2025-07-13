@echo off
title Flutter Chat App - Quick LAN Start
color 0A

echo =============================================
echo   🚀 Flutter Chat App - Quick LAN Start
echo =============================================
echo.
echo Your LAN IP: 192.168.1.6
echo.
echo Frontend: http://192.168.1.6:3000
echo Backend:  http://192.168.1.6:5000
echo.
echo ⚡ This assumes you've already built the app
echo 💡 Use start_lan_complete.bat for full setup
echo.
echo =============================================

REM Start backend server in background
echo 🔧 Starting backend server...
cd backend
start "Backend Server - Port 5000" cmd /k "npm run dev"
cd ..

REM Wait a moment for backend to start
timeout /t 2 /nobreak >nul

REM Start frontend server
echo 📱 Starting frontend server...
start "Frontend Server - Port 3000" cmd /k "npm start"

echo.
echo ✅ Servers started!
echo.
echo 📱 Users can access: http://192.168.1.6:3000
echo 🔧 Backend API at:   http://192.168.1.6:5000
echo.
echo 💡 Close the opened windows to stop servers
echo.

pause