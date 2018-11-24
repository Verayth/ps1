@echo off
set RUNDIR=%~dp0

call powershell.exe -NoProfile -executionpolicy remotesigned -File "%RUNDIR%\7DTDTweak.ps1"

if %ERRORLEVEL%==0 goto exit

pause
:exit
