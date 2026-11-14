@echo off
setlocal
cd /d "%~dp0" || goto failed
if not exist "%~dp0Multiplayer-Menu.ps1" goto failed
"%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe" -NoProfile -ExecutionPolicy Bypass -File "%~dp0Multiplayer-Menu.ps1"
if errorlevel 1 goto failed
exit /b 0

:failed
echo.
echo The launcher could not start. Keep all Rev8 files together and read the error above.
pause
exit /b 1
