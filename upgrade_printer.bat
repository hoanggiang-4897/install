@echo off
:: Khởi chạy quyền Administrator cho Script
:: ----------------------------------------------------
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo Dang yeu cau quyen Administrator...
    powershell -Command "Start-Process '%~f0' -Verb RunAs"
    exit /b
)

:: 1. Cấu hình thông tin máy in tại đây
:: ----------------------------------------------------
set "PrinterName=Tên_Máy_In_Của_Bạn"
set "NewIP=10.68.50.10"
set "OldPort=IP_10.67.4.200"

set "NewPort=IP_%NewIP%"

echo --------------------------------------------------
echo DANG CAP NHAT IP MAY IN...
echo --------------------------------------------------

:: 2. Chạy các lệnh PowerShell riêng lẻ
:: ----------------------------------------------------
echo 1. Dang tao cong IP moi: %NewPort%
powershell -Command "Add-PrinterPort -Name '%NewPort%' -PrinterHostAddress '%NewIP%' -ErrorAction SilentlyContinue"

echo 2. Dang chuyen may in sang cong moi...
powershell -Command "Set-Printer -Name '%PrinterName%' -PortName '%NewPort%'"

echo 3. Dang xoa cong IP cu: %OldPort%
powershell -Command "Remove-PrinterPort -Name '%OldPort%' -ErrorAction SilentlyContinue"

echo --------------------------------------------------
echo THANH CONG! Nhap phim bat ky de thoat.
echo --------------------------------------------------
pause
