@echo off
setlocal
set dp0=%~dp0

bash "%dp0%/iced" %*
endlocal
