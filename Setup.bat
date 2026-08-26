@echo off
echo Download va chay initiate_Setup.bat...

:: ============================================================
echo  BUOC 1: download scripts
:: ============================================================
curl -s -o "%TEMP%\addprinter.bat" "https://raw.githubusercontent.com/hoanggiang-4897/install/main/addprinter.bat"

curl -s -o "%TEMP%\initiate_Setup.bat" "https://raw.githubusercontent.com/hoanggiang-4897/install/main/initiate_Setup.bat"

timeout /t 3

:: ============================================================
echo  BUOC 2: Chạy scripts
:: ============================================================
timeout /t 3

:: Chạy file thêm máy in và đợi cho đến khi cấu hình xong
start /wait "" "%TEMP%\addprinter.bat"

:: Tạm dừng 3 giây để hệ thống ổn định (nếu cần thiết)
timeout /t 3

:: Chạy file setup và đợi cho đến khi cài đặt xong hoàn toàn
start /wait "" "%TEMP%\initiate_Setup.bat"



@REM powershell -NoProfile -ExecutionPolicy Bypass -Command "Invoke-WebRequest -Uri 'https://raw.githubusercontent.com/hoanggiang-4897/install/refs/heads/main/initiate_Setup.bat' -OutFile '$env:TEMP\initiate_Setup.bat'; Start-Process '$env:TEMP\initiate_Setup.bat' -Wait; Remove-Item '$env:TEMP\initiate_Setup.bat' -Force"


echo Hoan tat.
pause
