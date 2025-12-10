@echo off
cd /d "%~dp0"
title ZZZ Character Counter
color 0f
echo Starting...
Powershell.exe -ExecutionPolicy Bypass -File "ZZZ_GachaScript.ps1"
pause