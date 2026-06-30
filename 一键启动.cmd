@echo off
setlocal

cd /d "%~dp0"
set "LOG=%~dp0startup.log"
set "APP_EXE=%~dp0build\windows\x64\runner\Release\ai_novel_factory.exe"
if not exist "%APP_EXE%" set "APP_EXE=%~dp0build\windows\x64\runner\Debug\ai_novel_factory.exe"
set "FLUTTER_CMD="
set "ELEVATED_CMD=%TEMP%\ainovelfactory_start_desktop.cmd"

echo AINovelFactory desktop startup > "%LOG%"
echo script=%~f0 >> "%LOG%"
echo cwd=%CD% >> "%LOG%"

if exist "%APP_EXE%" goto start_app

if exist "%LOCALAPPDATA%\Programs\flutter\bin\flutter.bat" (
  set "FLUTTER_CMD=%LOCALAPPDATA%\Programs\flutter\bin\flutter.bat"
)

if not defined FLUTTER_CMD (
  for /f "delims=" %%P in ('where flutter.bat 2^>nul') do (
    if not defined FLUTTER_CMD set "FLUTTER_CMD=%%P"
  )
)

if not defined FLUTTER_CMD (
  echo Flutter was not found. >> "%LOG%"
  echo Flutter was not found.
  echo See startup.log in this folder.
  pause
  exit /b 1
)

echo flutter=%FLUTTER_CMD% >> "%LOG%"
echo app_exe=missing >> "%LOG%"
echo Built desktop app was not found.
echo Building Windows desktop app...

set "link_test=%TEMP%\ainovelfactory_symlink_test_%RANDOM%%RANDOM%"
set "link_target=%link_test%\target"
set "link_path=%link_test%\link"
mkdir "%link_target%" >nul 2>nul
cmd /d /c mklink /D "%link_path%" "%link_target%" >nul 2>nul

if errorlevel 1 (
  rd /s /q "%link_test%" >nul 2>nul
  echo symlink=unavailable >> "%LOG%"
  echo Symlink support is not available for this user.
  echo Requesting Administrator permission to build and start the desktop app...

  > "%ELEVATED_CMD%" echo @echo off
  >> "%ELEVATED_CMD%" echo setlocal
  >> "%ELEVATED_CMD%" echo cd /d "%~dp0"
  >> "%ELEVATED_CMD%" echo call "%FLUTTER_CMD%" build windows --debug --no-pub
  >> "%ELEVATED_CMD%" echo set "exit_code=%%ERRORLEVEL%%"
  >> "%ELEVATED_CMD%" echo echo elevated flutter build exit=%%exit_code%% ^>^> "%LOG%"
  >> "%ELEVATED_CMD%" echo if "%%exit_code%%"=="0" start "" "%APP_EXE%"
  >> "%ELEVATED_CMD%" echo if not "%%exit_code%%"=="0" pause
  >> "%ELEVATED_CMD%" echo exit /b %%exit_code%%

  echo elevated_script=%ELEVATED_CMD% >> "%LOG%"
  powershell -NoProfile -ExecutionPolicy Bypass -Command "Start-Process -FilePath 'cmd.exe' -ArgumentList '/d','/c','\"%ELEVATED_CMD%\"' -Verb RunAs"
  exit /b 0
)

rmdir "%link_path%" >nul 2>nul
rd /s /q "%link_test%" >nul 2>nul
echo symlink=available >> "%LOG%"

call "%FLUTTER_CMD%" build windows --debug --no-pub
set "exit_code=%ERRORLEVEL%"
echo flutter build exit=%exit_code% >> "%LOG%"

if not "%exit_code%"=="0" (
  echo flutter build failed with exit code %exit_code%.
  echo See startup.log in this folder.
  pause
  exit /b %exit_code%
)

if exist "%APP_EXE%" goto start_app

echo Built app was not found after build. >> "%LOG%"
echo Built app was not found after build.
echo See startup.log in this folder.
pause
exit /b 1

:start_app
echo app_exe=%APP_EXE% >> "%LOG%"
echo Starting Windows desktop app...
start "" "%APP_EXE%"
exit /b 0
