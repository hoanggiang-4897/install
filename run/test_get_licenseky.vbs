Function GetWindowsLicenseInfo()

    Dim objWMI, colLicenses, objLicense
    Dim strInfo

    Set objWMI = GetObject("winmgmts:\\.\root\CIMV2")

    Set colLicenses = objWMI.ExecQuery( _
        "SELECT * FROM SoftwareLicensingProduct " & _
        "WHERE PartialProductKey IS NOT NULL")

    strInfo = ""

    For Each objLicense In colLicenses

        strInfo = strInfo & _
            "Name: " & objLicense.Name & vbCrLf & _
            "Description: " & objLicense.Description & vbCrLf & _
            "License Status: " & GetLicenseStatus(objLicense.LicenseStatus) & vbCrLf & _
            "Partial Product Key: " & objLicense.PartialProductKey & vbCrLf & _
            "Activation ID: " & objLicense.ID & vbCrLf & _
            String(50,"-") & vbCrLf

    Next

    GetWindowsLicenseInfo = strInfo

End Function

Function GetLicenseStatus(iStatus)

    Select Case iStatus
        Case 0 : GetLicenseStatus = "Unlicensed"
        Case 1 : GetLicenseStatus = "Licensed"
        Case 2 : GetLicenseStatus = "OOB Grace"
        Case 3 : GetLicenseStatus = "OOT Grace"
        Case 4 : GetLicenseStatus = "Non-Genuine Grace"
        Case 5 : GetLicenseStatus = "Notification"
        Case 6 : GetLicenseStatus = "Extended Grace"
        Case Else
            GetLicenseStatus = "Unknown"
    End Select

End Function


Dim strLicenseInfo
strLicenseInfo = GetWindowsLicenseInfo()

MsgBox strLicenseInfo