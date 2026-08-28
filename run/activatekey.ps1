#Requires -RunAsAdministrator

Add-Type -AssemblyName Microsoft.VisualBasic
Add-Type -AssemblyName System.Windows.Forms

# =====================================================
# CONFIG
# =====================================================

$UpgradeKey = "VK7JG-NPHTM-C97JM-9MPGT-3V66T"

$TempFolder = "$env:windir\Temp"
$KeyFile = Join-Path $TempFolder "retail.key"
$PostScript = Join-Path $TempFolder "PostActivate.ps1"
$LogFile = Join-Path $TempFolder "Activation.log"

$TaskName = "WindowsRetailActivation"

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
Start-Sleep -Seconds 20

`$KeyFile = '$KeyFile'

try
{
    # Wait network max 60 sec

    `$Timeout = 60
    `$Elapsed = 0

    while (
        -not (Test-NetConnection microsoft.com -InformationLevel Quiet) `
        -and (`$Elapsed -lt `$Timeout)
    )
    {
        Start-Sleep -Seconds 5
        `$Elapsed += 5
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
    Write-EventLog `
        -LogName Application `
        -Source "Windows Error Reporting" `
        -EntryType Error `
        -EventId 1000 `
        -Message `$_.Exception.Message `
        -ErrorAction SilentlyContinue
}

Remove-Item `$KeyFile -Force -ErrorAction SilentlyContinue

try
{
    Unregister-ScheduledTask `
        -TaskName '$TaskName' `
        -Confirm:`$false `
        -ErrorAction SilentlyContinue
}
catch {}

Remove-Item `$MyInvocation.MyCommand.Path `
    -Force `
    -ErrorAction SilentlyContinue
"@

$PostBootContent |
Set-Content `
    -Path $PostScript `
    -Encoding UTF8 `
    -Force

# =====================================================
# CREATE SCHEDULED TASK
# =====================================================

try
{
    Unregister-ScheduledTask `
        -TaskName $TaskName `
        -Confirm:$false `
        -ErrorAction SilentlyContinue
}
catch {}

$Action = New-ScheduledTaskAction `
    -Execute "powershell.exe" `
    -Argument "-ExecutionPolicy Bypass -WindowStyle Hidden -File `"$PostScript`""

$Trigger = New-ScheduledTaskTrigger -AtStartup

Register-ScheduledTask `
    -TaskName $TaskName `
    -Action $Action `
    -Trigger $Trigger `
    -User "SYSTEM" `
    -RunLevel Highest `
    -Force | Out-Null

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
# UPGRADE HOME => PRO
# =====================================================

if ($Edition -eq "Core")
{
    Write-Host "Upgrading Windows Home to Pro..."

    Start-Process `
        -FilePath "changepk.exe" `
        -ArgumentList "/ProductKey $UpgradeKey" `
        -Wait
}
else
{
    Write-Host "Windows is already Pro or higher."
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

if ($result -eq [System.Windows.Forms.DialogResult]::Yes)
{
    Restart-Computer -Force
}

