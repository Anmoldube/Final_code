@echo off
title Network Connectivity Test
color 0B

echo =============================================
echo   🌐 Network Connectivity Test
echo =============================================
echo.

echo 📡 Your Network Configuration:
echo.

REM Show IP configuration
echo 🔍 IP Configuration:
ipconfig | findstr /i "IPv4"
echo.

REM Show your specific IP
echo 🎯 Your LAN IP: 192.168.1.6
echo.

REM Test if ports are available
echo 🔌 Testing Port Availability:
echo.

REM Check if ports are in use
netstat -an | findstr :3000 >nul
if %errorlevel% equ 0 (
    echo ✅ Port 3000: IN USE (Frontend running)
) else (
    echo ⚪ Port 3000: AVAILABLE
)

netstat -an | findstr :5000 >nul
if %errorlevel% equ 0 (
    echo ✅ Port 5000: IN USE (Backend running)
) else (
    echo ⚪ Port 5000: AVAILABLE
)

echo.
echo 🔥 Firewall Status:
echo.

REM Check firewall rules (requires admin, so we'll just show the command)
echo 💡 To check firewall rules, run as Administrator:
echo    netsh advfirewall firewall show rule name="Flutter Chat App - Frontend (Port 3000)"
echo    netsh advfirewall firewall show rule name="Flutter Chat App - Backend (Port 5000)"

echo.
echo =============================================
echo   📱 Access URLs for Testing
echo =============================================
echo.
echo 🏠 Local Access:
echo    Frontend: http://localhost:3000
echo    Backend:  http://localhost:5000
echo.
echo 🌐 LAN Access (Share with others):
echo    Frontend: http://192.168.1.6:3000
echo    Backend:  http://192.168.1.6:5000
echo.
echo 📋 Test Instructions:
echo    1. Start servers using start_lan_complete.bat
echo    2. Configure firewall using configure_firewall.bat
echo    3. Share http://192.168.1.6:3000 with team members
echo    4. Ensure all devices are on same WiFi/LAN
echo.

pause