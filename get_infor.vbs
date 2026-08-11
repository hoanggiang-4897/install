Option Explicit

' =========================================================================
' RECIPIENT CONFIGURATION
' =========================================================================
Dim strRecipientEmail
strRecipientEmail = "giang.nh@sclife.com.vn" ' Set destination email address

' =========================================================================
' MAIN SCRIPT
' =========================================================================
Dim objWMIService, colItems, objItem, objNetwork, objShell
Dim strComputer

strComputer = "."
Set objNetwork = CreateObject("WScript.Network")
Set objShell   = CreateObject("WScript.Shell")

' Connect to WMI Root and CIMV2
Set objWMIService = GetObject("winmgmts:\\" & strComputer & "\root\cimv2")

' --- 1. User & Outlook Info ---
Dim strLogonAccount, strOutlookEmail
strLogonAccount = objNetwork.UserDomain & "\" & objNetwork.UserName
strOutlookEmail = GetOutlookEmail()

' --- 2. Operating System Info (Win32_OperatingSystem) ---
Dim strOSName, strOSVersion, strOSDescription, strOSManufacturer
Dim strWinDir, strSysDir, strLocale, strTimeZone
Dim strTotalRAM, strAvailRAM, strTotalVirtual, strAvailVirtual, strPageFileSize, strPageFilePath

Set colItems = objWMIService.ExecQuery("SELECT * FROM Win32_OperatingSystem")
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

' Time Zone
Set colItems = objWMIService.ExecQuery("SELECT Caption FROM Win32_TimeZone")
For Each objItem In colItems
    strTimeZone = objItem.Caption
    Exit For
Next

' Page File Location
Set colItems = objWMIService.ExecQuery("SELECT Name FROM Win32_PageFileSetting")
For Each objItem In colItems
    strPageFilePath = objItem.Name
    Exit For
Next
If strPageFilePath = "" Then strPageFilePath = "C:\pagefile.sys"

' --- 3. System & Hardware Info (Win32_ComputerSystem) ---
Dim strSystemName, strSysManufacturer, strSysModel, strSysType, strSysSKU, strInstalledRAM, strRole, strHypervisor

Set colItems = objWMIService.ExecQuery("SELECT * FROM Win32_ComputerSystem")
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

' --- 4. Processor & HAL Info ---
Dim strProcessor, strHALVersion
Set colItems = objWMIService.ExecQuery("SELECT * FROM Win32_Processor")
For Each objItem In colItems
    strProcessor = Trim(objItem.Name) & ", " & objItem.MaxClockSpeed & " Mhz, " & _
                   objItem.NumberOfCores & " Core(s), " & _
                   objItem.NumberOfLogicalProcessors & " Logical Processor(s)"
    Exit For
Next

' Hardware Abstraction Layer (HAL)
Set colItems = objWMIService.ExecQuery("SELECT Version FROM Win32_PnPEntity WHERE Name LIKE '%Hardware Abstraction Layer%'")
For Each objItem In colItems
    strHALVersion = "Version = """ & objItem.Version & """"
    Exit For
Next
If strHALVersion = "" Then strHALVersion = "Version = ""10.0.26100.1"""

' --- 5. BIOS Info (Win32_BIOS) ---
Dim strBIOSVersion, strSMBIOSVersion, strECVersion, strBIOSSerial, strBIOSMode, strSecureBoot

Set colItems = objWMIService.ExecQuery("SELECT * FROM Win32_BIOS")
For Each objItem In colItems
    strBIOSVersion   = objItem.Manufacturer & " " & objItem.SMBIOSBIOSVersion & ", " & ConvertWMIDate(objItem.ReleaseDate)
    strSMBIOSVersion = objItem.SMBIOSMajorVersion & "." & objItem.SMBIOSMinorVersion
    strECVersion     = objItem.EmbeddedControllerMajorVersion & "." & objItem.EmbeddedControllerMinorVersion
    strBIOSSerial    = Trim(objItem.SerialNumber)
    Exit For
Next

' BIOS Mode & Secure Boot State
strBIOSMode   = GetRegistryValue("HKLM\System\CurrentControlSet\Control\SecureBoot\State\UEFI", "UEFI", "Legacy / Unknown")
strSecureBoot = GetSecureBootState()

' --- 6. BaseBoard Info ---
Dim strBoardManufacturer, strBoardProduct, strBoardVersion

Set colItems = objWMIService.ExecQuery("SELECT * FROM Win32_BaseBoard")
For Each objItem In colItems
    strBoardManufacturer = objItem.Manufacturer
    strBoardProduct      = objItem.Product
    strBoardVersion      = objItem.Version
    If strBoardVersion = "" Then strBoardVersion = "Not Defined"
    Exit For
Next

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
Set colItems = objWMIService.ExecQuery("SELECT BootDevice FROM Win32_OperatingSystem")
For Each objItem In colItems
    strBootDevice = objItem.BootDevice
    Exit For
Next

strProductKey = GetWindowsProductKey()

' =========================================================================
' ASSEMBLE REPORT & SEND EMAIL
' =========================================================================
Dim strSubject, strBody
strSubject = "Full System Information Audit - " & strSystemName

strBody = "Item" & vbTab & vbTab & vbTab & "Value" & vbCrLf & _
          "--------------------------------------------------------------------------------" & vbCrLf & _
          "OS Name:" & vbTab & vbTab & vbTab & strOSName & vbCrLf & _
          "Version:" & vbTab & vbTab & vbTab & strOSVersion & vbCrLf & _
          "Other OS Description:" & vbTab & strOSDescription & vbCrLf & _
          "OS Manufacturer:" & vbTab & vbTab & strOSManufacturer & vbCrLf & _
          "System Name:" & vbTab & vbTab & strSystemName & vbCrLf & _
          "System Manufacturer:" & vbTab & strSysManufacturer & vbCrLf & _
          "System Model:" & vbTab & vbTab & strSysModel & vbCrLf & _
          "System Type:" & vbTab & vbTab & strSysType & vbCrLf & _
          "System SKU:" & vbTab & vbTab & strSysSKU & vbCrLf & _
          "Processor:" & vbTab & vbTab & strProcessor & vbCrLf & _
          "BIOS Version/Date:" & vbTab & strBIOSVersion & vbCrLf & _
          "SMBIOS Version:" & vbTab & vbTab & strSMBIOSVersion & vbCrLf & _
          "Embedded Controller Version:" & vbTab & strECVersion & vbCrLf & _
          "BIOS Mode:" & vbTab & vbTab & strBIOSMode & vbCrLf & _
          "BaseBoard Manufacturer:" & vbTab & strBoardManufacturer & vbCrLf & _
          "BaseBoard Product:" & vbTab & strBoardProduct & vbCrLf & _
          "BaseBoard Version:" & vbTab & strBoardVersion & vbCrLf & _
          "Platform Role:" & vbTab & vbTab & strRole & vbCrLf & _
          "Secure Boot State:" & vbTab & strSecureBoot & vbCrLf & _
          "Windows Directory:" & vbTab & strWinDir & vbCrLf & _
          "System Directory:" & vbTab & strSysDir & vbCrLf & _
          "Boot Device:" & vbTab & vbTab & strBootDevice & vbCrLf & _
          "Locale:" & vbTab & vbTab & vbTab & strLocale & vbCrLf & _
          "Hardware Abstraction Layer:" & vbTab & strHALVersion & vbCrLf & _
          "User Name:" & vbTab & vbTab & strLogonAccount & vbCrLf & _
          "Outlook Email:" & vbTab & vbTab & strOutlookEmail & vbCrLf & _
          "Time Zone:" & vbTab & vbTab & strTimeZone & vbCrLf & _
          "Installed Physical Memory (RAM): " & strInstalledRAM & vbCrLf & _
          "Total Physical Memory:" & vbTab & strTotalRAM & vbCrLf & _
          "Available Physical Memory:" & vbTab & strAvailRAM & vbCrLf & _
          "Total Virtual Memory:" & vbTab & strTotalVirtual & vbCrLf & _
          "Available Virtual Memory:" & vbTab & strAvailVirtual & vbCrLf & _
          "Page File Space:" & vbTab & strPageFileSize & vbCrLf & _
          "Page File:" & vbTab & vbTab & strPageFilePath & vbCrLf & _
          "Kernel DMA Protection:" & vbTab & strKernelDMA & vbCrLf & _
          "Virtualization-based security:" & vbTab & strVBSStatus & vbCrLf & _
          "VBS Required Security Props:" & vbTab & strVBSReq & vbCrLf & _
          "VBS Available Security Props:" & vbTab & strVBSAvail & vbCrLf & _
          "VBS Security Services Configured:" & strVBSSec & vbCrLf & _
          "App Control for Business policy:" & vbTab & strAppControl & vbCrLf & _
          "App Control for Business user policy:" & strAppControlUser & vbCrLf & _
          "SMM Isolation Level:" & vbTab & strSMMIsolation & vbCrLf & _
          "Windows Product Key:" & vbTab & strProductKey & vbCrLf & _
          "BIOS Serial Number:" & vbTab & strBIOSSerial & vbCrLf & _
          "Report Time:" & vbTab & vbTab & Now()

' Send Email via Outlook COM
SendViaOutlook strRecipientEmail, strSubject, strBody

' =========================================================================
' HELPER FUNCTIONS
' =========================================================================

Sub SendViaOutlook(strTo, strSubj, strBodyText)
    On Error Resume Next
    Dim objOutlook, objMail
    Set objOutlook = CreateObject("Outlook.Application")
    
    If Err.Number <> 0 Then
        WScript.Echo "Error: Microsoft Outlook is not installed or running."
        Err.Clear
        Exit Sub
    End If
    
    Set objMail = objOutlook.CreateItem(0)
    With objMail
        .To = strTo
        .Subject = strSubj
        .Body = strBodyText
        .Send
    End With
    
    If Err.Number <> 0 Then
        WScript.Echo "Failed to send email: " & Err.Description
        Err.Clear
    Else
        WScript.Echo "System information report successfully sent to " & strTo
    End If
    On Error GoTo 0
End Sub

Function GetOutlookEmail()
    On Error Resume Next
    Dim objOutlook, objNamespace, i, strEmails
    Set objOutlook = CreateObject("Outlook.Application")
    If Err.Number <> 0 Then
        GetOutlookEmail = "Outlook not installed"
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