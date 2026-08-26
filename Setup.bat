@echo off
echo Download va chay initiate_Setup.bat...

:: ============================================================
echo  BUOC 1: download scripts
:: ============================================================
curl -s -o "%TEMP%\addprinter.bat" "https://raw.githubusercontent.com/hoanggiang-4897/install/main/addprinter.bat"

curl -s -o "%TEMP%\initiate_Setup.bat" "https://raw.githubusercontent.com/hoanggiang-4897/install/main/initiate_Setup.bat"

:: ============================================================
echo  BUOC 2: Chạy scripts
:: ============================================================
<<<<<<< HEAD

call "%TEMP%\addprinter.bat" -wait

call "%TEMP%\initiate_Setup.bat" -wait
=======
curl -s -o "%TEMP%\initiate_Setup.bat" "https://raw.githubusercontent.com/hoanggiang-4897/install/refs/heads/main/initiate_Setup.bat" && call "%TEMP%\initiate_Setup.bat"
>>>>>>> e37d1c55c2611e7701f9aee9175b1b42257d591e


@REM powershell -NoProfile -ExecutionPolicy Bypass -Command "Invoke-WebRequest -Uri 'https://raw.githubusercontent.com/hoanggiang-4897/install/refs/heads/main/initiate_Setup.bat' -OutFile '$env:TEMP\initiate_Setup.bat'; Start-Process '$env:TEMP\initiate_Setup.bat' -Wait; Remove-Item '$env:TEMP\initiate_Setup.bat' -Force"


echo Hoan tat.
pause
