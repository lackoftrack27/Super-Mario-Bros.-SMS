@echo off

call :build smb           0 0
call :build smbPAL        0 1
call :build smb224p       1 0
call :build smbPAL240p    2 1

goto :eof

:build
set "name=%~1"
set "linemode=%~2"
set "palbuild=%~3"

echo.
echo === %name%  (LINEMODE=%linemode% PALBUILD=%palbuild%) ===
echo.

wla-z80 -D LINEMODE=%linemode% -D PALBUILD=%palbuild% -o "%name%.o" main.asm
if errorlevel 1 exit /b 1

> "%name%.link" echo [objects]
>> "%name%.link" echo %name%.o

wlalink -r -v -S "%name%.link" "%name%.sms"
if errorlevel 1 exit /b 1

del "%name%.link" "%name%.o"

goto :eof
