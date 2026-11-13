@echo off
echo Cleaning system trash... hold on to your RAM ??

:: Clear user temp files
del /q/f/s %TEMP%\*
rd /s/q %TEMP%

:: Clear system temp files
del /q/f/s C:\Windows\Temp\*
rd /s/q C:\Windows\Temp

:: Clear Prefetch data
del /q/f/s C:\Windows\Prefetch\*
rd /s/q C:\Windows\Prefetch

:: Clear recent files list
del /q/f/s %APPDATA%\Microsoft\Windows\Recent\*
rd /s/q %APPDATA%\Microsoft\Windows\Recent
del /s /f /q c:\windows\temp\*.*
rd /s /q c:\windows\temp
md c:\windows\temp
del /s /f /q C:\WINDOWS\Prefetch
del /s /f /q %temp%\*.*
rd /s /q %temp%
md %temp%
deltree /y c:\windows\tempor~1
deltree /y c:\windows\temp
deltree /y c:\windows\tmp
deltree /y c:\windows\ff*.tmp
deltree /y c:\windows\history
deltree /y c:\windows\cookies
deltree /y c:\windows\recent
del c:\WIN386.SWP
:: Open Disk Cleanup
cleanmgr /sagerun:1
echo Done! Your PC is better now....
pause
