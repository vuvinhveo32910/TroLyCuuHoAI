@echo off
title WebVinhNam - Gemini and MedGemma LAN
REM Use the shared API; do not start a second YOLO/PyTorch server.
powershell.exe -NoProfile -File "%~dp0Run-Server.ps1" -Lan
if errorlevel 1 pause
