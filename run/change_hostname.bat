:: ============================================================
echo TU DONG LAY SERIAL NUMBER VA DOI HOSTNAME
:: ============================================================
:: Thay the WMIC bang PowerShell de lay Serial Number chuan xac tren Windows 11
for /f "usebackq tokens=*" %%I in (`powershell -Command "(Get-CimInstance Win32_Bios).SerialNumber.Trim()"`) do set "Serial=%%I"

:: Neu khong lay duoc serial hoax chuoi rong, tu dong dung thoi gian de lam chuoi ngau nhien
if "%Serial%"=="" (
    set "Serial=%RANDOM%"
)

set "NewHostName=VNHCM%Serial%"
echo Hostname hien tai: %COMPUTERNAME%
echo Hostname moi se dat: %NewHostName%
echo.

if /i not "%COMPUTERNAME%"=="%NewHostName%" (
    powershell -Command "Rename-Computer -NewName '%NewHostName%' -Force" >nul 2>&1
    echo [OK] Da thiet lap doi ten may thanh %NewHostName%.
) else (
    echo [OK] Ten may da trung khop, bo qua doi ten.
)
echo ------------------------------------------------------------
echo.