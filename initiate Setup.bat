@echo off
title Script Full Setup PC: Automated Deployment (Fixed WMIC)
cls

echo ============================================================
echo   KICH BAN SETUP TU DONG HOAN TOAN (AUTOMATED - AUTO YES)
echo ============================================================
echo.

:: Kiem tra quyen Administrator
net session >nul 2>&1
if %errorLevel% == 0 (
    echo [OK] Dang chay voi quyen Administrator.
) else (
    echo [ERROR] Vui long click chuot phai chon "Run as Administrator"!
    echo.
    timeout /t 5
    exit /b
)

:: ============================================================
echo  BUOC 1: TU DONG LAY SERIAL NUMBER VA DOI HOSTNAME
echo ============================================================
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

:: Tao thu muc tam de chua file tai ve
set "SetupFolder=%SystemDrive%\Software_Setup"
if not exist "%SetupFolder%" mkdir "%SetupFolder%"
cd /d "%SetupFolder%"

:: ============================================================
echo  BUOC 2: DOWNLOAD TAT CA CAC FILE CAI DAT (.EXE/.MSI)
echo ============================================================
echo.
:: Cap nhat tai Chrome phien ban Standalone .exe chinh thuc tu Google
echo [+] Dang tai Google Chrome (.exe)...
curl -L -o "chrome_installer.exe" "https://dl.google.com/tag/s/appguid%%3D%%7B8A69D345-D564-463C-AFF1-A69D9E530F96%%7D%%26iid%%3D%%7B809E0AA9-1065-C234-A758-B603248386EE%%7D%%26lang%%3Dvi%%26browser%%3D4%%26usagestats%%3D0%%26appname%%3DGoogle%%2520Chrome%%26needsadmin%%3Dtrue%%26ap%%3Dx64-stable-statsdef_1%%26brand%%3DGCEY/update2/installers/ChromeStandaloneSetup64.exe"

echo [+] Dang tai UltraViewer...
curl -L -o "ultraviewer_setup.exe" "https://www.ultraviewer.net/vi/download/UltraViewer_setup_vi.exe"

echo [+] Dang tai 7-Zip...
curl -L -o "7z_setup.exe" "https://www.7-zip.org/a/7z2408-x64.exe"

@REM echo [+] Dang tai WinRAR...
@REM curl -L -o "winrar_setup.exe" "https://www.rarlab.com/rar/winrar-x64-701.exe"

:: Thay the link tai UniKey 4.6 RC2 64-bit truc tiep tu trang chu unikey.org
echo [+] Dang tai UniKey (Chinh chu unikey.org)...
curl -L -o "unikey_setup.zip" "https://www.unikey.org/assets/release/unikey46RC2-230919-win64.zip"

echo [+] Dang tai Microsoft 365 Setup...
curl -L -o "setup_office.exe" "https://go.microsoft.com/fwlink/?linkid=2102395"

echo [+] Dang tai Microsoft Teams...
curl -L -o "teams_setup.exe" "https://go.microsoft.com/fwlink/?linkid=2187217"

@REM echo [+] Dang tai phan mem Base...
@REM curl -L -o "base_setup.exe" "https://update.basecdn.net/apps/desktop/win/x64/Base%20Setup.exe"

@REM :: Tu dong tao file cau hinh XML cho Office 365 (Chay an hoan toan)
@REM (
@REM echo ^<Configuration^>
@REM echo   ^<Add OfficeClientEdition="64" Channel="Current"^>
@REM echo     ^<Product ID="O365ProPlusRetail"^>
@REM echo       ^<Language ID="en-us" /^>
@REM echo     ^</Product^>
@REM echo   ^</Add^>
@REM echo   ^<Updates Enabled="TRUE" Channel="Current" /^>
@REM echo   ^<Display Level="None" AcceptEULA="TRUE" /^>
@REM echo ^</Configuration^>
@REM ) > configuration.xml

echo.
echo === DA DOWNLOAD XONG! CHUYEN SANG CAI DAT LUON ===
echo.
timeout /t 2 >nul
cls

:: ============================================================
echo  BUOC 3: TIEN HANH CAI DAT TU DONG TUNG PHAN MEM
echo ============================================================
echo.

:: 1. Chrome (Sua lai lenh chay file .exe)
echo [1/8] Dang cai dat Google Chrome...
start /wait "" "chrome_installer.exe" /silent /install
echo [OK] Chrome xong.
echo.

:: 2. UltraViewer
echo [2/8] Dang cai dat UltraViewer...
start /wait "" "ultraviewer_setup.exe" /VERYSILENT /SUPPRESSMSGBOXES /NORESTART
echo [OK] UltraViewer xong.
echo.

:: 3. 7-Zip
echo [3/8] Dang cai dat 7-Zip...
start /wait "" "7z_setup.exe" /S
echo [OK] 7-Zip xong.
echo.

@REM :: 4. WinRAR
@REM echo [4/8] Dang cai dat WinRAR...
@REM start /wait "" "winrar_setup.exe" /S
@REM echo [OK] WinRAR xong.
@REM echo.

:: 5. UniKey
echo [5/8] Dang giai nen va cau hinh UniKey...
if not exist "C:\UniKey" mkdir "C:\UniKey"
:: Giai nen ra thu muc tam truoc, sau do copy de khong bi tao sai thong tin thu muc con
powershell -Command "Expand-Archive -Path 'unikey_setup.zip' -DestinationPath '.\unikey_extracted' -Force"
powershell -Command "Get-ChildItem -Path '.\unikey_extracted' -Recurse -Filter '*.exe' | Copy-Item -Destination 'C:\UniKey\' -Force"
powershell -Command "Get-ChildItem -Path '.\unikey_extracted' -Recurse -Filter '*.dll' | Copy-Item -Destination 'C:\UniKey\' -Force"
:: Tao shortcut ra Desktop
powershell -Command "$WshShell = New-Object -ComObject WScript.Shell; $Shortcut = $WshShell.CreateShortcut([System.IO.Path]::Combine([Environment]::GetFolderPath('Desktop'), 'UniKey.lnk')); $Shortcut.TargetPath = 'C:\UniKey\UniKeyNT.exe'; $Shortcut.Save()"
echo [OK] UniKey xong.
echo.

@REM :: 6. Microsoft 365
@REM echo [6/8] Dang cai dat Microsoft 365 (Chay ngam hoan toan)...
@REM start /wait "" "setup_office.exe" /configure "configuration.xml"
@REM echo [OK] Microsoft 365 xong.
@REM echo.

@REM :: 7. Microsoft Teams
@REM echo [7/8] Dang cai dat Microsoft Teams...
@REM start /wait "" "teams_setup.exe" /checkInstall /silent
@REM echo [OK] Microsoft Teams xong.
@REM echo.

@REM :: 8. Phần mềm Base
@REM echo [8/8] Dang cai dat Base Desktop...
@REM start /wait "" "base_setup.exe" /S
@REM echo [OK] Base Desktop xong.
@REM echo.

@REM :: ============================================================
@REM echo  BUOC 4: DON DEP HE THONG NGHIEP VU & TU DONG REBOOT
@REM echo ============================================================
@REM echo Dang xoa file tam...
@REM cd /
@REM rd /s /q "%SetupFolder%"
@REM echo.

echo ============================================================
echo   CAI DAT HOAN THANH! MAY TINH SE TU DONG REBOOT SAU 5 GIAY
echo ============================================================
echo.

shutdown /r /t 5 /c "Tu dong khoi dong lai theo kich ban Setup de nhan Hostname moi"
exit