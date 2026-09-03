@REM @REM Lần 1
@REM @REM ------------------------------------------------
@REM @REM 1. Download scripts
@REM @REM 2. Run activatekey_hostname.ps1
@REM @REM 3. Save state = STEP2
@REM @REM 4. Restart

@REM @REM Lần 2
@REM @REM ------------------------------------------------
@REM @REM 5. Auto run initiate_Setup.bat
@REM @REM 6. Run download_apps.bat
@REM @REM 7. Save state = STEP3
@REM @REM 8. Restart

@REM @REM Lần 3
@REM @REM ------------------------------------------------
@REM @REM 9. Auto run initiate_Setup.bat
@REM @REM 10. Run addprinter.bat
@REM @REM 11. Cleanup
@REM @REM 12. Hoàn tất

@REM @echo off

@REM echo ==================================================
@REM echo Company Setup
@REM echo ==================================================

@REM :: --------------------------------------------------
@REM :: Download scripts (only first run)
@REM :: --------------------------------------------------

@REM echo STEP 0 - Download scripts

@REM echo add_printer
@REM curl -L -o "%TEMP%\add_printer.bat" "https://raw.githubusercontent.com/hoanggiang-4897/install/refs/heads/main/run/add_printer.bat"

@REM echo download_apps
@REM curl -L -o "%TEMP%\download_apps.bat" "https://raw.githubusercontent.com/hoanggiang-4897/install/refs/heads/main/run/download_apps.bat"

@REM echo activatekey_hostname
@REM curl -L -o "%TEMP%\activatekey_hostname.ps1" "https://raw.githubusercontent.com/hoanggiang-4897/install/refs/heads/main/run/activatekey_hostname.ps1"

@REM echo update_infor
@REM curl -L -o "%TEMP%\update_infor.vbs" "https://raw.githubusercontent.com/hoanggiang-4897/install/refs/heads/main/run/update_infor.vbs"

@REM echo change_hostname
@REM curl -L -o "%TEMP%\change_hostname.bat" "https://raw.githubusercontent.com/hoanggiang-4897/install/refs/heads/main/run/change_hostname.bat"

@REM echo change_hostname
@REM curl -L -o "%TEMP%\set_account.bat" "https://raw.githubusercontent.com/hoanggiang-4897/install/refs/heads/main/run/set_account.bat"

@REM timeout /t 3
@REM :: --------------------------------------------------
@REM :: Run scripts
@REM :: --------------------------------------------------

@REM powershell -command "start-process ""$env:TEMP\set_account.bat"""

@REM timeout /t 3

@REM powershell -command "start-process ""$env:TEMP\change_hostname.bat"""

@REM timeout /t 3

@REM powershell -command "start-process ""$env:TEMP\download_apps.bat"""

@REM timeout /t 3

@REM powershell -command "start-process ""$env:TEMP\add_printer.bat""" -wait "

@REM timeout /t 3

@REM powershell -command "start-process ""$env:TEMP\update_infor.vbs""" -wait "

@REM timeout /t 3

@REM echo STEP FINAL - Cleanup scripts

@REM for %%F in (
@REM     setup.bat
@REM     add_printer.bat
@REM     download_apps.bat
@REM     activatekey_hostname.ps1
@REM     update_infor.vbs
@REM     change_hostname.bat
@REM     set_account.bat
@REM ) do (
@REM     if exist "%TEMP%\%%F" del /f /q "%TEMP%\%%F"
@REM )

@REM echo Cleanup completed.

:: *****************************************************************************************************************
:: *****************************************************************************************************************
:: *****************************************************************************************************************
@echo off
setlocal EnableDelayedExpansion

:: --------------------------------------------------
:: Download scripts
:: --------------------------------------------------

echo STEP 0 - Download scripts

curl -Ls -o "%TEMP%\add_printer.bat" "https://raw.githubusercontent.com/hoanggiang-4897/install/refs/heads/main/run/add_printer.bat"

curl -Ls -o "%TEMP%\download_apps.bat" "https://raw.githubusercontent.com/hoanggiang-4897/install/refs/heads/main/run/download_apps.bat"

curl -Ls -o "%TEMP%\activatekey_hostname.ps1" "https://raw.githubusercontent.com/hoanggiang-4897/install/refs/heads/main/run/activatekey_hostname.ps1"

curl -Ls -o "%TEMP%\update_infor.vbs" "https://raw.githubusercontent.com/hoanggiang-4897/install/refs/heads/main/run/update_infor.vbs"

curl -Ls -o "%TEMP%\change_hostname.bat" "https://raw.githubusercontent.com/hoanggiang-4897/install/refs/heads/main/run/change_hostname.bat"

curl -Ls -o "%TEMP%\set_account.bat" "https://raw.githubusercontent.com/hoanggiang-4897/install/refs/heads/main/run/set_account.bat"

timeout /t 2 /nobreak >nul

:: --------------------------------------------------
:: Menu Selection
:: --------------------------------------------------

echo.
echo ===================================
echo Company Setup
echo ===================================
echo.
echo [1] Set Account
echo [2] Change Hostname
echo [3] Activate Key
echo [4] Download Apps
echo [5] Add Printer
echo [6] Update Info
echo [7] run all
echo.
set /p CHOICE=Nhap lua chon (VD: 1 4 5 6) :


for %%A in (%CHOICE%) do (
    if "%%A"=="1" (
        echo Running Set Account...
        @REM call "%TEMP%\set_account.bat"
        powershell -command "start-process ""$env:TEMP\set_account.bat""" -wait "
    )

    if "%%A"=="2" (
        echo Running Change Hostname...
        @REM call "%TEMP%\change_hostname.bat"
        powershell -command "start-process ""$env:TEMP\change_hostname.bat"""
    )

    if "%%A"=="3" (
        echo Running Activate Key...
        powershell -ExecutionPolicy Bypass -File "%TEMP%\activatekey_hostname.ps1"
    )

    if "%%A"=="4" (
        echo Running Download Apps...
        @REM call "%TEMP%\download_apps.bat"
        powershell -command "start-process ""$env:TEMP\download_apps.bat"""
    )

    if "%%A"=="5" (
        echo Running Add Printer...
        @REM call "%TEMP%\add_printer.bat"
        powershell -command "start-process ""$env:TEMP\add_printer.bat"""
    )

    if "%%A"=="6" (
        echo Running Update Info...
        powershell -command "start-process ""$env:TEMP\update_infor.vbs"""
    )
    
    if "%%A"=="7" (
        echo Running all scripts..................
        echo =====================================
        echo Running Set Account...
        call "%TEMP%\set_account.bat"

        echo =====================================
        echo Running Change Hostname...
        call "%TEMP%\change_hostname.bat"

        echo =====================================
        echo Running Activate Key...
        powershell -ExecutionPolicy Bypass -File "%TEMP%\activatekey_hostname.ps1"

        echo =====================================
        echo Running Download Apps...
        call "%TEMP%\download_apps.bat"

        echo =====================================
        echo Running Add Printer...
        call "%TEMP%\add_printer.bat"

        echo =====================================
        echo Running Update Info...
        powershell -command "start-process ""$env:TEMP\update_infor.vbs"""
    )
)



timeout /t 30 

echo.
set /p CONFIRM="Do you want to delete all scripts? (Y/N): "

if /i "%CONFIRM%"=="Y" (
    for %%F in (
        setup.bat
        add_printer.bat
        download_apps.bat
        activatekey_hostname.ps1
        update_infor.vbs
        change_hostname.bat
        set_account.bat
    ) do (
        if exist "%TEMP%\%%F" del /f /q "%TEMP%\%%F"
    )
    echo Cleanup completed.
) else (
    echo Bo qua cleanup.
)
