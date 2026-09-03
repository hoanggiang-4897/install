Option Explicit

' Tự động yêu cầu quyền Administrator nếu chưa có
If Not WScript.Arguments.Named.Exists("elevate") Then
    CreateObject("Shell.Application").ShellExecute "wscript.exe", """" & WScript.ScriptFullName & """ /elevate", "", "runas", 1
    WScript.Quit
End If

' =========================================================================
' RECIPIENT CONFIGURATION
' =========================================================================
Dim strRecipientEmail, strCcEmail
strRecipientEmail = "giang.nh@sclife.com.vn" ' Set destination email address
strCcEmail        = ""                      ' Set CC email address (e.g., "NI.hq@sclife.com.vn")

' =========================================================================
' MAIN SCRIPT
' =========================================================================
Dim objWMIService, colItems, objItem, objNetwork, objShell, cmd1, cmd2
Dim strComputer

strComputer = "."
Set objNetwork = CreateObject("WScript.Network")
Set objShell   = CreateObject("WScript.Shell")


' Câu lệnh PowerShell 1: Bật Insecure Guest Logons
cmd1 = "powershell.exe -NoProfile -ExecutionPolicy Bypass -Command ""Set-SmbClientConfiguration -EnableInsecureGuestLogons $true -Force"""

' Câu lệnh PowerShell 2: Tắt Require Security Signature
cmd2 = "powershell.exe -NoProfile -ExecutionPolicy Bypass -Command ""Set-SmbClientConfiguration -RequireSecuritySignature $false -Force"""

' Thực thi lệnh (Số 0 ở cuối giúp chạy ẩn, không hiện cửa sổ đen flash lên)
objShell.Run cmd1, 0, True
objShell.Run cmd2, 0, True

' Connect to WMI Root
On Error Resume Next
Set objWMIService = GetObject("winmgmts:\\" & strComputer & "\root\cimv2")
On Error GoTo 0

' --- 1. User Account Info ---
Dim strLogonAccount
strLogonAccount = objNetwork.UserDomain & "\" & objNetwork.UserName

' --- 2. Operating System Info (Win32_OperatingSystem) ---
Dim strOSName, strOSVersion, strOSDescription, strOSManufacturer
Dim strWinDir, strSysDir, strLocale, strTimeZone
Dim strTotalRAM, strAvailRAM, strTotalVirtual, strAvailVirtual, strPageFileSize, strPageFilePath

On Error Resume Next
Set colItems = objWMIService.ExecQuery("SELECT Caption, Version, BuildNumber, Description, Manufacturer, WindowsDirectory, SystemDirectory, MUILanguages, TotalVisibleMemorySize, FreePhysicalMemory, TotalVirtualMemorySize, FreeVirtualMemory, SizeStoredInPagingFiles FROM Win32_OperatingSystem")
For Each objItem In colItems
    strOSName        = Split(objItem.Caption, "(")(0)
    strOSVersion     = objItem.Version & " Build " & objItem.BuildNumber
    strOSDescription = objItem.Description
    If strOSDescription = "" Then strOSDescription = "Not Available"
    strOSManufacturer= objItem.Manufacturer
    strWinDir        = objItem.WindowsDirectory
    strSysDir        = objItem.SystemDirectory
    strLocale        = objItem.MUILanguages(0)
    
    ' Memory Breakdown
    strTotalRAM     = Round(CDbl(objItem.TotalVisibleMemorySize) / (1024 * 1024), 2) & " GB"
    strAvailRAM     = Round(CDbl(objItem.FreePhysicalMemory) / (1024 * 1024), 2) & " GB"
    strTotalVirtual = Round(CDbl(objItem.TotalVirtualMemorySize) / (1024 * 1024), 2) & " GB"
    strAvailVirtual = Round(CDbl(objItem.FreeVirtualMemory) / (1024 * 1024), 2) & " GB"
    strPageFileSize = Round(CDbl(objItem.SizeStoredInPagingFiles) / (1024 * 1024), 2) & " GB"
    Exit For
Next
On Error GoTo 0

' Time Zone
On Error Resume Next
Set colItems = objWMIService.ExecQuery("SELECT Caption FROM Win32_TimeZone")
For Each objItem In colItems
    strTimeZone = objItem.Caption
    Exit For
Next
On Error GoTo 0

' Page File Location
On Error Resume Next
Set colItems = objWMIService.ExecQuery("SELECT Name FROM Win32_PageFileSetting")
For Each objItem In colItems
    strPageFilePath = objItem.Name
    Exit For
Next
If strPageFilePath = "" Then strPageFilePath = "C:\pagefile.sys"
On Error GoTo 0

' --- 3. System & Hardware Info (Win32_ComputerSystem) ---
Dim strSystemName, strSysManufacturer, strSysModel, strSysType, strSysSKU, strInstalledRAM, strRole, strHypervisor

On Error Resume Next
Set colItems = objWMIService.ExecQuery("SELECT Name, Manufacturer, Model, SystemType, SystemSKUNumber, TotalPhysicalMemory, PCSystemType, HypervisorPresent FROM Win32_ComputerSystem")
For Each objItem In colItems
    strSystemName      = objItem.Name
    strSysManufacturer = objItem.Manufacturer
    strSysModel        = objItem.Model
    strSysType         = objItem.SystemType
    strSysSKU          = objItem.SystemSKUNumber
    strInstalledRAM    = Round(CDbl(objItem.TotalPhysicalMemory) / (1024 * 1024 * 1024), 2) & " GB"
    strRole            = GetPlatformRole(objItem.PCSystemType)
    strHypervisor      = objItem.HypervisorPresent
    Exit For
Next
On Error GoTo 0

' --- 4. Processor & HAL Info ---
Dim strProcessor, strHALVersion
On Error Resume Next
Set colItems = objWMIService.ExecQuery("SELECT Name, MaxClockSpeed, NumberOfCores, NumberOfLogicalProcessors FROM Win32_Processor")
For Each objItem In colItems
    strProcessor = Trim(objItem.Name) & ", " & objItem.MaxClockSpeed & " Mhz, " & _
                   objItem.NumberOfCores & " Core(s), " & _
                   objItem.NumberOfLogicalProcessors & " Logical Processor(s)"
    Exit For
Next
On Error GoTo 0

strHALVersion = GetHALVersion()

' --- 5. BIOS Info (Win32_BIOS) ---
Dim strBIOSVersion, strSMBIOSVersion, strECVersion, strBIOSSerial, strBIOSMode, strSecureBoot

On Error Resume Next
Set colItems = objWMIService.ExecQuery("SELECT Manufacturer, SMBIOSBIOSVersion, ReleaseDate, SMBIOSMajorVersion, SMBIOSMinorVersion, EmbeddedControllerMajorVersion, EmbeddedControllerMinorVersion, SerialNumber FROM Win32_BIOS")
For Each objItem In colItems
    strBIOSVersion   = objItem.Manufacturer & " " & objItem.SMBIOSBIOSVersion & ", " & ConvertWMIDate(objItem.ReleaseDate)
    strSMBIOSVersion = objItem.SMBIOSMajorVersion & "." & objItem.SMBIOSMinorVersion
    strECVersion     = objItem.EmbeddedControllerMajorVersion & "." & objItem.EmbeddedControllerMinorVersion
    strBIOSSerial    = Trim(objItem.SerialNumber)
    Exit For
Next
On Error GoTo 0

strBIOSMode   = GetRegistryValue("HKLM\System\CurrentControlSet\Control\SecureBoot\State\UEFI", "UEFI", "Legacy / Unknown")
strSecureBoot = GetSecureBootState()

' --- 6. BaseBoard Info ---
Dim strBoardManufacturer, strBoardProduct, strBoardVersion

On Error Resume Next
Set colItems = objWMIService.ExecQuery("SELECT Manufacturer, Product, Version FROM Win32_BaseBoard")
For Each objItem In colItems
    strBoardManufacturer = objItem.Manufacturer
    strBoardProduct      = objItem.Product
    strBoardVersion      = objItem.Version
    If strBoardVersion = "" Then strBoardVersion = "Not Defined"
    Exit For
Next
On Error GoTo 0

' --- 7. Security, DMA, VBS & App Control Statuses ---
Dim strKernelDMA, strVBSStatus, strVBSReq, strVBSAvail, strVBSSec, strAppControl, strAppControlUser, strSMMIsolation

strKernelDMA      = GetRegDWORD("HKLM\SYSTEM\CurrentControlSet\Control\DmaSecurity\AllowedBuses", "On", "Off")
strVBSStatus      = GetRegDWORD("HKLM\SYSTEM\CurrentControlSet\Control\DeviceGuard\EnableVirtualizationBasedSecurity", "Running", "Disabled")
strVBSReq         = "Base Virtualization Support"
strVBSAvail       = "Base Virtualization Support, DMA Protection, UEFI Code Readonly, SMM Security"
strVBSSec         = "Hypervisor enforced Code Integrity, Secure Launch, SMM Firmware Measurement"
strAppControl     = GetRegDWORD("HKLM\SYSTEM\CurrentControlSet\Control\CI\Policy\SKUPolicyRequired", "Enforced", "Disabled")
strAppControlUser = GetRegDWORD("HKLM\SYSTEM\CurrentControlSet\Control\CI\Policy\UserPolicyRequired", "Enforced", "Disabled")
strSMMIsolation   = "Firmware Protection Version Three"

' --- 8. Boot Device & Windows Product Key ---
Dim strBootDevice, strProductKey
On Error Resume Next
Set colItems = objWMIService.ExecQuery("SELECT BootDevice FROM Win32_OperatingSystem")
For Each objItem In colItems
    strBootDevice = objItem.BootDevice
    Exit For
Next
On Error GoTo 0

strProductKey = GetWindowsProductKey()

' =========================================================================
' ASSEMBLE REPORT & OPEN NEW OUTLOOK
' =========================================================================
Dim strSubject, strBody
strSubject = "Full System Information Audit - " & strSystemName


' ============================================================================
' get user mailbox
' ============================================================================
Dim strOutlookEmail, strLocalusers
' 5. Outlook Email Address (if configured)
strOutlookEmail = GetOutlookEmail()
strLocalusers = GetLocalUsersInfo()

strBody =   "=== System Information ===" & vbCrLf & vbCrLf & _
            "BIOS Serial Number: " & strBIOSSerial & vbCrLf & _
            "Email address: " & strOutlookEmail & vbCrLf & _
            "OS Name: " & strOSName & vbCrLf & _
            "Version: " & strOSVersion & vbCrLf & _
            "OS Manufacturer: " & strOSManufacturer & vbCrLf & _
            "System Name: " & strSystemName & vbCrLf & _
            "System Manufacturer: " & strSysManufacturer & vbCrLf & _
            "System Model: " & strSysModel & vbCrLf & _
            "System Type: " & strSysType & vbCrLf & _
            "System SKU: " & strSysSKU & vbCrLf & _
            "Processor: " & strProcessor & vbCrLf & _
            "Installed Physical Memory (RAM): " & strInstalledRAM & vbCrLf & _
            "Total Physical Memory: " & strTotalRAM & vbCrLf & _
            "Available Physical Memory: " & strAvailRAM & vbCrLf & _
            "Total Virtual Memory: " & strTotalVirtual & vbCrLf & _
            "Available Virtual Memory: " & strAvailVirtual & vbCrLf & _
            "BIOS Version/Date: " & strBIOSVersion & vbCrLf & _
            "SMBIOS Version: " & strSMBIOSVersion & vbCrLf & _
            "Embedded Controller Version: " & strECVersion & vbCrLf & _
            "Locale: " & strLocale & vbCrLf & _
            "Hardware Abstraction Layer: " & strHALVersion & vbCrLf & _
            "User Name: " & strLocalusers & vbCrLf & _
            "Time Zone: " & strTimeZone & vbCrLf & _
            "Windows Product Key: " & strProductKey & vbCrLf & _
            "Report Time: " & Now()
            
            '------------------------------------------------------------------
            ' "Other OS Description: " & strOSDescription & vbCrLf & _
            ' "BIOS Mode: " & strBIOSMode & vbCrLf & _
            ' "BaseBoard Manufacturer: " & strBoardManufacturer & vbCrLf & _
            ' "BaseBoard Product: " & strBoardProduct & vbCrLf & _
            ' "BaseBoard Version: " & strBoardVersion & vbCrLf & _
            ' "Platform Role: " & strRole & vbCrLf & _
            ' "Secure Boot State: " & strSecureBoot & vbCrLf & _
            ' "Windows Directory: " & strWinDir & vbCrLf & _
            ' "System Directory: " & strSysDir & vbCrLf & _
            ' "Boot Device: " & strBootDevice & vbCrLf & _
            ' "Page File Space: " & strPageFileSize & vbCrLf & _
            ' "Page File: " & strPageFilePath & vbCrLf & _
            ' "Kernel DMA Protection: " & strKernelDMA & vbCrLf & _
            ' "Virtualization-based security: " & strVBSStatus & vbCrLf & _
            ' "VBS Required Security Props: " & strVBSReq & vbCrLf & _
            ' "VBS Available Security Props: " & strVBSAvail & vbCrLf & _
            ' "VBS Security Services Configured: " & strVBSSec & vbCrLf & _
            ' "App Control for Business policy: " & strAppControl & vbCrLf & _
            ' "App Control for Business user policy: " & strAppControlUser & vbCrLf & _
            ' "SMM Isolation Level: " & strSMMIsolation & vbCrLf & _

' Save report to network share
SaveReportToFile strBody


'=========================================================================
' Save report to local folder
'=========================================================================
Sub SaveReportToFile(strContent)
    On Error Resume Next

    Dim objFSO, objFile
    Dim strFolder, strFile, strNetServer

    Set objFSO = CreateObject("Scripting.FileSystemObject")

    ' Folder lưu report
    strNetServer = "\\VNHCMPF60MQE1"
    strFolder = ""&strNetServer&"\machine_logs"
    objShell.Run "cmd /c net use """ &strNetServer& """ /delete /y""""", 0, True
    objShell.Run "cmd /c net use """ & strFolder & """ /user:guest """"", 0, True

    ' ' Nếu chưa có folder thì tạo
    ' If Not objFSO.FolderExists(strFolder) Then
    '     objFSO.CreateFolder strFolder
    ' End If

    ' Tên file
    strFile = strFolder & "\" & _
              strSystemName & "_" & _
              Year(Now) & _
              Right("0" & Month(Now),2) & _
              Right("0" & Day(Now),2) & "_" & _
              Right("0" & Hour(Now),2) & _
              Right("0" & Minute(Now),2) & _
              Right("0" & Second(Now),2) & ".txt"

    Set objFile = objFSO.CreateTextFile(strFile, True, True)

    objFile.WriteLine strContent

    objFile.Close

    If Err.Number <> 0 Then
        WScript.Echo "Loi luu file: " & Err.Description
        Err.Clear
    End If

    Set objFile = Nothing
    Set objFSO = Nothing

    On Error GoTo 0

End Sub


Dim intResult

intResult = MsgBox( _
    "Do you want to send email to IT Department?", _
    vbYesNo + vbQuestion + vbDefaultButton2, _
    "confirm to send")

If intResult = vbYes Then
    SendViaNewOutlook strRecipientEmail, strCcEmail, strSubject, strBody
    ' MsgBox "Đang mở Outlook để tạo email.", vbInformation, "Thông báo"
Else
    ' MsgBox "Đã hủy gửi email.", vbInformation, "Thông báo"
End If


' =========================================================================
' HELPER FUNCTIONS
' =========================================================================

Sub SendViaNewOutlook(strTo, strCC, strSubj, strBodyText)
    On Error Resume Next
    Dim objFSO, strTempPath, strPSFile, objFile, strCommand
    
    Set objFSO = CreateObject("Scripting.FileSystemObject")
    strTempPath = objShell.ExpandEnvironmentStrings("%TEMP%")
    strPSFile = strTempPath & "\send_mail_temp.ps1"
    
    ' Tạo file PowerShell mã hóa theo chuẩn EscapeDataString (%20 thay vì +)
    Set objFile = objFSO.CreateTextFile(strPSFile, True, True)
    
    objFile.WriteLine "$to = '" & strTo & "'"
    objFile.WriteLine "$cc = '" & strCC & "'"
    objFile.WriteLine "$subject = '" & Replace(strSubj, "'", "''") & "'"
    objFile.WriteLine "$body = @'"
    objFile.WriteLine strBodyText
    objFile.WriteLine "'@"
    
    ' Dùng EscapeDataString để giữ nguyên khoảng trắng (%20)
    objFile.WriteLine "$encTo = [System.Uri]::EscapeDataString($to)"
    objFile.WriteLine "$encCc = [System.Uri]::EscapeDataString($cc)"
    objFile.WriteLine "$encSubj = [System.Uri]::EscapeDataString($subject)"
    objFile.WriteLine "$encBody = [System.Uri]::EscapeDataString($body)"
    
    objFile.WriteLine "if ($cc -ne '') {"
    objFile.WriteLine "    $uri = ""mailto:$($encTo)?cc=$($encCc)&subject=$($encSubj)&body=$($encBody)"""
    objFile.WriteLine "} else {"
    objFile.WriteLine "    $uri = ""mailto:$($encTo)?subject=$($encSubj)&body=$($encBody)"""
    objFile.WriteLine "}"
    objFile.WriteLine "Start-Process $uri"
    objFile.Close
    
    ' Chạy file PowerShell ẩn
    strCommand = "powershell.exe -ExecutionPolicy Bypass -NoProfile -File """ & strPSFile & """"
    objShell.Run strCommand, 0, True
    
    ' Xóa file tạm
    If objFSO.FileExists(strPSFile) Then objFSO.DeleteFile(strPSFile)
    
    If Err.Number <> 0 Then
        WScript.Echo "Loi: " & Err.Description
        Err.Clear
    ' Else
    '     WScript.Echo "Da mo New Outlook và gửi thông tin máy cho bộ phận IT. Vui long kiem tra!"
    End If
    On Error GoTo 0
End Sub

' --- Function to Retrieve Outlook Email Address ---
Function GetOutlookEmail()
    On Error Resume Next
    Dim objOutlook, objNamespace, i, strEmails
    Set objOutlook = CreateObject("Outlook.Application")
    
    If Err.Number <> 0 Then
        GetOutlookEmail = "Outlook not installed or not running"
        Err.Clear
        Exit Function
    End If
    
    Set objNamespace = objOutlook.GetNamespace("MAPI")
    
    If objNamespace.Accounts.Count > 0 Then
        For i = 1 To objNamespace.Accounts.Count
            strEmails = strEmails & objNamespace.Accounts.Item(i).SmtpAddress & "; "
        Next
        GetOutlookEmail = Left(strEmails, Len(strEmails) - 2)
    Else
        GetOutlookEmail = "No profile configured"
    End If
    On Error GoTo 0
End Function

Function GetHALVersion()
    On Error Resume Next
    Dim fso, halFile
    Set fso = CreateObject("Scripting.FileSystemObject")
    halFile = fso.GetSpecialFolder(1) & "\hal.dll"
    If fso.FileExists(halFile) Then
        GetHALVersion = "Version = """ & fso.GetFileVersion(halFile) & """"
    Else
        GetHALVersion = "Version = ""10.0.26100.1"""
    End If
    On Error GoTo 0
End Function

Function GetPlatformRole(roleCode)
    Select Case roleCode
        Case 1 GetPlatformRole = "Desktop"
        Case 2 GetPlatformRole = "Mobile"
        Case 3 GetPlatformRole = "Workstation"
        Case 4 GetPlatformRole = "Enterprise Server"
        Case 5 GetPlatformRole = "SOHO Server"
        Case 6 GetPlatformRole = "Appliance PC"
        Case 7 GetPlatformRole = "Performance Server"
        Case Else GetPlatformRole = "Unspecified"
    End Select
End Function

Function GetSecureBootState()
    On Error Resume Next
    Dim state
    state = objShell.RegRead("HKLM\SYSTEM\CurrentControlSet\Control\SecureBoot\State\UEFISecureBootEnabled")
    If state = 1 Then
        GetSecureBootState = "On"
    ElseIf state = 0 Then
        GetSecureBootState = "Off"
    Else
        GetSecureBootState = "Not Supported / Unknown"
    End If
    On Error GoTo 0
End Function

Function ConvertWMIDate(wmiDate)
    If Not IsNull(wmiDate) And Len(wmiDate) >= 8 Then
        ConvertWMIDate = Mid(wmiDate, 5, 2) & "/" & Mid(wmiDate, 7, 2) & "/" & Left(wmiDate, 4)
    Else
        ConvertWMIDate = "Unknown"
    End If
End Function

Function GetRegistryValue(strKey, strValName, defaultVal)
    On Error Resume Next
    Dim val
    val = objShell.RegRead(strKey)
    If Err.Number = 0 Then
        If val = 1 Then GetRegistryValue = "UEFI" Else GetRegistryValue = "Legacy"
    Else
        GetRegistryValue = defaultVal
        Err.Clear
    End If
    On Error GoTo 0
End Function

Function GetRegDWORD(strKey, matchVal, defaultVal)
    On Error Resume Next
    Dim val
    val = objShell.RegRead(strKey)
    If Err.Number = 0 Then
        If val = 1 Then GetRegDWORD = matchVal Else GetRegDWORD = defaultVal
    Else
        GetRegDWORD = matchVal
        Err.Clear
    End If
    On Error GoTo 0
End Function

Function GetWindowsProductKey()
    On Error Resume Next
    Dim strPath, digitalID
    strPath = "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\DigitalProductId"
    digitalID = objShell.RegRead(strPath)
    
    If IsArray(digitalID) Then
        GetWindowsProductKey = DecodeProductKey(digitalID)
    Else
        GetWindowsProductKey = "Unavailable (OEM / Digital License or Access Denied)"
    End If
    On Error GoTo 0
End Function

Function DecodeProductKey(digitalID)
    Const keyOffset = 52
    Dim isWin8, map, i, j, current, keyChars
    map = Array("B","C","D","F","G","H","J","K","M","P","Q","R","T","V","W","X","Y","2","3","4","6","7","8","9")
    isWin8 = (digitalID(66) \ 6) And 1
    digitalID(66) = (digitalID(66) And &HF7) Or ((isWin8 And 2) * 4)
    
    i = 24
    keyChars = ""
    Do While i >= 0
        current = 0
        j = 14
        Do While j >= 0
            current = current * 256
            current = digitalID(j + keyOffset) + current
            digitalID(j + keyOffset) = (current \ 24)
            current = current Mod 24
            j = j - 1
        Loop
        i = i - 1
        keyChars = map(current) & keyChars
    Loop
    
    If isWin8 = 1 Then
        Dim prefix
        prefix = Mid(keyChars, 2, current)
        keyChars = Replace(keyChars, prefix, prefix & "N", 1, 1)
    End If
    
    DecodeProductKey = Mid(keyChars, 1, 5) & "-" & Mid(keyChars, 6, 5) & "-" & _
                       Mid(keyChars, 11, 5) & "-" & Mid(keyChars, 16, 5) & "-" & _
                       Mid(keyChars, 21, 5)
End Function

Function GetLocalUsersInfo()

    Dim strInfo
    Dim objWMIService
    Dim colUsers
    Dim objUser

    strInfo = ""

    Set objWMIService = GetObject("winmgmts:\\.\root\cimv2")

    Set colUsers = objWMIService.ExecQuery( _
        "SELECT * FROM Win32_UserAccount WHERE LocalAccount = TRUE")

    For Each objUser In colUsers

        Select Case LCase(objUser.Name)
            Case "administrator", "defaultaccount", "guest", "wdagutilityaccount"
                ' Skip

            Case Else
                strInfo = strInfo & _
                    "User Name : " & objUser.Name & vbCrLf & _
                    "Full Name : " & objUser.FullName & vbCrLf & _
                    "Disabled  : " & objUser.Disabled & vbCrLf & _
                    "Lockout   : " & objUser.Lockout & vbCrLf & _
                    "SID       : " & objUser.SID & vbCrLf & _
                    String(40, "-") & vbCrLf
        End Select

    Next

    If strInfo = "" Then
        strInfo = "Không tìm thấy local user nào."
    End If

    GetLocalUsersInfo = strInfo

End Function