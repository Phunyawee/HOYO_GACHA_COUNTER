@echo off
cd /d "%~dp0"
title Genshin Wish Viewer
color 0f
echo Starting...

:: บรรทัดนี้คือหัวใจสำคัญ: -NoExit จะสั่งให้หน้าต่างไม่ปิด ไม่ว่าจะเกิดอะไรขึ้น
PowerShell -NoExit -ExecutionPolicy Bypass -File "GachaScript.ps1"

pause