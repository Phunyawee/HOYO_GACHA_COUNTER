@echo off
cd /d "%~dp0"
start "" PowerShell -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File "App.ps1"