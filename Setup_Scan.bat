@echo off
title Create Scan Account and Shared Folder

echo ========================================
echo Creating local user scan_acc...
echo ========================================

powershell -Command "if (-not (Get-LocalUser -Name 'scan_acc' -ErrorAction SilentlyContinue)) { New-LocalUser -Name 'scan_acc' -Password (ConvertTo-SecureString 'Account@Scan' -AsPlainText -Force) }"

powershell -Command "Enable-LocalUser -Name 'scan_acc'"

echo.
echo ========================================
echo Creating folder C:\scan...
echo ========================================

if not exist "C:\scan" (
    mkdir "C:\scan"
)

echo.
echo ========================================
echo Creating SMB Share...
echo ========================================

powershell -Command "if (-not (Get-SmbShare -Name 'scan' -ErrorAction SilentlyContinue)) { New-SmbShare -Name 'scan' -Path 'C:\scan' -FullAccess 'scan_acc' }"

echo.
echo ========================================
echo Granting NTFS Full Control...
echo ========================================

icacls "C:\scan" /grant "scan_acc:(OI)(CI)F" /inheritance:e /T

echo.
echo ========================================
echo Configuration completed.
echo ========================================

echo.
echo User   : scan_acc
echo Share  : \\%COMPUTERNAME%\scan
echo Folder : C:\scan

pause