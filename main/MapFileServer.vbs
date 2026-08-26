' -------------------------------------------------------------------------------
Dim objNetwork, strRemoteShare
Set objNetwork = WScript.CreateObject("WScript.Network")

GroupsDrive = "\\VNHCMPW0NHQF5\LPLife"


' Remove existing network drives if needed
On Error Resume Next
objNetwork.RemoveNetworkDrive "G:"

On Error GoTo 0

WScript.Sleep(500)

' Map network drives and handle errors
If Not MapDrive("G:", GroupsDrive) Then
    MsgBox "Failed to map drive G: to " & GroupsDrive, vbCritical, "Error"
End If


Function MapDrive(driveLetter, remotePath)
    On Error Resume Next
    objNetwork.MapNetworkDrive driveLetter, remotePath, False
    If Err.Number <> 0 Then
        MapDrive = False
        Err.Clear
    Else
        MapDrive = True
    End If
    On Error GoTo 0
    
End Function

MsgBox "Completed"