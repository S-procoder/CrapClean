@echo off
setlocal EnableExtensions
title CrapClean 2.0
cd /d "%~dp0"

if not exist "%~dp0CrapClean.ps1" (
  echo.
  echo  CrapClean.ps1 is missing from this folder.
  echo.
  echo  You need BOTH files in the same folder:
  echo     CrapClean.bat   ^(this one^)
  echo     CrapClean.ps1
  echo.
  echo  Download the release zip from:
  echo     https://github.com/S-procoder/CrapClean/releases
  echo  then right-click the zip - Extract All - and run CrapClean.bat from there.
  echo.
  pause
  exit /b 1
)

net session >nul 2>&1
if %errorlevel% neq 0 (
  echo.
  echo  Asking Windows for administrator rights...
  echo  A blue "Do you want to allow this app to make changes" box will appear.
  echo  Press Yes.
  echo.
  powershell -NoProfile -ExecutionPolicy Bypass -Command "Start-Process -FilePath '%~f0' -Verb RunAs"
  exit /b
)

powershell -NoProfile -ExecutionPolicy Bypass -STA -File "%~dp0CrapClean.ps1"
if %errorlevel% neq 0 (
  echo.
  echo  CrapClean closed with an error. Nothing else was deleted.
  echo  Logs: %%LOCALAPPDATA%%\CrapClean\logs
  echo.
  pause
)
endlocal
