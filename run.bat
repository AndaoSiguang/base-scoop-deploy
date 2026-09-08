@echo off
setlocal
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0deploy_base_scoop.ps1"
set "exitCode=%ERRORLEVEL%"
pause
exit /b %exitCode%