@echo off
echo ================================================
echo          SYSTEM TIME FIX SCRIPT
echo ================================================
echo.
echo Current system time:
powershell -Command "Get-Date"
echo.
echo This script will fix your system time from 2025 to 2024
echo.
echo IMPORTANT: 
echo 1. Right-click this file and select "Run as administrator"
echo 2. Or manually change time in Windows Settings
echo.
pause

echo Setting correct date and time...
echo Please enter the correct date (format: MM-DD-YYYY)
set /p correctDate=Enter date (e.g., 12-12-2024): 

echo Please enter the correct time (format: HH:MM:SS)
set /p correctTime=Enter time (e.g., 15:30:00): 

echo.
echo Setting date to: %correctDate%
date %correctDate%

echo Setting time to: %correctTime%  
time %correctTime%

echo.
echo Verifying new system time:
powershell -Command "Get-Date"

echo.
echo ================================================
echo Time fix completed! 
echo Now restart your Node.js server.
echo ================================================
pause