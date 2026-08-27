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

echo ==================================================
echo Company Setup
echo ==================================================

:: --------------------------------------------------
:: Download scripts (only first run)
:: --------------------------------------------------

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
curl -L -o "%TEMP%\change_hostname.bat" "https://raw.githubusercontent.com/hoanggiang-4897/install/refs/heads/main/run/change_hostname.bat"



timeout /t 3
:: --------------------------------------------------
:: Run scripts
:: --------------------------------------------------

powershell -command "start-process ""$env:TEMP\change_hostname.bat"""

timeout /t 3

powershell -command "start-process ""$env:TEMP\download_apps.bat"""

timeout /t 3

powershell -command "start-process ""$env:TEMP\add_printer.bat"""

timeout /t 3


