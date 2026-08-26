#Requires -RunAsAdministrator

Add-Type -AssemblyName Microsoft.VisualBasic
Add-Type -AssemblyName System.Windows.Forms

# =====================================================
# CONFIG
# =====================================================

# Windows Pro Upgrade Key
$UpgradeKey = "VK7JG-NPHTM-C97JM-9MPGT-3V66T"

$KeyFile = "C:\Windows\Temp\retail.key"
$PostScript = "C:\Windows\Temp\PostActivate.ps1"
$TaskName = "WindowsRetailActivation"

# =====================================================
# INPUT RETAIL KEY
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

    exit
}

# =====================================================
# SAVE KEY
# =====================================================

$RetailKey | Set-Content -Path $KeyFile -Force

# =====================================================
# CREATE POST-BOOT SCRIPT
# =====================================================

$PostBootContent = @'
Start-Sleep -Seconds 30

# Enable Wi-Fi

netsh interface set interface name="Wi-Fi" admin=enable

# Enable all adapters

Get-NetAdapter | ForEach-Object {
    try {
        Enable-NetAdapter -Name $_.Name -Confirm:$false -ErrorAction SilentlyContinue
    }
    catch {
    }
}

Start-Sleep -Seconds 15

$KeyFile = "C:\Windows\Temp\retail.key"

if (Test-Path $KeyFile)
{
    $RetailKey = (Get-Content $KeyFile -Raw).Trim()

    cscript.exe //nologo "$env:SystemRoot\System32\slmgr.vbs" /ipk $RetailKey

    Start-Sleep -Seconds 10

    cscript.exe //nologo "$env:SystemRoot\System32\slmgr.vbs" /ato
}

Remove-Item $KeyFile -Force -ErrorAction SilentlyContinue

schtasks /Delete /TN "WindowsRetailActivation" /F

Remove-Item $MyInvocation.MyCommand.Path -Force -ErrorAction SilentlyContinue
'@


$PostBootContent | Set-Content `
    -Path $PostScript `
    -Encoding UTF8 `
    -Force

# =====================================================
# CREATE SCHEDULED TASK
# =====================================================

schtasks /Create `
 /TN $TaskName `
 /SC ONSTART `
 /RU SYSTEM `
 /RL HIGHEST `
 /TR "powershell.exe -ExecutionPolicy Bypass -WindowStyle Hidden -File `"$PostScript`"" `
 /F

# =====================================================
# DISCONNECT NETWORK
# =====================================================

Get-NetAdapter |
Where-Object {$_.Status -eq "Up"} |
ForEach-Object {
    try {
        Disable-NetAdapter `
            -Name $_.Name `
            -Confirm:$false `
            -ErrorAction SilentlyContinue
    }
    catch {
    }
}

# =====================================================
# CHANGE HOME -> PRO
# =====================================================

Write-Host ""
Write-Host "Changing Windows Edition..."
Write-Host ""

Start-Process `
    -FilePath "changepk.exe" `
    -ArgumentList "/ProductKey $UpgradeKey" `
    -Wait

# =====================================================
# CHANGE HOSTNAME
# =====================================================

try
{
    $Serial = (Get-CimInstance Win32_BIOS).SerialNumber.Trim()
}
catch
{
    $Serial = ""
}

if ([string]::IsNullOrWhiteSpace($Serial))
{
    $Serial = Get-Random -Minimum 10000 -Maximum 99999
}

# Loại bỏ ký tự không hợp lệ trong hostname
$Serial = $Serial -replace '[^A-Za-z0-9]', ''

$NewHostName = "VNHCM$Serial"

Write-Host ""
Write-Host "Current Hostname : $env:COMPUTERNAME"
Write-Host "New Hostname     : $NewHostName"
Write-Host ""

if ($env:COMPUTERNAME -ne $NewHostName)
{
    try
    {
        Rename-Computer -NewName $NewHostName -Force

        Write-Host "[OK] Hostname changed to $NewHostName"
    }
    catch
    {
        Write-Host "[ERROR] Failed to rename computer."
    }
}
else
{
    Write-Host "[OK] Hostname already matches."
}

# =====================================================
# ASK FOR RESTART
# =====================================================

$result = [System.Windows.Forms.MessageBox]::Show(
    "Upgrade completed.`r`nRestart now?",
    "Windows Activation",
    [System.Windows.Forms.MessageBoxButtons]::YesNo,
    [System.Windows.Forms.MessageBoxIcon]::Question
)

if ($result -eq [System.Windows.Forms.DialogResult]::Yes)
{
    Restart-Computer -Force
}


