@echo off
setlocal

net session >nul 2>nul
if not "%errorlevel%"=="0" (
    echo Requesting administrator permission...
    powershell -Command "Start-Process -FilePath '%~f0' -Verb RunAs"
    exit /b
)

set "APP_DB_URL=jdbc:mysql://127.0.0.1:3306/jspdemo?useSSL=false&sslMode=DISABLED&allowPublicKeyRetrieval=true&serverTimezone=Asia/Shanghai&characterEncoding=UTF-8"
set "APP_DB_USER=root"
set "APP_DB_PASSWORD=asuka123"
set "APP_AI_ENDPOINT=https://api.openai.com/v1/chat/completions"
set "APP_AI_MODEL=gpt-4o-mini"
set "APP_AI_KEY=REPLACE_WITH_YOUR_AI_KEY"

echo [1/4] Starting MySQL service...
sc query MYSQL80 | find "RUNNING" >nul
if "%errorlevel%"=="0" (
    echo MySQL service is already running.
) else (
    powershell -Command "Start-Service MYSQL80"
    if errorlevel 1 (
        echo Failed to start MYSQL80.
        pause
        exit /b 1
    )
    timeout /t 3 /nobreak >nul
    sc query MYSQL80 | find "RUNNING" >nul
    if not "%errorlevel%"=="0" (
        echo MYSQL80 did not enter RUNNING state.
        pause
        exit /b 1
    )
    echo MySQL service started.
)

echo [2/4] Starting Tomcat...
cd /d "C:\Program Files\Apache Software Foundation\Tomcat 9.0\bin"
call startup.bat

echo [3/4] Waiting for Tomcat to bind port 8080...
timeout /t 5 /nobreak >nul

echo [4/4] Opening login page...
start http://localhost:8080/JSPDemo/login.jsp

echo.
echo JSPDemo startup flow finished.
echo If AI chat does not work, update APP_AI_KEY in start-jspdemo.bat first.
pause

