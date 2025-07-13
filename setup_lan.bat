@echo off
echo =============================================
echo   Flutter Web App LAN Setup
echo =============================================
echo.

echo Step 1: Building Flutter Web App...
call flutter build web
if %errorlevel% neq 0 (
    echo ❌ Flutter build failed!
    pause
    exit /b 1
)

echo.
echo Step 2: Installing Node.js dependencies...
call npm install
if %errorlevel% neq 0 (
    echo ❌ npm install failed!
    echo Falling back to Python server...
    goto :python_server
)

echo.
echo Step 3: Starting Node.js server...
call npm start
goto :end

:python_server
echo.
echo Starting Python server...
python serve_lan.py

:end
echo.
echo Server stopped.
pause