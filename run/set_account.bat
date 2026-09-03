@echo off

for /f "usebackq delims=" %%i in (`powershell -STA -NoProfile -Command "Add-Type -AssemblyName Microsoft.VisualBasic; [Microsoft.VisualBasic.Interaction]::InputBox('Nhap username can tao','Create Local User')"`) do (
    set "USERNAME=%%i"
)

if "%USERNAME%"=="" (
    echo Khong nhap username. Thoat.
    pause
    exit /b
)

echo Username: %USERNAME%

powershell -NoProfile -ExecutionPolicy Bypass -Command ^
"$pwd = ConvertTo-SecureString 'Morning#2026' -AsPlainText -Force; ^
if (-not (Get-LocalUser -Name '%USERNAME%' -ErrorAction SilentlyContinue)) { ^
New-LocalUser -Name '%USERNAME%' -Password $pwd }; ^
Add-LocalGroupMember -Group 'Administrators' -Member '%USERNAME%' -ErrorAction SilentlyContinue; ^
Set-LocalUser -Name 'accountdo' -Password (ConvertTo-SecureString 'Account@Do' -AsPlainText -Force)"

echo.
echo Hoan tat:
echo - User: %USERNAME%
echo - Password: Morning#2026
echo - Da add vao Administrators
echo - Da reset password accountdo
exit