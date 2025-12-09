@echo off
cd /d "%~dp0"
title HSR Timeline Viewer
color 0f
echo Starting...
Powershell.exe -ExecutionPolicy Bypass -File "HSR_GachaScriptALL.ps1"
pause