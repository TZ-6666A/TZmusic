@echo off
setlocal

set "DEVECO_HOME=D:\HarmonyDeveco\DevEco Studio"
set "DEVECO_SDK_HOME=%DEVECO_HOME%\sdk"
set "NODE_HOME=%DEVECO_HOME%\tools\node"

call "%DEVECO_HOME%\tools\ohpm\bin\ohpm.bat" %*
exit /b %ERRORLEVEL%
