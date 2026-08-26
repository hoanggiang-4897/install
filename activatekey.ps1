# ============================================================
# Windows Home -> Pro Upgrade and Activation
# Run as Administrator
# ============================================================

Add-Type -AssemblyName Microsoft.VisualBasic
Add-Type -AssemblyName System.Windows.Forms

# ----------------------------
# CONFIGURATION
# ----------------------------

# Generic Pro upgrade key
$GenericUpgradeKey = "VK7JG-NPHTM-C97JM-9MPGT-3V66T"

$TaskName  = "WindowsActivationContinue"
$ScriptPath = $MyInvocation.MyCommand.Path
$KeyFile   = "$env:ProgramData\RetailKey.txt"

# ----------------------------
# STAGE 2 (AFTER REBOOT)
# ----------------------------

if ($args -contains "Continue") {

    Write-Host "Post-reboot phase started..." -ForegroundColor Cyan

    if (-not (Test-Path $KeyFile)) {
        Write-Host "Retail key file not found." -ForegroundColor Red
        exit 1
    }

    $RetailKey = (Get-Content $KeyFile -Raw).Trim()

    Write-Host "Installing retail key..." -ForegroundColor Yellow

    cscript.exe "$env:SystemRoot\System32\slmgr.vbs" /ipk $RetailKey

    Start-Sleep -Seconds 5

    Write-Host "Activating Windows..." -ForegroundColor Yellow

    cscript.exe "$env:SystemRoot\System32\slmgr.vbs" /ato

    Start-Sleep -Seconds 5

    Write-Host "Removing scheduled task..." -ForegroundColor Yellow

    Unregister-ScheduledTask `
        -TaskName $TaskName `
        -Confirm:$false `
        -ErrorAction SilentlyContinue

    Remove-Item $KeyFile -Force -ErrorAction SilentlyContinue

    [System.Windows.Forms.MessageBox]::Show(
        "Activation process completed.",
        "Completed",
        [System.Windows.Forms.MessageBoxButtons]::OK,
        [System.Windows.Forms.MessageBoxIcon]::Information
    ) | Out-Null

    Write-Host "Completed." -ForegroundColor Green
    exit
}

# ----------------------------
# STAGE 1 (BEFORE REBOOT)
# ----------------------------

$RetailKey = [Microsoft.VisualBasic.Interaction]::InputBox(
    "Enter Retail Product Key",
    "Windows Pro Activation",
    ""
)

if (:IsNullOrWhiteSpace($RetailKey)) {
    Write-Host "Retail key is required." -ForegroundColor Red
    exit 1
}

# Save key for use after reboot
$RetailKey | Set-Content $KeyFile -Encoding ASCII

Write-Host "Disconnecting Wi-Fi..." -ForegroundColor Cyan

try {
    Get-NetAdapter |
        Where-Object { $_.Status -eq "Up" } |
        Disable-NetAdapter -Confirm:$false
}
catch {
    Write-Warning "Could not disable network adapters."
}

Write-Host "Creating resume task..." -ForegroundColor Cyan

$Action = New-ScheduledTaskAction `
    -Execute "powershell.exe" `
    -Argument "-ExecutionPolicy Bypass -File `"$ScriptPath`" Continue"

$Trigger = New-ScheduledTaskTrigger -AtLogOn

Register-ScheduledTask `
    -TaskName $TaskName `
    -Action $Action `
    -Trigger $Trigger `
    -RunLevel Highest `
    -Force | Out-Null

Write-Host "Installing Pro upgrade key..." -ForegroundColor Cyan

cscript.exe "$env:SystemRoot\System32\slmgr.vbs" /ipk $GenericUpgradeKey

Start-Sleep -Seconds 5

$result = [System.Windows.Forms.MessageBox]::Show(
    "The Pro upgrade key has been installed.`n`nRestart now?",
    "Restart Required",
    [System.Windows.Forms.MessageBoxButtons]::YesNo,
    [System.Windows.Forms.MessageBoxIcon]::Question
)

if ($result -eq [System.Windows.Forms.DialogResult]::Yes) {

    Write-Host "Restarting computer..." -ForegroundColor Yellow
    Restart-Computer -Force

}
else {

    Write-Host "Restart cancelled by user." -ForegroundColor Yellow

    [System.Windows.Forms.MessageBox]::Show(
        "Please restart Windows manually later to continue activation.",
        "Restart Pending",
        [System.Windows.Forms.MessageBoxButtons]::OK,
        [System.Windows.Forms.MessageBoxIcon]::Warning
    ) | Out-Null
}