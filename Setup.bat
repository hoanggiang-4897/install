@REM Lần 1
@REM ------------------------------------------------
@REM 1. Download scripts
@REM 2. Run activatekey_hostname.ps1
@REM 3. Save state = STEP2
@REM 4. Restart

@REM Lần 2
@REM ------------------------------------------------
@REM 5. Auto run initiate_Setup.bat
@REM 6. Run download_apps.bat
@REM 7. Save state = STEP3
@REM 8. Restart

@REM Lần 3
@REM ------------------------------------------------
@REM 9. Auto run initiate_Setup.bat
@REM 10. Run addprinter.bat
@REM 11. Cleanup
@REM 12. Hoàn tất

@echo off
setlocal

set TASKNAME=CompanySetup
set STATEFILE=%TEMP%\CompanySetup.state

echo ==================================================
echo Company Setup
echo ==================================================

:: --------------------------------------------------
:: Download scripts (only first run)
:: --------------------------------------------------

if not exist "%STATEFILE%" (

    echo STEP 0 - Download scripts
    echo add_printer
    curl -L -o "%TEMP%\add_printer.bat" "https://raw.githubusercontent.com/hoanggiang-4897/install/refs/heads/main/run/add_printer.bat"
    echo download_apps
    curl -L -o "%TEMP%\download_apps.bat" "https://raw.githubusercontent.com/hoanggiang-4897/install/refs/heads/main/run/download_apps.bat"
    echo activatekey_hostname
    curl -L -o "%TEMP%\activatekey_hostname.ps1" "https://raw.githubusercontent.com/hoanggiang-4897/install/refs/heads/main/run/activatekey_hostname.ps1"
    echo update_infor
    curl -L -o "%TEMP%\update_infor.vbs" "https://raw.githubusercontent.com/hoanggiang-4897/install/refs/heads/main/run/update_infor.vbs"
    echo change_hostname
    curl -L -o "%TEMP%\change_hostname.bat" "https://raw.githubusercontent.com/hoanggiang-4897/install/refs/heads/main/run/change_hostname.vbs"

    :: Create Task
    schtasks /create ^
        /tn "%TASKNAME%" ^
        /sc onlogon ^
        /rl highest ^
        /tr "\"%~f0\"" ^
        /f

    echo STEP1 > "%STATEFILE%"
)

:: --------------------------------------------------
:: Read current state
:: --------------------------------------------------

set /p STEP=<"%STATEFILE%"

:: --------------------------------------------------
:: STEP 1
:: --------------------------------------------------

if /I "%STEP%"=="STEP1" (

    echo.
    echo Running activatekey_hostname.ps1
    echo.

    @REM powershell.exe ^
    @REM   -NoProfile ^
    @REM   -ExecutionPolicy Bypass ^
    @REM   -File "%TEMP%\activatekey_hostname.ps1"

    echo STEP2 > "%STATEFILE%"

    echo.
    echo Restarting...
    timeout /t 5

    @REM shutdown /r /t 0

    exit
)

:: --------------------------------------------------
:: STEP 2
:: --------------------------------------------------

if /I "%STEP%"=="STEP2" (

    echo.
    echo Running download_apps.bat
    echo.

    start /wait "" "%TEMP%\download_apps.bat"

    echo STEP3 > "%STATEFILE%"

    @REM echo.
    @REM echo Restarting...
    @REM timeout /t 5

    @REM shutdown /r /t 0

    exit
)

:: --------------------------------------------------
:: STEP 3
:: --------------------------------------------------

if /I "%STEP%"=="STEP3" (

    echo.
    echo Running addprinter.bat
    echo.

    start /wait "" "%TEMP%\add_printer.bat"

    del "%STATEFILE%" /f /q

    schtasks /delete ^
        /tn "%TASKNAME%" ^
        /f

    echo.
    echo ==========================
    echo Setup Completed
    echo ==========================

    pause
)

endlocal