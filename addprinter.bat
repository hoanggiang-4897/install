@echo off
title Ricoh Auto Setup - Silent
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

powershell -Command "[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; Invoke-WebRequest '%DRIVER_URL%' -OutFile '%DRIVER_EXE%'"

if not exist "%DRIVER_EXE%" (
    echo Driver download failed.
    pause
    exit /b 1
)

:: ==========================
:: WINRAR SILENT EXTRACTION
:: ==========================

echo.
echo Extracting Driver using WinRAR SFX (Silent Mode)...

if not exist "%EXTRACT_DIR%" mkdir "%EXTRACT_DIR%"

:: Giải nén ngầm 100% bằng WinRAR SFX
start /wait "" "%DRIVER_EXE%" /s /a /x"%EXTRACT_DIR%"

:: ==========================
:: INSTALL DRIVER TO WINDOWS STORE
:: ==========================

echo.
echo Installing Driver to Driver Store...

for /r "%EXTRACT_DIR%" %%f in (*.inf) do (
    echo Installing INF: %%f
    pnputil /add-driver "%%f" /install >nul 2>&1
)

:: ==========================
:: CREATE TCP/IP PORT
:: ==========================

echo.
echo Creating TCP/IP Printer Port (%PRINTER_IP%)...

powershell -Command ^
"$Port='IP_%PRINTER_IP%'; ^
if (!(Get-PrinterPort -Name $Port -ErrorAction SilentlyContinue)) { ^
    Add-PrinterPort -Name $Port -PrinterHostAddress '%PRINTER_IP%' ^
}"

:: ==========================
:: CREATE PRINTER
:: ==========================

echo.
echo Binding Driver and Creating Printer...

powershell -Command "& { ^
    $drv = Get-PrinterDriver | Where-Object { $_.Name -like '*C4504*' -or $_.Name -like '*Ricoh*' -or $_.Name -like '*PCL*' } | Select-Object -First 1 -ExpandProperty Name; ^
    if ($drv) { ^
        Add-Printer -Name '%PRINTER_NAME%' -DriverName $drv -PortName 'IP_%PRINTER_IP%'; ^
        Write-Host 'Success! Driver matched: ' $drv; ^
    } else { ^
        Write-Host 'Error: No matching driver found in Windows Store!'; ^
    } ^
}"

:: ==========================
:: DONE
:: ==========================

echo.
echo ========================================
echo PRINTER NAME : %PRINTER_NAME%
echo PRINTER IP   : %PRINTER_IP%
echo PORT NAME    : IP_%PRINTER_IP%
echo STATUS       : COMPLETED
echo ========================================
