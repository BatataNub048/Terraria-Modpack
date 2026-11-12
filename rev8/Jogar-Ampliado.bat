@echo off
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0Executar-Perfil.ps1" -Perfil Ampliado -Modo Cliente
if errorlevel 1 pause
