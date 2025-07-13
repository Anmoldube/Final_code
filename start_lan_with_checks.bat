@echo off
title Flutter Chat App - Complete LAN Setup with Checks
color 0A

echo =============================================
echo   🚀 Flutter Chat App - Complete Setup
echo =============================================
echo.
echo Your LAN IP: 192.168.1.6
echo Frontend: http://192.168.1.6:3000
echo Backend:  http://192.168.1.6:5000
echo.
echo =============================================

REM Step 1: Check Prerequisites
echo 📋 Step 1: Checking Prerequisites...
echo.

REM Check Node.js
node --version >nul 2>&1
if %errorlevel% neq 0 (
    echo ❌ Node.js is not installed
    echo 💡 Install from: https://nodejs.org/
    pause
    exit /b 1
) else (
    echo ✅ Node.js is installed
)

REM Check Flutter
flutter --version >nul 2>&1
if %errorlevel% neq 0 (
    echo ❌ Flutter is not installed
    echo 💡 Install from: https://flutter.dev/
    pause
    exit /b 1
) else (
    echo ✅ Flutter is installed
)

REM Check MongoDB
netstat -an | findstr :27017 >nul
if %errorlevel% neq 0 (
    echo ❌ MongoDB is not running on port 27017
    echo 💡 Start MongoDB or run: setup_mongodb.bat
    echo.
    set /p continue="Continue anyway? (y/n): "
    if /i not "%continue%"=="y" exit /b 1
) else (
    echo ✅ MongoDB is running
)

echo.

REM Step 2: Check Port Availability
echo 📡 Step 2: Checking Port Availability...
echo.

netstat -an | findstr :3000 >nul
if %errorlevel% equ 0 (
    echo ⚠️  Port 3000 is already in use
    echo 💡 Stop existing services or change port
    set /p continue="Continue anyway? (y/n): "
    if /i not "%continue%"=="y" exit /b 1
) else (
    echo ✅ Port 3000 is available
)

netstat -an | findstr :5000 >nul
if %errorlevel% equ 0 (
    echo ⚠️  Port 5000 is already in use
    echo 💡 Stop existing services or change port
    set /p continue="Continue anyway? (y/n): "
    if /i not "%continue%"=="y" exit /b 1
) else (
    echo ✅ Port 5000 is available
)

echo.

REM Step 3: Install Dependencies
echo 📦 Step 3: Installing Dependencies...
echo.

echo Installing frontend dependencies...
call npm install
if %errorlevel% neq 0 (
    echo ❌ Frontend npm install failed
    pause
    exit /b 1
)
echo ✅ Frontend dependencies installed

echo Installing backend dependencies...
cd backend
call npm install
if %errorlevel% neq 0 (
    echo ❌ Backend npm install failed
    pause
    exit /b 1
)
echo ✅ Backend dependencies installed
cd ..

echo.

REM Step 4: Build Flutter App
echo 🔨 Step 4: Building Flutter Web App...
echo.

call flutter build web
if %errorlevel% neq 0 (
    echo ❌ Flutter build failed
    pause
    exit /b 1
)
echo ✅ Flutter build completed

echo.

REM Step 5: Check Firewall (informational)
echo 🔥 Step 5: Firewall Check...
echo.
echo 💡 For LAN access, ensure Windows Firewall allows:
echo    - Port 3000 (Frontend)
echo    - Port 5000 (Backend)
echo.
echo 🔧 Run configure_firewall.bat as Administrator if needed
echo.

set /p firewall="Configure firewall now? (y/n): "
if /i "%firewall%"=="y" (
    echo Opening firewall configuration...
    start configure_firewall.bat
    echo 💡 Configure firewall in the opened window, then press any key here
    pause >nul
)

echo.

REM Step 6: Start Servers
echo 🚀 Step 6: Starting Servers...
echo.

echo Starting backend server...
cd backend
start "Backend Server - http://192.168.1.6:5000" cmd /k "echo Backend Server Starting... && npm run dev"
cd ..

echo Waiting for backend to start...
timeout /t 5 /nobreak >nul

echo Starting frontend server...
start "Frontend Server - http://192.168.1.6:3000" cmd /k "echo Frontend Server Starting... && npm start"

echo.
echo =============================================
echo   🎉 Setup Complete!
echo =============================================
echo.
echo ✅ Backend Server: http://192.168.1.6:5000
echo ✅ Frontend Server: http://192.168.1.6:3000
echo.
echo 🌐 Share with your team:
echo    http://192.168.1.6:3000
echo.
echo 📱 Test on mobile devices:
echo    1. Connect to same WiFi
echo    2. Open browser
echo    3. Go to: http://192.168.1.6:3000
echo.
echo 🔧 Troubleshooting:
echo    - Run test_network.bat to check connectivity
echo    - Check firewall settings if others can't connect
echo    - Ensure MongoDB is running for backend functionality
echo.
echo 💡 Close the server windows to stop the application
echo.

pause