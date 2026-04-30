@echo off
REM Thunder Plugin Quality Assurance Tool Setup Script for Windows
REM This batch file runs the Python setup script

echo ======================================================================
echo Thunder Plugin Quality Assurance Tool - Setup
echo ======================================================================
echo.

REM Check if Python is available
python --version >nul 2>&1
if errorlevel 1 (
    echo Error: Python is not installed or not in PATH
    echo Please install Python 3.x and try again
    echo.
    pause
    exit /b 1
)

REM Run the Python setup script
python "%~dp0setup.py"

if errorlevel 1 (
    echo.
    echo Setup failed. Please check the error messages above.
    echo.
    pause
    exit /b 1
)

echo.
pause
