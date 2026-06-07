@echo off
setlocal

net session >nul 2>nul
if not "%errorlevel%"=="0" (
    echo Requesting administrator permission...
    powershell -Command "Start-Process -FilePath '%~f0' -Verb RunAs"
    exit /b
)

set "MYSQL_SERVICE=MYSQL80"
set "MYSQLD_EXE=C:\Program Files\MySQL\MySQL Server 8.0\bin\mysql.exe"
set "MYSQL_INI=C:\ProgramData\MySQL\MySQL Server 8.0\my.ini"
set "TOMCAT_BIN=D:\apache-tomcat-11.0.20-windows-x64\apache-tomcat-11.0.20\bin"
set "JDBC_JAR=D:\apache-tomcat-11.0.20-windows-x64\apache-tomcat-11.0.20\lib\mysql-connector-j-9.5.0.jar"

set "APP_DB_URL=jdbc:mysql://127.0.0.1:3306/jspdemo?useSSL=false&sslMode=DISABLED&allowPublicKeyRetrieval=true&serverTimezone=Asia/Shanghai&characterEncoding=UTF-8"
set "APP_DB_USER=root"
set "APP_DB_PASSWORD=20060828aA"
set "APP_AI_ENDPOINT=https://api.openai.com/v1/chat/completions"
set "APP_AI_MODEL=gpt-4o-mini"
set "APP_AI_KEY=sk-ceace4a6597a994be88b164285078b734bf6433702b037cc6e7fecef33936bce"

if not exist "%MYSQLD_EXE%" (
    echo MySQL executable not found:
    echo %MYSQLD_EXE%
    pause
    exit /b 1
)

if not exist "%MYSQL_INI%" (
    echo MySQL config not found:
    echo %MYSQL_INI%
    pause
    exit /b 1
)

if not exist "%JDBC_JAR%" (
    echo MySQL JDBC driver not found:
    echo %JDBC_JAR%
    pause
    exit /b 1
)

if not exist "%TOMCAT_BIN%\\startup.bat" (
    echo Tomcat startup script not found:
    echo %TOMCAT_BIN%\startup.bat
    pause
    exit /b 1
)

echo [1/4] Starting MySQL...
sc query "%MYSQL_SERVICE%" | find "RUNNING" >nul
if "%errorlevel%"=="0" (
    echo MySQL service is already running.
) else (
    sc start "%MYSQL_SERVICE%" >nul 2>nul
    timeout /t 3 /nobreak >nul
    sc query "%MYSQL_SERVICE%" | find "RUNNING" >nul
    if "%errorlevel%"=="0" (
        echo MySQL service started.
    ) else (
        echo Service start did not succeed. Trying mysqld.exe directly...
        start "JSPDemo-MySQL" /min "%MYSQLD_EXE%" --defaults-file="%MYSQL_INI%" --console
        timeout /t 5 /nobreak >nul
        netstat -ano | findstr :3306 >nul
        if not "%errorlevel%"=="0" (
            echo MySQL did not start successfully.
            pause
            exit /b 1
        )
        echo MySQL started from executable path.
    )
)

echo [2/4] Starting Tomcat...
cd /d "%TOMCAT_BIN%"
call startup.bat

echo [3/4] Waiting for Tomcat to bind port 8080...
timeout /t 5 /nobreak >nul

echo [4/4] Opening login page...
start http://localhost:8080/JSPDemo/login.jsp

echo.
echo JSPDemo startup flow finished.
echo If AI chat does not work, update APP_AI_KEY in start-jspdemo.bat first.
pause

