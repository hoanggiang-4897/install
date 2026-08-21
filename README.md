# Install

the script will set up machine includes:
1. change hostname
2. download apps
- chrome
- Ultra view
- 7zip
- unikey
- office 365 setup
- foxit reader







--------------------------------------------------------------------------------------------------
# RUN SETUP MACHINE SCRIPT

Invoke-WebRequest -Uri "https://raw.githubusercontent.com/hoanggiang-4897/install/refs/heads/main/initiate_Setup.bat" -Outfile "$env:TEMP\initiate_Setup.bat"; Start-Process "$env:TEMP\initiate_Setup.bat" -wait ; remove-item -path "$env:TEMP\initiate_Setup.bat" -force

--------------------------------------------------------------------------------------------------
# Command retrieve machine's system information

***Command Prompt

curl -s -o "%TEMP%\get_infor.bat" "https://raw.githubusercontent.com/hoanggiang-4897/install/main/get_infor.vbs" && call "%TEMP%\get_infor.vbs"

***Powershell

Invoke-RestMethod -Uri "https://raw.githubusercontent.com/hoanggiang-4897/install/main/get_infor.vbs" -OutFile "$env:TEMP\get_infor.vbs"; cscript //nologo "$env:TEMP\get_infor.vbs"

--------------------------------------------------------------------------------------------------
# PRINTER SETUP

driver link: https://support.ricoh.com/bb/html/dr_ut_e/rc3/model/mpc4504ex/mpc4504ex.htm

Invoke-WebRequest -Uri "https://raw.githubusercontent.com/hoanggiang-4897/install/refs/heads/main/addprinter.bat" -Outfile "$env:TEMP\addprinter.bat"; Start-Process "$env:TEMP\addprinter.bat" -wait ; remove-item -path "$env:TEMP\addprinter.bat" -force

--------------------------------------------------------------------------------------------------
# SCAN SETUP - run script with powershell

Invoke-WebRequest -Uri "https://raw.githubusercontent.com/hoanggiang-4897/install/refs/heads/main/Setup_Scan.bat" -Outfile "$env:TEMP\Setup_Scan.bat"; Start-Process "$env:TEMP\Setup_Scan.bat"


