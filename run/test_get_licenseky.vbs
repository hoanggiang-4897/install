' Function GetWindowsLicenseInfo()

'     Dim objWMI, colLicenses, objLicense
'     Dim strInfo

'     Set objWMI = GetObject("winmgmts:\\.\root\CIMV2")

'     Set colLicenses = objWMI.ExecQuery( _
'         "SELECT * FROM SoftwareLicensingProduct " & _
'         "WHERE PartialProductKey IS NOT NULL")

'     strInfo = ""

'     For Each objLicense In colLicenses

'         strInfo = strInfo & _
'             "Name: " & objLicense.Name & vbCrLf & _
'             "Description: " & objLicense.Description & vbCrLf & _
'             "License Status: " & GetLicenseStatus(objLicense.LicenseStatus) & vbCrLf & _
'             "Partial Product Key: " & objLicense.PartialProductKey & vbCrLf & _
'             "Activation ID: " & objLicense.ID & vbCrLf & _
'             String(50,"-") & vbCrLf

'     Next

'     GetWindowsLicenseInfo = strInfo

' End Function

' Function GetLicenseStatus(iStatus)

'     Select Case iStatus
'         Case 0 : GetLicenseStatus = "Unlicensed"
'         Case 1 : GetLicenseStatus = "Licensed"
'         Case 2 : GetLicenseStatus = "OOB Grace"
'         Case 3 : GetLicenseStatus = "OOT Grace"
'         Case 4 : GetLicenseStatus = "Non-Genuine Grace"
'         Case 5 : GetLicenseStatus = "Notification"
'         Case 6 : GetLicenseStatus = "Extended Grace"
'         Case Else
'             GetLicenseStatus = "Unknown"
'     End Select

' End Function


' Dim strLicenseInfo
' strLicenseInfo = GetWindowsLicenseInfo()

' MsgBox strLicenseInfo


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
            Case "administrator", "defaultaccount", "guest", "wdagutilityaccount", "accountdo", "scan_acc",
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

Dim strInfor
Dim arrLines
Dim line
Dim strUserName

strInfor = GetLocalUsersInfo()

arrLines = Split(strInfor, vbCrLf)

For Each line In arrLines
    If InStr(line, "User Name :") > 0 Then
        strUserName = Trim(Replace(line, "User Name :", ""))
        Exit For
    End If
Next

MsgBox strUserName