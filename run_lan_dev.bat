@echo off
echo Starting Flutter Web App for LAN Development...
echo.
echo This will start the app in development mode with hot reload
echo Access from other devices: http://YOUR_LOCAL_IP:3000
echo.

REM Get local IP
for /f "tokens=2 delims=:" %%a in ('ipconfig ^| findstr /i "IPv4"') do (
    for /f "tokens=1" %%b in ("%%a") do (
        set LOCAL_IP=%%b
        goto :found
    )
)

:found
echo Your local IP appears to be: %LOCAL_IP%
echo.
echo Starting Flutter...

flutter run -d chrome --web-port 3000 --web-hostname localhost --web-browser-flag="--disable-web-security" --web-browser-flag="--disable-features=VizDisplayCompositor" --web-browser-flag="--user-data-dir=c:/temp/chrome_dev_session" --web-browser-flag="--allow-running-insecure-content" --web-browser-flag="--disable-site-isolation-trials"