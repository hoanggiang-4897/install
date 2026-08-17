# install
### RUN SETUP MACHINE SCRIPT ###

Invoke-WebRequest -Uri "https://raw.githubusercontent.com/hoanggiang-4897/install/refs/heads/main/initiate_Setup.bat" -Outfile "$env:TEMP\initiate_Setup.bat"; Start-Process "$env:TEMP\initiate_Setup.bat" -wait ; remove-item -path "$env:TEMP\get_infor.vbs" -force

#command retrieve machine's system information#

***Command Prompt

curl -s -o "%TEMP%\get_infor.bat" "https://raw.githubusercontent.com/hoanggiang-4897/install/main/get_infor.vbs" && call "%TEMP%\get_infor.vbs"

***Powershell

Invoke-RestMethod -Uri "https://raw.githubusercontent.com/hoanggiang-4897/install/main/get_infor.vbs" -OutFile "$env:TEMP\get_infor.vbs"; cscript //nologo "$env:TEMP\get_infor.vbs"
