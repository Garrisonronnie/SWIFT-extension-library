@echo off
cd /d "%~dp0"

echo ===============================
echo SmartImageTool Installer
echo ===============================
echo.

REM Step 1: Prompt for image URL
set /p ICON_URL=Paste your custom profile image URL (PNG/JPG):

REM Save the URL to a config file
echo { > userImageConfig.json
echo "customIconURL": "%ICON_URL%" >> userImageConfig.json
echo } >> userImageConfig.json

REM Step 2: Run Node script to generate
where node >nul 2>&1
if %errorlevel% neq 0 (
echo Node.js not found. Please install Node.js.
pause
exit /b
)

echo Generating your SmartImageTool script...
node generateScript.js

REM Step 3: Launch in browser
if exist index.html (
echo Opening SmartImageTool in browser...
start index.html
) else (
echo index.html not found. Please make sure it exists in the current folder.
)

echo.
echo Setup Complete!
pause
