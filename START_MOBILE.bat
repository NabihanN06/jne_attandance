@echo off
REM ─────────────────────────────────────────────
REM START_MOBILE.bat - Flutter Mobile App Startup
REM ─────────────────────────────────────────────

echo.
echo ╔════════════════════════════════════════════╗
echo ║  JNE Attendance Mobile App - Flutter      ║
echo ║  Starting...                              ║
echo ╚════════════════════════════════════════════╝
echo.

cd /d "%~dp0"

REM Check if we're in the right directory
if not exist "user_mobile\pubspec.yaml" (
    echo ERROR: user_mobile folder not found!
    echo Please run this script from the root directory.
    pause
    exit /b 1
)

REM Navigate to mobile project
cd user_mobile

REM Get dependencies
echo [1/3] Fetching Flutter dependencies...
call flutter pub get
if errorlevel 1 (
    echo ERROR: Failed to fetch dependencies
    pause
    exit /b 1
)

echo.
echo [2/3] Analyzing project...
call flutter analyze
if errorlevel 1 (
    echo WARNING: Some analysis warnings found (non-blocking)
)

echo.
echo [3/3] Running Flutter app...
call flutter run

pause
