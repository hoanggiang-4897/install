@echo off
echo Download va chay initiate_Setup.bat...

:: ============================================================
echo  BUOC 1: download scripts
:: ============================================================
curl -s -o "%TEMP%\addprinter.bat" "https://raw.githubusercontent.com/hoanggiang-4897/install/refs/heads/main/run/addprinter.bat"

curl -s -o "%TEMP%\download_apps.bat" "https://raw.githubusercontent.com/hoanggiang-4897/install/refs/heads/main/run/download_apps.bat"

curl -s -o "%TEMP%\activatekey_hostname.ps1" "https://raw.githubusercontent.com/hoanggiang-4897/install/refs/heads/main/run/activatekey_hostname.ps1"

curl -s -o "%TEMP%\update_infor.vbs" "https://raw.githubusercontent.com/hoanggiang-4897/install/refs/heads/main/run/update_infor.vbs"

timeout /t 3

:: ============================================================
echo  BUOC 2: Run scripts
:: ============================================================
:: Chạy activatekey_hostname.ps1
@REM start /wait "" powershell.exe -ExecutionPolicy Bypass -File "%TEMP%\activatekey_hostname.ps1"
start /wait "" "%TEMP%\activatekey_hostname.ps1"

timeout /t 3

:: Chạy fil
start /wait "" "%TEMP%\download_apps.bat"

:: Tạm dừng 3 giây để hệ thống ổn định (nếu cần thiết)
timeout /t 3

:: Chạy file setup và đợi cho đến khi cài đặt xong hoàn toàn
start /wait "" "%TEMP%\add_printer.bat"



@REM powershell -NoProfile -ExecutionPolicy Bypass -Command "Invoke-WebRequest -Uri 'https://raw.githubusercontent.com/hoanggiang-4897/install/refs/heads/main/initiate_Setup.bat' -OutFile '$env:TEMP\initiate_Setup.bat'; Start-Process '$env:TEMP\initiate_Setup.bat' -Wait; Remove-Item '$env:TEMP\initiate_Setup.bat' -Force"


echo Hoan tat.
pause
