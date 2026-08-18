@echo off
title Ricoh Auto Setup
color 0A

:: ==========================
:: CONFIGURATION
:: ==========================

set PRINTER_IP=10.67.4.200
set PRINTER_NAME=Ricoh MP C4504ex

set DRIVER_URL=https://support.ricoh.com/bb/pub_e/dr_ut_e/0001343/0001343376/V3200/z06671L16.exe

set WORKDIR=C:\Temp\Ricoh
set DRIVER_EXE=%WORKDIR%\driver.exe
set EXTRACT_DIR=%WORKDIR%\Extract

:: ==========================
:: DRIVER DOWNLOAD
:: ==========================

echo.
echo Downloading Ricoh Driver...

if not exist "%WORKDIR%" mkdir "%WORKDIR%"

powershell -Command ^
"Invoke-WebRequest '%DRIVER_URL%' -OutFile '%DRIVER_EXE%'"

if not exist "%DRIVER_EXE%" (
    echo Driver download failed.
    pause
    exit /b 1
)

timeout /t 10
:: ==========================
:: WINRAR SILENT EXTRACTION
:: ==========================

echo.
echo Extracting Driver using WinRAR SFX (Silent Mode)...

if not exist "%EXTRACT_DIR%" mkdir "%EXTRACT_DIR%"

@REM :: Cách 1: Chạy tham số Silent của WinRAR SFX tự nén (/s /a /x)
@REM start /wait "" "%DRIVER_EXE%" /s /a /x"%EXTRACT_DIR%"

:: Cách 2: Phòng trường hợp máy đã cài WinRAR.exe, gọi trực tiếp WinRAR để giải nén ngầm
if exist "%ProgramFiles%\WinRAR\WinRAR.exe" (
    "%ProgramFiles%\WinRAR\WinRAR.exe" x -ibck -y "%DRIVER_EXE%" "%EXTRACT_DIR%\" >nul 2>&1
)

taskkill /im RV_SETUP.exe /f
:: Kiểm tra nếu giải nén thành công
timeout /t 10

:: ==========================
:: INSTALL DRIVER TO WINDOWS STORE
:: ==========================

echo.
echo Installing Driver to Driver Store...

for /r "%EXTRACT_DIR%" %%f in (*.inf) do (
    echo Installing INF: %%f
    pnputil /add-driver "%%f" /install >nul 2>&1
)

timeout /t 10

:: ==========================
:: CREATE TCP/IP PORT
:: ==========================

echo.
echo Creating TCP/IP Printer Port (%PRINTER_IP%)...

powershell -Command ^
"$Port='%PRINTER_IP%'; ^
if (!(Get-PrinterPort -Name $Port -ErrorAction SilentlyContinue)) { ^
    Add-PrinterPort -Name $Port -PrinterHostAddress '%PRINTER_IP%' ^
}"

timeout /t 10

:: ==========================
:: CREATE PRINTER
:: ==========================

echo.
echo Binding Driver and Creating Printer...

powershell -Command "$Driver = (Get-PrinterDriver | Where-Object {$_.Name -match 'Ricoh'} | Select-Object -First 1 -ExpandProperty Name)"

powershell -Command "if ($Driver) {Add-Printer -Name '%PRINTER_NAME%' -DriverName $Driver -PortName '%PRINTER_IP%'; Write-Host 'Success! Driver matched: ' $Driver;} else {Write-Host 'Error: No matching Ricoh driver found in system!';}"

timeout /t 10
:: ==========================
:: DONE
:: ==========================

echo.
echo ========================================
echo PRINTER NAME : %PRINTER_NAME%
echo PRINTER IP   : %PRINTER_IP%
echo PORT NAME    : IP_%PRINTER_IP%
echo STATUS       : INSTALLED SUCCESSFULLY
echo ========================================

timeout /t 10 >nul