#Requires -RunAsAdministrator

Add-Type -AssemblyName Microsoft.VisualBasic
Add-Type -AssemblyName System.Windows.Forms

# =====================================================
# CONFIG
# =====================================================

$UpgradeKey = "VK7JG-NPHTM-C97JM-9MPGT-3V66T"

$TempFolder = "$env:windir\Temp"
$KeyFile    = Join-Path $TempFolder "RetailKey.dat"
$PostScript = Join-Path $TempFolder "PostUpgrade.ps1"
$LogFile    = Join-Path $TempFolder "EditionUpgrade.log"

# Dùng Common Startup để chạy bất kể user nào đăng nhập trước
$StartupFolder   = [Environment]::GetFolderPath('CommonStartup')
$StartupShortcut = Join-Path $StartupFolder "PostUpgrade.lnk"

Start-Transcript -Path $LogFile -Force

# =====================================================
# INPUT PRODUCT KEY
# =====================================================

$RetailKey = [Microsoft.VisualBasic.Interaction]::InputBox(
    "Enter Windows Pro Retail Product Key",
    "Windows Activation",
    ""
)

if ([string]::IsNullOrWhiteSpace($RetailKey))
{
    [System.Windows.Forms.MessageBox]::Show(
        "Retail Product Key is required.",
        "Windows Activation"
    )

    Stop-Transcript
    exit
}

# =====================================================
# SAVE PRODUCT KEY
# =====================================================

$RetailKey |
ConvertTo-SecureString -AsPlainText -Force |
ConvertFrom-SecureString |
Set-Content $KeyFile -Force

# =====================================================
# CREATE POST BOOT SCRIPT
# =====================================================

$PostBootContent = @"
# ---- Tu nang quyen (Run as Administrator) neu chua co ----
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator))
{
    Start-Process powershell.exe -ArgumentList '-ExecutionPolicy Bypass -WindowStyle Hidden -File "`$PSCommandPath"' -Verb RunAs
    exit
}

`$KeyFile         = "$KeyFile"
`$StartupShortcut = "$StartupShortcut"

Start-Sleep -Seconds 20

try
{
    Write-Output "Enabling network adapters..."

    Get-NetAdapter -Physical -ErrorAction SilentlyContinue |
    ForEach-Object {

        Enable-NetAdapter `
            -Name `$_.Name `
            -Confirm:`$false `
            -ErrorAction SilentlyContinue
    }

    Start-Sleep -Seconds 10

    Write-Output "Waiting for internet connection..."

    `$Timeout = 120
    `$Elapsed = 0

    while (
        -not (Test-NetConnection microsoft.com -InformationLevel Quiet) `
        -and (`$Elapsed -lt `$Timeout)
    )
    {
        Start-Sleep -Seconds 5
        `$Elapsed += 5
    }

    if (`$Elapsed -lt `$Timeout)
    {
        Write-Output "Internet connection detected."
    }
    else
    {
        Write-Output "Internet connection timeout."
    }

    if (Test-Path `$KeyFile)
    {
        `$SecureKey = Get-Content `$KeyFile -Raw |
                      ConvertTo-SecureString

        `$RetailKey = [System.Net.NetworkCredential]::new(
            "",
            `$SecureKey
        ).Password

        `$Slmgr = "`$env:SystemRoot\System32\slmgr.vbs"

        cscript.exe //nologo `$Slmgr /ipk `$RetailKey

        Start-Sleep -Seconds 5

        cscript.exe //nologo `$Slmgr /ato
    }
}
catch
{
    Write-Output `$_.Exception.Message

    Write-EventLog `
        -LogName Application `
        -Source "Windows Error Reporting" `
        -EntryType Error `
        -EventId 1000 `
        -Message `$_.Exception.Message `
        -ErrorAction SilentlyContinue
}
finally
{
    Remove-Item `$KeyFile -Force -ErrorAction SilentlyContinue
    Remove-Item `$StartupShortcut -Force -ErrorAction SilentlyContinue
    Remove-Item `$MyInvocation.MyCommand.Path -Force -ErrorAction SilentlyContinue
}

"@

$PostBootContent |
Set-Content `
    -Path $PostScript `
    -Encoding UTF8 `
    -Force

# =====================================================
# TAO SHORTCUT TRONG STARTUP FOLDER
# (thay the Scheduled Task - tu chay khi dang nhap, tu xoa sau khi xong)
# =====================================================

if (Test-Path $StartupShortcut)
{
    Remove-Item $StartupShortcut -Force -ErrorAction SilentlyContinue
}

$WshShell = New-Object -ComObject WScript.Shell
$Shortcut = $WshShell.CreateShortcut($StartupShortcut)
$Shortcut.TargetPath       = "$env:SystemRoot\System32\WindowsPowerShell\v1.0\powershell.exe"
$Shortcut.Arguments        = "-ExecutionPolicy Bypass -WindowStyle Hidden -File `"$PostScript`""
$Shortcut.WorkingDirectory = $TempFolder
$Shortcut.WindowStyle      = 7   # Minimized
$Shortcut.Description      = "Post-upgrade activation task"
$Shortcut.Save()

# =====================================================
# CHECK WINDOWS EDITION
# =====================================================

$Edition = (
    Get-ItemProperty `
        "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion"
).EditionID

Write-Host ""
Write-Host "Current Edition : $Edition"
Write-Host ""

# =====================================================
# DISABLE NETWORK BEFORE UPGRADE
# =====================================================

Write-Host "Disabling physical network adapters..."

Get-NetAdapter -Physical -ErrorAction SilentlyContinue |
Where-Object Status -ne "Disabled" |
ForEach-Object {

    Disable-NetAdapter `
        -Name $_.Name `
        -Confirm:$false `
        -ErrorAction SilentlyContinue
}

Start-Sleep -Seconds 5

# =====================================================
# UPGRADE HOME -> PRO
# =====================================================

if ($Edition -eq "Core")
{
    Write-Host ""
    Write-Host "Upgrading Windows Home to Pro..."
    Write-Host ""

    Start-Process `
        -FilePath "changepk.exe" `
        -ArgumentList "/ProductKey $UpgradeKey" `
        -Wait
}
else
{
    Write-Host ""
    Write-Host "Windows is already Pro or higher."
    Write-Host ""
}

# =====================================================
# RESTART PROMPT
# =====================================================

$result = [System.Windows.Forms.MessageBox]::Show(
    "Upgrade completed.`r`n`r`nRestart now?",
    "Windows Activation",
    [System.Windows.Forms.MessageBoxButtons]::YesNo,
    [System.Windows.Forms.MessageBoxIcon]::Question
)

Stop-Transcript

# if ($result -eq [System.Windows.Forms.DialogResult]::Yes)
# {
#     Restart-Computer -Force
# }