@echo off
title Remove Flutter Chat App Firewall Rules
color 0C

echo =============================================
echo   🗑️  Remove Firewall Rules
echo =============================================
echo.
echo This will remove firewall rules for:
echo   📱 Port 3000 (Frontend)
echo   🔧 Port 5000 (Backend)
echo.

REM Check for administrator privileges
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo ❌ This script requires Administrator privileges
    echo 💡 Right-click and select "Run as administrator"
    pause
    exit /b 1
)

echo ✅ Running with Administrator privileges
echo.

echo 🗑️ Removing firewall rules...

REM Remove the rules
netsh advfirewall firewall delete rule name="Flutter Chat App - Frontend (Port 3000)"
netsh advfirewall firewall delete rule name="Flutter Chat App - Backend (Port 5000)"
netsh advfirewall firewall delete rule name="Flutter Chat App - Frontend OUT (Port 3000)"
netsh advfirewall firewall delete rule name="Flutter Chat App - Backend OUT (Port 5000)"

echo.
echo ✅ Firewall rules removed
echo.

pause