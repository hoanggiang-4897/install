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

MsgBox GetLocalUsersInfo(), vbInformation, "Local Users"