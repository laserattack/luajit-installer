' settings block start

archive_url = "https://github.com/LuaJIT/LuaJIT/archive/refs/tags/v2.1.ROLLING.zip"

' settings block end

Function Main()

    ' перезапуск самого себя с консолью
    If InStr(LCase(WScript.FullName), "wscript") > 0 Then
        ExecCmd "cscript //Nologo " & QuoteString(WScript.ScriptFullName), 1, False
        WScript.Quit
    End If

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
    Set fs = CreateObject("Scripting.FileSystemObject")
    sourceFile = fs.GetAbsolutePathName(archive_path)
    destFolder = fs.GetAbsolutePathName(dst)
    tar_cmd = "tar -xf " & QuoteString(sourceFile) & " -C " & QuoteString(destFolder)
    ExecCmd "cmd /c " & tar_cmd, 0, True
    Set fs = Nothing
End Function

Function FolderExists(path)
    Set fs = CreateObject("Scripting.FileSystemObject")
    FolderExists = fs.FolderExists(path)
    Set fs = Nothing
End Function

Function CreateFolder(path)
    Set fs = CreateObject("Scripting.FileSystemObject")
    fs.CreateFolder path
    Set fs = Nothing
End Function

Function ExecCmd(command, windowStyle, waitOnReturn)
    Set shell = CreateObject("WScript.Shell")
    shell.Run command, windowStyle, waitOnReturn
    Set shell = Nothing
End Function

Function QuoteString(str)
    QuoteString = Chr(34) & str & Chr(34)
End Function

Main()