@echo off
cd /d "%~dp0"
title HSR Character Counter
color 0f
echo Starting...
Powershell.exe -ExecutionPolicy Bypass -File "HSR_GachaScript.ps1"
pause