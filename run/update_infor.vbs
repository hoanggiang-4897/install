' =========================================================================================
' SCRIPT INFORMATION & MAINTENANCE GUIDE
' =========================================================================================
' Script Name   : System Information Audit & Auto Logger
' Author        : IT Department
' Created Date  : 2026-03
' Target OS     : Windows 10 / Windows 11 / Windows Server
' Language      : VBScript (WSH)
'
' PURPOSE:
'   - Tự động kiểm tra quyền Admin và xin cấp quyền (Elevate) nếu chưa có.
'   - Thu thập thông tin phần cứng, hệ điều hành, tài khoản local & bản quyền Windows qua WMI.
'   - Cấu hình SMB client & dịch vụ Network Discovery/File Sharing.
'   - Xuất dữ liệu log và đẩy về thư mục chia sẻ mạng (SMB Share).
'   - Khởi tạo giao diện mail qua New Outlook (Mailto URI) để gửi báo cáo về IT.
'
' ARCHITECTURE / MAIN COMPONENTS:
'   1. EnsureAdminPrivileges : Bắt buộc chạy script dưới quyền Admin.
'   2. Class SystemAudit     : Đảm nhận toàn bộ truy vấn WMI & Registry (OS, CPU, RAM, Key).
'   3. Class ReportLogger    : Xử lý bật dịch vụ mạng, mount SMB Share và ghi file log.
'   4. Class EmailNotifier   : Tạo file PowerShell tạm để trigger New Outlook gửi mail.
'
' CONFIGURATION PARAMETERS (Cần cập nhật khi thay đổi hạ tầng):
'   - Recipient Email : notifier.Recipient = "giang.nh@sacomlife.com.vn"
'   - SMB Log Server  : strNetServer = "\\VNHCMPF60MQE1"
'   - SMB Log Folder  : strFolder    = "\\VNHCMPF60MQE1\machine_logs"
'
' REVISION HISTORY:
'   - v1.0 (2026-03) : Khởi tạo bản refactor theo cấu trúc Object-Oriented (Class).
'   - v1.1 (2026-03) : Fix lỗi WMI Query 0x80041017 (OSManufacturer -> Manufacturer).
' =========================================================================================

Option Explicit

' =========================================================================
' 1. INITIALIZATION & ELEVATION
' =========================================================================
EnsureAdminPrivileges

Dim audit, logger, notifier, userChoice

Set audit = New SystemAudit
Set logger = New ReportLogger
Set notifier = New EmailNotifier

' Cấu hình SMB client ngầm
audit.ApplySmbConfigurations

' Thu thập dữ liệu
Dim reportContent, serialNumber, primaryUser
reportContent = audit.GenerateFullReport()
serialNumber  = audit.BIOSSerial
primaryUser   = audit.GetPrimaryUserName()

' Lưu report vào SMB Share / Local Folder
logger.SaveReportToFile reportContent, serialNumber, primaryUser

' Xác nhận gửi mail
userChoice = MsgBox("Do you want to send email to IT Department?", _
                    vbYesNo + vbQuestion + vbDefaultButton2, "Confirm Send")

If userChoice = vbYes Then
    notifier.Recipient = "giang.nh@sacomlife.com.vn"
    notifier.Cc        = ""
    notifier.Subject   = "Full System Information Audit - " & audit.SystemName
    notifier.SendViaNewOutlook reportContent
End If

' Clear Objects
Set audit = Nothing
Set logger = Nothing
Set notifier = Nothing


' =========================================================================
' 2. CLASSES & MODULES
' =========================================================================

' -------------------------------------------------------------------------
' CLASS: SystemAudit (Chịu trách nhiệm thu thập toàn bộ thông tin WMI/Registry)
' -------------------------------------------------------------------------
Class SystemAudit
    Private objWMI, objShell, objNetwork
    Public SystemName, BIOSSerial

    Private Sub Class_Initialize()
        Set objNetwork = CreateObject("WScript.Network")
        Set objShell   = CreateObject("WScript.Shell")
        On Error Resume Next
        Set objWMI     = GetObject("winmgmts:\\.\root\cimv2")
        On Error GoTo 0
    End Sub

    Public Sub ApplySmbConfigurations()
        Dim cmd1, cmd2
        cmd1 = "powershell.exe -NoProfile -ExecutionPolicy Bypass -Command ""Set-SmbClientConfiguration -EnableInsecureGuestLogons $true -Force"""
        cmd2 = "powershell.exe -NoProfile -ExecutionPolicy Bypass -Command ""Set-SmbClientConfiguration -RequireSecuritySignature $false -Force"""
        objShell.Run cmd1, 0, True
        objShell.Run cmd2, 0, True
    End Sub

    Public Function GenerateFullReport()
        Dim sb
        sb = "=== System Information ===" & vbCrLf & vbCrLf
        sb = sb & "BIOS Serial Number: " & GetBIOSInfo() & vbCrLf
        sb = sb & "Email address: " & GetOutlookEmail() & vbCrLf
        sb = sb & GetOSInfo() & vbCrLf
        sb = sb & GetComputerSystemInfo() & vbCrLf
        sb = sb & "Processor: " & GetProcessorInfo() & vbCrLf
        sb = sb & "Locale: " & GetLocaleInfo() & vbCrLf
        sb = sb & "Hardware Abstraction Layer: " & GetHALVersion() & vbCrLf
        sb = sb & GetLocalUsersInfo() & vbCrLf
        sb = sb & "Time Zone: " & GetTimeZoneInfo() & vbCrLf & vbCrLf
        sb = sb & "=== License Information ===" & vbCrLf
        sb = sb & "Windows Product Key: " & GetWindowsProductKey() & vbCrLf
        sb = sb & String(50, "-") & vbCrLf
        sb = sb & "License Product Key: " & vbCrLf & GetWindowsLicenseInfo() & vbCrLf
        sb = sb & "Report Time: " & Now()

        GenerateFullReport = sb
    End Function

    Private Function GetOSInfo()
        Dim colItems, objItem, res
        Set colItems = objWMI.ExecQuery("SELECT Caption, Version, BuildNumber, Manufacturer, TotalVisibleMemorySize, FreePhysicalMemory, TotalVirtualMemorySize, FreeVirtualMemory FROM Win32_OperatingSystem")
        For Each objItem In colItems
            res = "OS Name: " & Split(objItem.Caption, "(")(0) & vbCrLf & _
                  "Version: " & objItem.Version & " Build " & objItem.BuildNumber & vbCrLf & _
                  "OS Manufacturer: " & objItem.Manufacturer & vbCrLf & _
                  "Total Physical Memory: " & Round(CDbl(objItem.TotalVisibleMemorySize) / (1024 * 1024), 2) & " GB" & vbCrLf & _
                  "Available Physical Memory: " & Round(CDbl(objItem.FreePhysicalMemory) / (1024 * 1024), 2) & " GB" & vbCrLf & _
                  "Total Virtual Memory: " & Round(CDbl(objItem.TotalVirtualMemorySize) / (1024 * 1024), 2) & " GB" & vbCrLf & _
                  "Available Virtual Memory: " & Round(CDbl(objItem.FreeVirtualMemory) / (1024 * 1024), 2) & " GB"
            Exit For
        Next
        GetOSInfo = res
    End Function

    Private Function GetComputerSystemInfo()
        Dim colItems, objItem, res
        Set colItems = objWMI.ExecQuery("SELECT Name, Manufacturer, Model, SystemType, SystemSKUNumber, TotalPhysicalMemory FROM Win32_ComputerSystem")
        For Each objItem In colItems
            SystemName = objItem.Name
            res = "System Name: " & objItem.Name & vbCrLf & _
                  "System Manufacturer: " & objItem.Manufacturer & vbCrLf & _
                  "System Model: " & objItem.Model & vbCrLf & _
                  "System Type: " & objItem.SystemType & vbCrLf & _
                  "System SKU: " & objItem.SystemSKUNumber & vbCrLf & _
                  "Installed Physical Memory (RAM): " & Round(CDbl(objItem.TotalPhysicalMemory) / (1024 * 1024 * 1024), 2) & " GB"
            Exit For
        Next
        GetComputerSystemInfo = res
    End Function

    Private Function GetProcessorInfo()
        Dim colItems, objItem
        Set colItems = objWMI.ExecQuery("SELECT Name, MaxClockSpeed, NumberOfCores, NumberOfLogicalProcessors FROM Win32_Processor")
        For Each objItem In colItems
            GetProcessorInfo = Trim(objItem.Name) & ", " & objItem.MaxClockSpeed & " Mhz, " & _
                               objItem.NumberOfCores & " Core(s), " & _
                               objItem.NumberOfLogicalProcessors & " Logical Processor(s)"
            Exit For
        Next
    End Function

    Private Function GetBIOSInfo()
        Dim colItems, objItem, res
        Set colItems = objWMI.ExecQuery("SELECT Manufacturer, SMBIOSBIOSVersion, ReleaseDate, SMBIOSMajorVersion, SMBIOSMinorVersion, EmbeddedControllerMajorVersion, EmbeddedControllerMinorVersion, SerialNumber FROM Win32_BIOS")
        For Each objItem In colItems
            BIOSSerial = Trim(objItem.SerialNumber)
            res = BIOSSerial & vbCrLf & _
                  "BIOS Version/Date: " & objItem.Manufacturer & " " & objItem.SMBIOSBIOSVersion & ", " & ConvertWMIDate(objItem.ReleaseDate) & vbCrLf & _
                  "SMBIOS Version: " & objItem.SMBIOSMajorVersion & "." & objItem.SMBIOSMinorVersion & vbCrLf & _
                  "Embedded Controller Version: " & objItem.EmbeddedControllerMajorVersion & "." & objItem.EmbeddedControllerMinorVersion
            Exit For
        Next
        GetBIOSInfo = res
    End Function

    Private Function GetLocaleInfo()
        Dim colItems, objItem
        Set colItems = objWMI.ExecQuery("SELECT MUILanguages FROM Win32_OperatingSystem")
        For Each objItem In colItems
            GetLocaleInfo = objItem.MUILanguages(0)
            Exit For
        Next
    End Function

    Private Function GetTimeZoneInfo()
        Dim colItems, objItem
        Set colItems = objWMI.ExecQuery("SELECT Caption FROM Win32_TimeZone")
        For Each objItem In colItems
            GetTimeZoneInfo = objItem.Caption
            Exit For
        Next
    End Function

    Private Function GetHALVersion()
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

    Private Function GetOutlookEmail()
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

    Public Function GetLocalUsersInfo()
        Dim colUsers, objUser, strInfo
        Set colUsers = objWMI.ExecQuery("SELECT * FROM Win32_UserAccount WHERE LocalAccount = TRUE")
        
        For Each objUser In colUsers
            Select Case LCase(objUser.Name)
                Case "administrator", "defaultaccount", "guest", "wdagutilityaccount", "accountdo", "scan_acc"
                    ' Skip system accounts
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
        
        If strInfo = "" Then strInfo = "Không tìm thấy local user nào."
        GetLocalUsersInfo = strInfo
    End Function

    Public Function GetPrimaryUserName()
        Dim info, lines, line
        info = GetLocalUsersInfo()
        lines = Split(info, vbCrLf)
        For Each line In lines
            If InStr(line, "User Name :") > 0 Then
                GetPrimaryUserName = Trim(Replace(line, "User Name :", ""))
                Exit Function
            End If
        Next
        GetPrimaryUserName = objNetwork.UserName
    End Function

    Private Function GetWindowsLicenseInfo()
        Dim colLicenses, objLicense, strInfo
        Set colLicenses = objWMI.ExecQuery("SELECT * FROM SoftwareLicensingProduct WHERE PartialProductKey IS NOT NULL")
        For Each objLicense In colLicenses
            strInfo = strInfo & _
                "Name: " & objLicense.Name & vbCrLf & _
                "Description: " & objLicense.Description & vbCrLf & _
                "License Status: " & GetLicenseStatus(objLicense.LicenseStatus) & vbCrLf & _
                "Partial Product Key: " & objLicense.PartialProductKey & vbCrLf & _
                "Activation ID: " & objLicense.ID & vbCrLf & _
                String(50, "-") & vbCrLf
        Next
        GetWindowsLicenseInfo = strInfo
    End Function

    Private Function GetLicenseStatus(iStatus)
        Select Case iStatus
            Case 0 : GetLicenseStatus = "Unlicensed"
            Case 1 : GetLicenseStatus = "Licensed"
            Case 2 : GetLicenseStatus = "OOB Grace"
            Case 3 : GetLicenseStatus = "OOT Grace"
            Case 4 : GetLicenseStatus = "Non-Genuine Grace"
            Case 5 : GetLicenseStatus = "Notification"
            Case 6 : GetLicenseStatus = "Extended Grace"
            Case Else : GetLicenseStatus = "Unknown"
        End Select
    End Function

    Private Function GetWindowsProductKey()
        On Error Resume Next
        Dim digitalID
        digitalID = objShell.RegRead("HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\DigitalProductId")
        If IsArray(digitalID) Then
            GetWindowsProductKey = DecodeProductKey(digitalID)
        Else
            GetWindowsProductKey = "Unavailable (OEM / Digital License or Access Denied)"
        End If
        On Error GoTo 0
    End Function

    Private Function DecodeProductKey(digitalID)
        Const keyOffset = 52
        Dim isWin8, map, i, j, current, keyChars, prefix
        map = Array("B","C","D","F","G","H","J","K","M","P","Q","R","T","V","W","X","Y","2","3","4","6","7","8","9")
        isWin8 = (digitalID(66) \ 6) And 1
        digitalID(66) = (digitalID(66) And &HF7) Or ((isWin8 And 2) * 4)
        
        i = 24
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
            prefix = Mid(keyChars, 2, current)
            keyChars = Replace(keyChars, prefix, prefix & "N", 1, 1)
        End If
        
        DecodeProductKey = Mid(keyChars, 1, 5) & "-" & Mid(keyChars, 6, 5) & "-" & _
                           Mid(keyChars, 11, 5) & "-" & Mid(keyChars, 16, 5) & "-" & _
                           Mid(keyChars, 21, 5)
    End Function

    Private Function ConvertWMIDate(wmiDate)
        If Not IsNull(wmiDate) And Len(wmiDate) >= 8 Then
            ConvertWMIDate = Mid(wmiDate, 5, 2) & "/" & Mid(wmiDate, 7, 2) & "/" & Left(wmiDate, 4)
        Else
            ConvertWMIDate = "Unknown"
        End If
    End Function
End Class


' -------------------------------------------------------------------------
' CLASS: ReportLogger (Quản lý bật Service, File Sharing & Lưu File Log)
' -------------------------------------------------------------------------
Class ReportLogger
    Private objShell, objFSO

    Private Sub Class_Initialize()
        Set objShell = CreateObject("WScript.Shell")
        Set objFSO   = CreateObject("Scripting.FileSystemObject")
    End Sub

    Public Sub SaveReportToFile(strContent, strSerial, strUserName)
        On Error Resume Next
        EnableNetworkSharing

        Dim strNetServer, strFolder, strFile, objFile
        strNetServer = "\\VNHCMPF60MQE1"
        strFolder    = strNetServer & "\machine_logs"

        ' Mount Share
        objShell.Run "cmd /c net use """ & strNetServer & """ /delete /y", 0, True
        objShell.Run "cmd /c net use """ & strFolder & """ /user:guest """"", 0, True

        ' Format File Name
        strFile = strFolder & "\" & strSerial & "_" & strUserName & "_" & _
                  Year(Now) & Right("0" & Month(Now), 2) & Right("0" & Day(Now), 2) & ".txt"

        Set objFile = objFSO.CreateTextFile(strFile, True, True)
        objFile.WriteLine strContent
        objFile.Close

        If Err.Number <> 0 Then
            WScript.Echo "Lỗi lưu file: " & Err.Description
            Err.Clear
        End If
        On Error GoTo 0
    End Sub

    Private Sub EnableNetworkSharing()
        ' Bật Firewall & Services liên quan
        objShell.Run "cmd /c netsh advfirewall firewall set rule group=""File and Printer Sharing"" new enable=Yes", 0, True
        objShell.Run "cmd /c sc config FDResPub start= auto && sc start FDResPub", 0, True
        objShell.Run "cmd /c sc config SSDPSRV start= auto && sc start SSDPSRV", 0, True
        objShell.Run "cmd /c sc config upnphost start= auto && sc start upnphost", 0, True
    End Sub
End Class


' -------------------------------------------------------------------------
' CLASS: EmailNotifier (Xử lý khởi chạy PowerShell để gửi mail qua New Outlook)
' -------------------------------------------------------------------------
Class EmailNotifier
    Public Recipient, Cc, Subject
    Private objShell, objFSO

    Private Sub Class_Initialize()
        Set objShell = CreateObject("WScript.Shell")
        Set objFSO   = CreateObject("Scripting.FileSystemObject")
    End Sub

    Public Sub SendViaNewOutlook(strBodyText)
        On Error Resume Next
        Dim strTempPath, strPSFile, objFile, strCommand

        strTempPath = objShell.ExpandEnvironmentStrings("%TEMP%")
        strPSFile   = strTempPath & "\send_mail_temp.ps1"

        Set objFile = objFSO.CreateTextFile(strPSFile, True, True)
        objFile.WriteLine "$to = '" & Recipient & "'"
        objFile.WriteLine "$cc = '" & Cc & "'"
        objFile.WriteLine "$subject = '" & Replace(Subject, "'", "''") & "'"
        objFile.WriteLine "$body = @'"
        objFile.WriteLine strBodyText
        objFile.WriteLine "'@"
        objFile.WriteLine "$encTo = [System.Uri]::EscapeDataString($to)"
        objFile.WriteLine "$encCc = [System.Uri]::EscapeDataString($cc)"
        objFile.WriteLine "$encSubj = [System.Uri]::EscapeDataString($subject)"
        objFile.WriteLine "$encBody = [System.Uri]::EscapeDataString($body)"
        objFile.WriteLine "if ($cc -ne '') { $uri = ""mailto:$($encTo)?cc=$($encCc)&subject=$($encSubj)&body=$($encBody)"" } else { $uri = ""mailto:$($encTo)?subject=$($encSubj)&body=$($encBody)"" }"
        objFile.WriteLine "Start-Process $uri"
        objFile.Close

        strCommand = "powershell.exe -ExecutionPolicy Bypass -NoProfile -File """ & strPSFile & """"
        objShell.Run strCommand, 0, True

        If objFSO.FileExists(strPSFile) Then objFSO.DeleteFile(strPSFile)

        If Err.Number <> 0 Then
            WScript.Echo "Lỗi Mail: " & Err.Description
            Err.Clear
        End If
        On Error GoTo 0
    End Sub
End Class


' -------------------------------------------------------------------------
' GLOBAL HELPER PROCEDURES
' -------------------------------------------------------------------------
Sub EnsureAdminPrivileges()
    If Not WScript.Arguments.Named.Exists("elevate") Then
        CreateObject("Shell.Application").ShellExecute "wscript.exe", """" & WScript.ScriptFullName & """ /elevate", "", "runas", 1
        WScript.Quit
    End If
End Sub