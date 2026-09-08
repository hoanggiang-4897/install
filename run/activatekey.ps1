#Requires -RunAsAdministrator

Add-Type -AssemblyName System.Windows.Forms

# =====================================================
# CONFIG
# =====================================================

$UpgradeKey = "VK7JG-NPHTM-C97JM-9MPGT-3V66T"

$TempFolder = "$env:windir\Temp"
# $PostScript = Join-Path $TempFolder "PostUpgrade.ps1"
# $LogFile    = Join-Path $TempFolder "EditionUpgrade.log"

# # Dùng Common Startup để chạy bất kể user nào đăng nhập trước
# $StartupFolder   = [Environment]::GetFolderPath('CommonStartup')
# $StartupShortcut = Join-Path $StartupFolder "PostUpgrade.lnk"

$WifiProfileName = $null
$WifiProfile = Get-NetConnectionProfile -ErrorAction SilentlyContinue |
    Where-Object { $_.InterfaceAlias -match 'Wi-Fi|Wireless|WLAN' } |
    Select-Object -First 1

if ($WifiProfile)
{
    $WifiProfileName = $WifiProfile.Name
}

# Start-Transcript -Path $LogFile -Force

# # =====================================================
# # CREATE POST BOOT SCRIPT
# # =====================================================

# $PostBootContent = @"
# # ---- Tu nang quyen (Run as Administrator) neu chua co ----
# if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator))
# {
#     Start-Process powershell.exe -ArgumentList '-ExecutionPolicy Bypass -WindowStyle Hidden -File "`$PSCommandPath"' -Verb RunAs
#     exit
# }

# `$StartupShortcut = "$StartupShortcut"

# Start-Sleep -Seconds 20

# try
# {
#     Write-Output "Reconnecting Wi-Fi..."

#     if (-not [string]::IsNullOrWhiteSpace("$WifiProfileName"))
#     {
#         netsh.exe wlan connect name="$WifiProfileName" | Out-Null
#     }

#     Start-Sleep -Seconds 10

#     Write-Output "Waiting for internet connection..."

#     `$Timeout = 120
#     `$Elapsed = 0

#     while (
#         -not (Test-NetConnection microsoft.com -InformationLevel Quiet) `
#         -and (`$Elapsed -lt `$Timeout)
#     )
#     {
#         Start-Sleep -Seconds 5
#         `$Elapsed += 5
#     }

#     if (`$Elapsed -lt `$Timeout)
#     {
#         Write-Output "Internet connection detected."
#     }
#     else
#     {
#         Write-Output "Internet connection timeout."
#     }

# }
# catch
# {
#     Write-Output `$_.Exception.Message

#     Write-EventLog `
#         -LogName Application `
#         -Source "Windows Error Reporting" `
#         -EntryType Error `
#         -EventId 1000 `
#         -Message `$_.Exception.Message `
#         -ErrorAction SilentlyContinue
# }
# finally
# {
#     Remove-Item `$StartupShortcut -Force -ErrorAction SilentlyContinue
#     Remove-Item `$MyInvocation.MyCommand.Path -Force -ErrorAction SilentlyContinue
# }

# "@

# $PostBootContent |
# Set-Content `
#     -Path $PostScript `
#     -Encoding UTF8 `
#     -Force

# # =====================================================
# # TAO SHORTCUT TRONG STARTUP FOLDER
# # (thay the Scheduled Task - tu chay khi dang nhap, tu xoa sau khi xong)
# # =====================================================

# if (Test-Path $StartupShortcut)
# {
#     Remove-Item $StartupShortcut -Force -ErrorAction SilentlyContinue
# }

# $WshShell = New-Object -ComObject WScript.Shell
# $Shortcut = $WshShell.CreateShortcut($StartupShortcut)
# $Shortcut.TargetPath       = "$env:SystemRoot\System32\WindowsPowerShell\v1.0\powershell.exe"
# $Shortcut.Arguments        = "-ExecutionPolicy Bypass -WindowStyle Hidden -File `"$PostScript`""
# $Shortcut.WorkingDirectory = $TempFolder
# $Shortcut.WindowStyle      = 7   # Minimized
# $Shortcut.Description      = "Post-upgrade Wi-Fi reconnect task"
# $Shortcut.Save()

# # =====================================================
# # CHECK WINDOWS EDITION
# # =====================================================

$Edition = (
    Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion"
).EditionID

# Write-Host ""
# Write-Host "Current Edition : $Edition"
# Write-Host ""

# =====================================================
# DISCONNECT WI-FI BEFORE UPGRADE
# =====================================================

Write-Host "Disconnecting Wi-Fi temporarily..."
netsh.exe wlan disconnect | Out-Null

Start-Sleep -Seconds 5

# =====================================================
# UPGRADE HOME -> PRO
# =====================================================

if ($Edition -in "Core", "CoreSingleLanguage")
{
    Write-Host ""
    Write-Host "Upgrading Windows Home to Pro..."
    Write-Host ""
    changepk.exe /ProductKey $UpgradeKey
}
else
{
    Write-Host ""
    Write-Host "Windows is already Pro or higher."
    Write-Host ""
}

# =====================================================
# RESTART PROMPT AND COUNTDOWN
# =====================================================

# function Request-Restart
# {
#     $Result = [System.Windows.Forms.MessageBox]::Show(
#         "Windows upgrade is ready.`r`n`r`nRestart now? The computer will restart after a 200-second countdown.",
#         "Windows Activation",
#         [System.Windows.Forms.MessageBoxButtons]::YesNo,
#         [System.Windows.Forms.MessageBoxIcon]::Question
#     )

#     if ($Result -ne [System.Windows.Forms.DialogResult]::Yes)
#     {
#         if (-not [string]::IsNullOrWhiteSpace($WifiProfileName))
#         {
#             Write-Host "Reconnecting Wi-Fi..."
#             netsh.exe wlan connect name="$WifiProfileName" | Out-Null
#         }

#         Write-Host "Restart cancelled. Run this script again or restart Windows manually."
#         return
#     }

#     for ($SecondsRemaining = 200; $SecondsRemaining -gt 0; $SecondsRemaining--)
#     {
#         Write-Progress `
#             -Activity "Restarting computer" `
#             -Status "$SecondsRemaining seconds remaining" `
#             -SecondsRemaining $SecondsRemaining `
#             -PercentComplete ((200 - $SecondsRemaining) / 200 * 100)

#         Start-Sleep -Seconds 1
#     }

#     Write-Progress -Activity "Restarting computer" -Completed

#     try
#     {
#         Restart-Computer -Force -ErrorAction Stop
#     }
#     catch
#     {
#         Write-Warning "Restart-Computer failed. Trying shutdown.exe..."
#         shutdown.exe /r /t 0 /f
#     }
# }

# Stop-Transcript
# Request-Restart