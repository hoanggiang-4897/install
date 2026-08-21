@echo off
echo Download va chay initiate_Setup.bat...

:: ============================================================
echo  BUOC 1: Chạy script cài máy MFD in Richo
:: ============================================================
curl -s -o "%TEMP%\addprinter.bat" "https://raw.githubusercontent.com/hoanggiang-4897/install/main/addprinter.bat" && call "%TEMP%\addprinter.bat"


:: ============================================================
echo  BUOC 2: Chạy script initiate_Setup.bat
:: ============================================================
curl -s -o "%TEMP%\addprinter.bat" "https://raw.githubusercontent.com/hoanggiang-4897/install/main/initiate_Setup.bat" && call "%TEMP%\initiate_Setup.bat"


@REM powershell -NoProfile -ExecutionPolicy Bypass -Command "Invoke-WebRequest -Uri 'https://raw.githubusercontent.com/hoanggiang-4897/install/refs/heads/main/initiate_Setup.bat' -OutFile '$env:TEMP\initiate_Setup.bat'; Start-Process '$env:TEMP\initiate_Setup.bat' -Wait; Remove-Item '$env:TEMP\initiate_Setup.bat' -Force"


echo Hoan tat.
pause