' settings block start

archive_url = "https://github.com/LuaJIT/LuaJIT/archive/refs/tags/v2.1.ROLLING.zip"

' settings block end

If InStr(LCase(WScript.FullName), "wscript") > 0 Then
    CreateObject("WScript.Shell").Run "cscript //Nologo " & QuoteString(WScript.ScriptFullName), 1, False
    WScript.Quit
End If

Function Main()
    WScript.Echo "installation initiated!"

    load_dir = "./LuaJIT/"
    
    WScript.Echo "preparing folders..."
    If Not FolderExists(load_dir) Then CreateFolder load_dir
    
    archive_path = load_dir & "LuaJIT.zip"
    download_cmd = "curl -L -o " & QuoteString(archive_path) & " " & archive_url
    WScript.Echo "downloading sources..."
    ExecCmd "cmd /c " & download_cmd, 0, True
    WScript.Echo "unpacking archives..."
    UnzipArchive archive_path, load_dir

End Function

Function UnzipArchive(archive_path, dst)
    Set fso = CreateObject("Scripting.FileSystemObject")
    sourceFile = fso.GetAbsolutePathName(archive_path)
    destFolder = fso.GetAbsolutePathName(dst)

    tar_cmd = "tar -xf " & QuoteString(sourceFile) & " -C " & QuoteString(destFolder)
    ExecCmd "cmd /c " & tar_cmd, 0, True
End Function

Function FolderExists(path)
    Set fs = CreateObject("Scripting.FileSystemObject")
    FolderExists = fs.FolderExists(path)
End Function

Function CreateFolder(path)
    Set fs = CreateObject("Scripting.FileSystemObject")
    fs.CreateFolder path
End Function

Function ExecCmd(command, windowStyle, waitOnReturn)
    Set shell = CreateObject("WScript.Shell")
    shell.Run command, windowStyle, waitOnReturn
End Function

Function QuoteString(str)
    QuoteString = Chr(34) & str & Chr(34)
End Function

Main()