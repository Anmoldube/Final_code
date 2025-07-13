@echo off
title MongoDB Setup for Flutter Chat App
color 0D

echo =============================================
echo   🛢️  MongoDB Setup Guide
echo =============================================
echo.
echo This app requires MongoDB to be running locally
echo Database: lan_chat
echo Connection: mongodb://localhost:27017
echo.

REM Check if MongoDB is running
echo 🔍 Checking if MongoDB is running...
netstat -an | findstr :27017 >nul
if %errorlevel% equ 0 (
    echo ✅ MongoDB appears to be running on port 27017
    goto :mongodb_running
) else (
    echo ❌ MongoDB is not running on port 27017
    goto :mongodb_not_running
)

:mongodb_not_running
echo.
echo 📋 MongoDB Setup Options:
echo.
echo 1. Install MongoDB Community Server:
echo    https://www.mongodb.com/try/download/community
echo.
echo 2. Or use MongoDB Docker container:
echo    docker run -d -p 27017:27017 --name mongodb mongo:latest
echo.
echo 3. Or use MongoDB Atlas (cloud):
echo    Update backend/.env with your Atlas connection string
echo.
echo ⚠️  The app will not work without MongoDB running
goto :end

:mongodb_running
echo.
echo 🔧 Testing MongoDB connection...

REM Try to connect to MongoDB (requires mongo client)
where mongo >nul 2>&1
if %errorlevel% equ 0 (
    echo ✅ MongoDB client found, testing connection...
    echo show dbs | mongo --quiet
) else (
    echo 💡 MongoDB client not found in PATH
    echo    You can install MongoDB Compass for GUI management
)

echo.
echo 📊 Database Configuration:
echo    Database Name: lan_chat
echo    Connection URL: mongodb://localhost:27017
echo    Collections: users, chats, messages, roles
echo.
echo ✅ MongoDB setup appears correct!

:end
echo.
echo =============================================
echo   📚 Next Steps
echo =============================================
echo.
echo 1. Ensure MongoDB is running
echo 2. Run: start_lan_complete.bat
echo 3. Backend will automatically create database and collections
echo 4. Share http://192.168.1.6:3000 with your team
echo.

pause