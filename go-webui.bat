@echo off
setlocal
rem Examples: go-webui.bat cpu    go-webui.bat -Device cu126 -Language en_US
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0go-webui.ps1" %*
exit /b %errorlevel%
