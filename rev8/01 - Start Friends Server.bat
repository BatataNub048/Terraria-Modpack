@echo off
setlocal
cd /d "%~dp0" || goto folder_error
set "SCRIPT=%~dp0Servidor-Amigos.ps1"
if not exist "%SCRIPT%" goto script_error
set "PS=%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe"
set "NETWORK="

echo Rev8 Friends Server - Vanity ^(72 mods^)
echo T - Tailscale multiplayer
echo L - Local test on this PC
echo P - Prepare the Vanity copy ^(first-time setup only^)
echo Q - Quit
choice /C TLPQ /N /M "Choose T, L, P or Q: "
set "SELECTION=%ERRORLEVEL%"
if "%SELECTION%"=="4" exit /b 0
if "%SELECTION%"=="3" goto prepare
if "%SELECTION%"=="2" set "NETWORK=Local"
if "%SELECTION%"=="1" set "NETWORK=Tailscale"
if not defined NETWORK goto menu_error

echo.
echo Choose the total player limit, including the host.
choice /C 2345678 /N /T 10 /D 4 /M "Press 2-8 (default: 4 after 10 seconds): "
set "SELECTION=%ERRORLEVEL%"
if %SELECTION% LSS 1 goto menu_error
if %SELECTION% GTR 7 goto menu_error
set /a "PLAYERS=SELECTION+1" >nul
echo.
echo Starting Vanity on %NETWORK% for up to %PLAYERS% players.
echo Wait for Server started, then open 02 - Play With Friends.bat.
echo To stop the server, leave the game and type exit in this window.
"%PS%" -NoProfile -ExecutionPolicy Bypass -File "%SCRIPT%" -Modo Servidor -Perfil Vanity -Rede %NETWORK% -MaxPlayers %PLAYERS%
if errorlevel 1 goto run_error
echo Server session ended.
goto done

:prepare
echo Close all Terraria clients and servers before preparing the copy.
"%PS%" -NoProfile -ExecutionPolicy Bypass -File "%SCRIPT%" -Modo Preparar -Perfil Vanity
if errorlevel 1 goto run_error
echo Preparation complete. Reopen this launcher and choose T or L to start.
goto done

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
echo If the Vanity copy is missing, close Terraria and choose P on the next run.
goto fail
:done
pause
exit /b 0
:fail
pause
exit /b 1
