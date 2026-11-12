@echo off
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0Preparar-Desempenho.ps1"
if errorlevel 1 goto error
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0Executar-Perfil.ps1" -Perfil TodosRecuperados-Titanico-Desempenho -Modo Cliente
if errorlevel 1 goto error
exit /b 0
:error
pause
exit /b 1
