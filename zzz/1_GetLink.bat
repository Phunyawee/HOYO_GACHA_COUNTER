@echo off
cd /d "%~dp0"
Powershell.exe -ExecutionPolicy Bypass -File "GetZZZLink.ps1"
pause