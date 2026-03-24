@echo off
setlocal

echo [1/2] Stopping Tomcat...
cd /d "C:\Program Files\Apache Software Foundation\Tomcat 9.0\bin"
call shutdown.bat

echo [2/2] Tomcat stop command sent.
echo MySQL service is left running on purpose.
pause
