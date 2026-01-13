@echo off
cd /d "%~dp0"
Powershell.exe -ExecutionPolicy Bypass -File "GetHSRLink.ps1"
pause