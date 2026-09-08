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
echo BUOC 1: DOWNLOAD TAT CA CAC FILE CAI DAT (.EXE/.MSI)
:: ===========================================================
echo.

:: Tao thu muc tam de chua file tai ve
set "SetupFolder=%SystemDrive%\Software_Setup"
if not exist "%SetupFolder%" mkdir "%SetupFolder%"
cd /d "%SetupFolder%"


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
curl -L -o "setup_office.exe" "https://go.microsoft.com/fwlink/?linkid=2264705&amp;clcid=0x42a&amp;culture=vi-vn&amp;country=vn"

echo [+] Dang tai FoxitPDF Reader202613_L10N_Setup_Prom_x64 Setup...
curl -L -o FoxitPDFReader202613_L10N_Setup_Prom_x64.exe "https://cdn01.foxitsoftware.com/product/reader/desktop/win/2026.1.3/FoxitPDFReader202613_L10N_Setup_Prom_x64.exe"

echo.
echo === DA DOWNLOAD XONG! CHUYEN SANG CAI DAT LUON ===
echo.
timeout /t 2 >nul
cls

:: ============================================================
echo  BUOC 2: TIEN HANH CAI DAT TU DONG TUNG PHAN MEM
echo ============================================================
echo.

:: 1. Chrome (Sua lai lenh chay file .exe)
echo *** Dang cai dat Google Chrome...
start /wait "" "%SetupFolder%\chrome_installer.exe" /silent /install
echo [OK] Chrome xong.
echo.

@REM :: 2. UltraViewer
@REM echo [2/8] Dang cai dat UltraViewer...
@REM start /wait "" "ultraviewer_setup.exe" /VERYSILENT /SUPPRESSMSGBOXES /NORESTART
@REM echo [OK] UltraViewer xong.
@REM echo.

:: 3. 7-Zip
echo *** Dang cai dat 7-Zip...
start /wait "" "%SetupFolder%\7z_setup.exe" /S
echo [OK] 7-Zip xong.
echo.

@REM :: 4. WinRAR
@REM echo [4/8] Dang cai dat WinRAR...
@REM start /wait "" "winrar_setup.exe" /S
@REM echo [OK] WinRAR xong.
@REM echo.

:: 5. UniKey
echo *** Dang giai nen va cau hinh UniKey...
if not exist "C:\UniKey" mkdir "C:\UniKey"
:: Giai nen ra thu muc tam truoc, sau do copy de khong bi tao sai thong tin thu muc con
powershell -Command "Expand-Archive -Path 'unikey_setup.zip' -DestinationPath '.\unikey_extracted' -Force"
powershell -Command "Get-ChildItem -Path '.\unikey_extracted' -Recurse -Filter '*.exe' | Copy-Item -Destination 'C:\Users\Public\Desktop' -Force"
powershell -Command "Get-ChildItem -Path '.\unikey_extracted' -Recurse -Filter '*.dll' | Copy-Item -Destination 'C:\Users\Public\Desktop' -Force"
:: Tao shortcut ra Desktop
@REM powershell -Command "$WshShell = New-Object -ComObject WScript.Shell; $Shortcut = $WshShell.CreateShortcut([System.IO.Path]::Combine([Environment]::GetFolderPath('Desktop'), 'UniKey.lnk')); $Shortcut.TargetPath = 'C:\UniKey\UniKeyNT.exe'; $Shortcut.Save()"
echo [OK] UniKey xong.
echo.

:: cài Phần mềm FoxitPDF Reader202613_L10N_Setup_Prom_x64
echo *** Dang cai dat FoxitPDF Reader202613_L10N_Setup_Prom_x64...
start /wait "" "%SetupFolder%\FoxitPDFReader202613_L10N_Setup_Prom_x64.exe" /quiet
echo [OK] FoxitPDF Reader xong.
echo.

:: Microsoft 365
echo *** Dang cai dat Microsoft 365...
start "%SetupFolder%\setup_office.exe" 
echo [OK] Microsoft 365 is installing..........
echo.

@REM :: 7. Microsoft Teams
@REM echo [7/8] Dang cai dat Microsoft Teams...
@REM start /wait "" "teams_setup.exe" /checkInstall /silent
@REM echo [OK] Microsoft Teams xong.
@REM echo.


echo ============================================================
echo   CAI DAT HOAN TAT
echo ============================================================
exit
