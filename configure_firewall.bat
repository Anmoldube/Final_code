@echo off
title Configure Windows Firewall for LAN Access
color 0E

echo =============================================
echo   🔥 Windows Firewall Configuration
echo =============================================
echo.
echo This will add firewall rules to allow:
echo   📱 Port 3000 (Frontend)
echo   🔧 Port 5000 (Backend)
echo.
echo ⚠️  This requires Administrator privileges
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

echo 🔥 Adding firewall rules...

REM Add inbound rules for ports 3000 and 5000
netsh advfirewall firewall add rule name="Flutter Chat App - Frontend (Port 3000)" dir=in action=allow protocol=TCP localport=3000
if %errorlevel% equ 0 (
    echo ✅ Frontend port 3000 rule added
) else (
    echo ❌ Failed to add frontend port rule
)

netsh advfirewall firewall add rule name="Flutter Chat App - Backend (Port 5000)" dir=in action=allow protocol=TCP localport=5000
if %errorlevel% equ 0 (
    echo ✅ Backend port 5000 rule added
) else (
    echo ❌ Failed to add backend port rule
)

REM Add outbound rules (usually not needed but good practice)
netsh advfirewall firewall add rule name="Flutter Chat App - Frontend OUT (Port 3000)" dir=out action=allow protocol=TCP localport=3000
netsh advfirewall firewall add rule name="Flutter Chat App - Backend OUT (Port 5000)" dir=out action=allow protocol=TCP localport=5000

echo.
echo =============================================
echo   🎉 Firewall Configuration Complete!
echo =============================================
echo.
echo ✅ Port 3000 (Frontend) - Allowed
echo ✅ Port 5000 (Backend) - Allowed
echo.
echo 🌐 Other devices on your LAN can now access:
echo    http://192.168.1.6:3000
echo.
echo 💡 To remove these rules later, run:
echo    remove_firewall_rules.bat
echo.

pause