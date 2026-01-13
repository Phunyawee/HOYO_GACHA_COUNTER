@echo off
cd /d "%~dp0"
title ZZZ Character Counter
color 0f
echo Starting...
Powershell.exe -ExecutionPolicy Bypass -File "ZZZ_GachaScriptALL.ps1"
REM Powershell.exe -ExecutionPolicy Bypass -File "ZZZ_GachaScriptALL_Debug.ps1"
pause