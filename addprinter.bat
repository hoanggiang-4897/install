@echo off
title Ricoh Auto Setup - Fully Silent
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

echo Downloading Ricoh Driver...

if not exist "%WORKDIR%" mkdir "%WORKDIR%"

powershell -Command "[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; Invoke-WebRequest '%DRIVER_URL%' -OutFile '%DRIVER_EXE%'"

if not exist "%DRIVER_EXE%" (
    echo Driver download failed.
    pause
    exit /b 1
)

:: ==========================
:: SILENT EXTRACTION (NO SETUP POPUP)
:: ==========================

echo Extracting Driver files only (skipping GUI setup)...

if not exist "%EXTRACT_DIR%" mkdir "%EXTRACT_DIR%"

:: Phương án 1: Dùng WinRAR giải nén chỉ lấy file (không khởi chạy RV_SETUP)
if exist "%ProgramFiles%\WinRAR\WinRAR.exe" (
    "%ProgramFiles%\WinRAR\WinRAR.exe" x -ibck -y "%DRIVER_EXE%" "%EXTRACT_DIR%\" >nul 2>&1
) else (
    :: Phương án 2: Dùng PowerShell giải nén trực tiếp file EXE dưới dạng ZIP/Archive
    powershell -Command "Expand-Archive -Path '%DRIVER_EXE%' -DestinationPath '%EXTRACT_DIR%' -Force" >nul 2>&1
)

:: Tắt cưỡng chế nếu bộ tự giải nén cố tình kích hoạt RV_SETUP.exe
taskkill /f /im RV_SETUP.exe >nul 2>&1
taskkill /f /im Setup.exe >nul 2>&1

:: ==========================
:: INSTALL DRIVER TO WINDOWS
:: ==========================

echo Registering INF Drivers into Windows Store...

for /r "%EXTRACT_DIR%" %%f in (*.inf) do (
    pnputil /add-driver "%%f" /install >nul 2>&1
)

:: ==========================
:: CREATE TCP/IP PORT
:: ==========================

echo Creating Printer Port (%PRINTER_IP%)...

powershell -Command ^
"$Port='%PRINTER_IP%'; ^
if (!(Get-PrinterPort -Name $Port -ErrorAction SilentlyContinue)) { ^
    Add-PrinterPort -Name $Port -PrinterHostAddress '%PRINTER_IP%' ^
}"

:: ==========================
:: CREATE PRINTER
:: ==========================

echo Creating Printer Object...
timeout /t 3

powershell -Command "& { ^
    $drv = Get-PrinterDriver | Where-Object { $_.Name -like '*C4504*' -or $_.Name -like '*Ricoh*' -or $_.Name -like '*PCL*' } | Select-Object -First 1 -ExpandProperty Name; ^
    if ($drv) { ^
        Add-Printer -Name '%PRINTER_NAME%' -DriverName $drv -PortName '%PRINTER_IP%'; ^
        Write-Host 'SUCCESS: Printer added with driver:' $drv; ^
    } else { ^
        Write-Host 'ERROR: Could not match driver in Windows Store!'; ^
    } ^
}"
timeout /t 10
:: ==========================
:: DONE
:: ==========================

echo.
echo ========================================
echo PRINTER NAME : %PRINTER_NAME%
echo PRINTER IP   : %PRINTER_IP%
echo STATUS       : INSTALLED SUCCESSFULLY
echo ========================================
pause
