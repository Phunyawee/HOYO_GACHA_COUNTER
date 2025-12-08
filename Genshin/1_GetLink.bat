@echo off
cd /d "%~dp0"
Powershell.exe -ExecutionPolicy Bypass -File "GetGenshinLink.ps1"
pause