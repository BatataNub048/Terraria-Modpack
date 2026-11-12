@echo off
setlocal DisableDelayedExpansion
if not exist "%~dp0installer.ps1" (
  echo ERROR: Extract the entire ZIP first. installer.ps1 is missing.
  pause
  exit /b 2
)
if "%~1"=="" (
  echo Modpack Terraria - revisao 7 - tModLoader 2026.9.3.1: o menu solicitara a pasta do tModLoader.
  powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%~dp0installer.ps1" -Mode Menu
) else (
  powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%~dp0installer.ps1" %*
)
set "packExit=%errorlevel%"
echo.
echo Exit code: %packExit%
if "%~1"=="" pause
exit /b %packExit%
