# Install

## setup note
1. activatekey_hostname.ps1 - run activatekey and change hostname.
2. download_apps.bat - download and install all company apps.
3. add_printer.bat - add current printer.
4. update_infor.vbs - update the machine and user information and send email


the script will set up machine includes:
step 1. change hostname
step 2. download apps
1. chrome
2. Ultra view
3. 7zip
4. unikey
5. office 365 setup
6. foxit reader

# Powershell (admin) command to Run master script to call all sub scripts.

Invoke-WebRequest -Uri "https://raw.githubusercontent.com/hoanggiang-4897/install/refs/heads/main/run/setup.bat" -Outfile "$env:TEMP\setup.bat"; Start-Process "$env:TEMP\setup.bat" -wait ; remove-item -path "$env:TEMP\setup.bat" -force


--------------------------------------------------------------------------------------------------
# Individual commands
--------------------------------------------------------------------------------------------------
# Powershell command to run download_apps.bat

Invoke-WebRequest -Uri "https://raw.githubusercontent.com/hoanggiang-4897/install/refs/heads/main/run/download_apps.bat" -Outfile "$env:TEMP\download_apps.bat"; Start-Process "$env:TEMP\download_apps.bat" -wait ; remove-item -path "$env:TEMP\download_apps.bat" -force

--------------------------------------------------------------------------------------------------
# Command to retrieve machine's system information

Invoke-RestMethod -Uri "https://raw.githubusercontent.com/hoanggiang-4897/install/refs/heads/main/run/update_infor.vbs" -OutFile "$env:TEMP\update_infor.vbs"; cscript //nologo "$env:TEMP\update_infor.vbs"

--------------------------------------------------------------------------------------------------
# PRINTER SETUP

driver link: https://support.ricoh.com/bb/html/dr_ut_e/rc3/model/mpc4504ex/mpc4504ex.htm

Invoke-WebRequest -Uri "https://raw.githubusercontent.com/hoanggiang-4897/install/refs/heads/main/run/add_printer.bat" -Outfile "$env:TEMP\add_printer.bat"; Start-Process "$env:TEMP\add_printer.bat" -wait ; remove-item -path "$env:TEMP\add_printer.bat" -force

--------------------------------------------------------------------------------------------------
# SCAN SETUP - run script with powershell - hold on

Invoke-WebRequest -Uri "https://raw.githubusercontent.com/hoanggiang-4897/install/refs/heads/main/Setup_Scan.bat" -Outfile "$env:TEMP\Setup_Scan.bat"; Start-Process "$env:TEMP\Setup_Scan.bat"


