@echo off
set RUNDIR=%~dp0

call powershell.exe -NoProfile -executionpolicy remotesigned -File "%RUNDIR%\KCDTweak.ps1"

if %ERRORLEVEL%==0 goto exit

pause
:exit
