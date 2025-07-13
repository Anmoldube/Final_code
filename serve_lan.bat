@echo off
echo Building Flutter Web App...
call flutter build web

echo.
echo Starting LAN Server...
python serve_lan.py