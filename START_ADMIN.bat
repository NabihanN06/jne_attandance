@echo off
REM ─────────────────────────────────────────────
REM START_ADMIN.bat - Next.js Admin Web Startup
REM ─────────────────────────────────────────────

echo.
echo ╔════════════════════════════════════════════╗
echo ║  JNE Attendance Admin - Next.js Web       ║
echo ║  Starting...                              ║
echo ╚════════════════════════════════════════════╝
echo.

cd /d "%~dp0"

REM Check if we're in the right directory
if not exist "admin\package.json" (
    echo ERROR: admin folder not found!
    echo Please run this script from the root directory.
    pause
    exit /b 1
)

REM Navigate to admin project
cd admin

REM Check if node_modules exist
if not exist "node_modules" (
    echo [1/3] Installing dependencies...
    call npm install
    if errorlevel 1 (
        echo ERROR: Failed to install dependencies
        pause
        exit /b 1
    )
)

echo [2/3] Checking .env.local...
if not exist ".env.local" (
    echo ERROR: .env.local not found!
    echo Please copy .env.example to .env.local and fill in Firebase credentials.
    pause
    exit /b 1
)

echo [3/3] Starting development server...
call npm run dev

pause
