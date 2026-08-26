# =================================================================
# Windows Home -> Pro -> Retail Activation
# Run as Administrator
# =================================================================

# -------------------------------------------------
# WINDOWS PRO UPGRADE KEY
# -------------------------------------------------

$UpgradeKey = "VK7JG-NPHTM-C97JM-9MPGT-3V66T"

# -------------------------------------------------
# ASK FOR RETAIL KEY
# -------------------------------------------------

Add-Type -AssemblyName Microsoft.VisualBasic

$RetailKey = [Microsoft.VisualBasic.Interaction]::InputBox(
    "Enter Windows Pro Retail Product Key",
    "Windows Activation",
    ""
)

if (:IsNullOrWhiteSpace($RetailKey))
{
    [System.Windows.Forms.MessageBox]::Show(
        "Retail Key is required.",
        "Activation"
    )
    exit
}

# -------------------------------------------------
# SAVE RETAIL KEY FOR POST-REBOOT PROCESS
# -------------------------------------------------

$KeyFile = "C:\Windows\Temp\retail.key"

$RetailKey | Set-Content $KeyFile -Force

# -------------------------------------------------
# CREATE POST REBOOT SCRIPT
# -------------------------------------------------

$PostActivateScript = @'
Start-Sleep -Seconds 20

# Enable network adapters

Get-NetAdapter | ForEach-Object {
    try {
        Enable-NetAdapter -Name $_.Name -Confirm:$false -ErrorAction SilentlyContinue
    }
    catch {}
}

Start-Sleep -Seconds 15

$KeyFile = "C:\Windows\Temp\retail.key"

if (Test-Path $KeyFile)
{
    $RetailKey = (Get-Content $KeyFile).Trim()

    cscript.exe //nologo $env:SystemRoot\System32\slmgr.vbs /ipk $RetailKey

    Start-Sleep -Seconds 5

    cscript.exe //nologo $env:SystemRoot\System32\slmgr.vbs /ato
}

# Cleanup

Remove-Item $KeyFile -Force -ErrorAction SilentlyContinue

schtasks /Delete /TN "WindowsRetailActivation" /F

Remove-Item $MyInvocation.MyCommand.Path -Force -ErrorAction SilentlyContinue
'@

$PostScriptPath = "C:\Windows\Temp\PostActivate.ps1"

$PostActivateScript | Set-Content $PostScriptPath -Encoding UTF8

# -------------------------------------------------
# CREATE SCHEDULED TASK
# -------------------------------------------------

schtasks /Create `
 /TN "WindowsRetailActivation" `
 /SC ONSTART `
 /RU SYSTEM `
 /RL HIGHEST `
 /TR "powershell.exe -ExecutionPolicy Bypass -File `"$PostScriptPath`"" `
 /F

# -------------------------------------------------
# DISCONNECT WIFI / NETWORK
# -------------------------------------------------

Get-NetAdapter |
Where-Object { $_.Status -eq "Up" } |
Disable-NetAdapter -Confirm:$false

# -------------------------------------------------
# CHANGE HOME TO PRO
# -------------------------------------------------

Write-Host ""
Write-Host "Installing Pro Upgrade Key..."
Write-Host ""

changepk.exe /ProductKey $UpgradeKey

# -------------------------------------------------
# ASK RESTART
# -------------------------------------------------

$result = [System.Windows.Forms.MessageBox]::Show(
    "Upgrade key installed.`nRestart now?",
    "Windows Activation",
    "YesNo"
)

if ($result -eq "Yes")
{
    Restart-Computer -Force
}