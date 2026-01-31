@echo off
cd /d "%~dp0"
echo Launching GUI...
:: ใส่ -NoExit เพื่อให้หน้าจอค้างไว้ถ้ามี Error
start "" PowerShell -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File "Test-LogGen.ps1"
pause