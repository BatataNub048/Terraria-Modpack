@echo off
cd /d "%~dp0"
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0Servidor-Local.ps1" -Modo Servidor %*
if errorlevel 1 pause
