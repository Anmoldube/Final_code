@echo off
title Flutter Chat App - LAN Server
color 0A

echo =============================================
echo   🚀 Flutter Chat App - LAN Setup
echo =============================================
echo.
echo Your LAN IP: 192.168.1.6
echo.
echo This will start:
echo   📱 Frontend (Flutter Web): http://192.168.1.6:3000
echo   🔧 Backend API Server: http://192.168.1.6:5000
echo.
echo =============================================

REM Check if Node.js is installed
node --version >nul 2>&1
if %errorlevel% neq 0 (
    echo ❌ Node.js is not installed or not in PATH
    echo Please install Node.js from https://nodejs.org/
    pause
    exit /b 1
)

REM Check if Flutter is installed
flutter --version >nul 2>&1
if %errorlevel% neq 0 (
    echo ❌ Flutter is not installed or not in PATH
    echo Please install Flutter from https://flutter.dev/
    pause
    exit /b 1
)

echo ✅ Prerequisites check passed
echo.

REM Step 1: Install frontend dependencies
echo 📦 Installing frontend dependencies...
call npm install
if %errorlevel% neq 0 (
    echo ❌ Frontend npm install failed!
    pause
    exit /b 1
)

REM Step 2: Install backend dependencies
echo 📦 Installing backend dependencies...
cd backend
call npm install
if %errorlevel% neq 0 (
    echo ❌ Backend npm install failed!
    pause
    exit /b 1
)
cd ..

REM Step 3: Build Flutter web app
echo 🔨 Building Flutter web app...
call flutter build web
if %errorlevel% neq 0 (
    echo ❌ Flutter build failed!
    pause
    exit /b 1
)

echo.
echo ✅ Build completed successfully!
echo.
echo 🚀 Starting servers...
echo.

REM Step 4: Start backend server in background
echo Starting backend server...
cd backend
start "Backend Server" cmd /k "npm run dev"
cd ..

REM Wait a moment for backend to start
timeout /t 3 /nobreak >nul

REM Step 5: Start frontend server
echo Starting frontend server...
start "Frontend Server" cmd /k "npm start"

echo.
echo =============================================
echo   🎉 Servers Started Successfully!
echo =============================================
echo.
echo 📱 Frontend URL: http://192.168.1.6:3000
echo 🔧 Backend URL:  http://192.168.1.6:5000
echo.
echo 🌐 Share these URLs with other users on your LAN
echo 📱 They can access the app using: http://192.168.1.6:3000
echo.
echo ⚠️  Make sure Windows Firewall allows these ports
echo 💡 To stop servers, close the opened command windows
echo.
echo =============================================

pause