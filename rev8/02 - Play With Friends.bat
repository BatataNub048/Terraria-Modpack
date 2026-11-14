@echo off
setlocal
cd /d "%~dp0" || goto folder_error
set "SCRIPT=%~dp0Servidor-Amigos.ps1"
if not exist "%SCRIPT%" goto script_error
set "PS=%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe"
set "NETWORK="

echo Rev8 Friends Client - Vanity ^(72 mods^)
echo Start 01 - Start Friends Server.bat first and wait for Server started.
echo Choose the same network as the server:
echo T - Tailscale multiplayer
echo L - Local test on this PC
echo Q - Quit
choice /C TLQ /N /M "Choose T, L or Q: "
set "SELECTION=%ERRORLEVEL%"
if "%SELECTION%"=="3" exit /b 0
if "%SELECTION%"=="2" set "NETWORK=Local"
if "%SELECTION%"=="1" set "NETWORK=Tailscale"
if not defined NETWORK goto menu_error

"%PS%" -NoProfile -ExecutionPolicy Bypass -File "%SCRIPT%" -Modo Cliente -Perfil Vanity -Rede %NETWORK%
if errorlevel 1 goto run_error
echo Game session ended. The server can be stopped from its own window.
pause
exit /b 0

:folder_error
echo ERROR: Could not open the launcher's folder.
goto fail
:script_error
echo ERROR: Servidor-Amigos.ps1 must be next to this launcher.
goto fail
:menu_error
echo ERROR: No valid menu selection was received.
goto fail
:run_error
echo.
echo ERROR: The PowerShell script failed. See the message above.
echo Check that the Vanity server is ready and that both launchers use the same network.
:fail
pause
exit /b 1
