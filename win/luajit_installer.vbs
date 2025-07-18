' settings block start

archive_url = "https://github.com/LuaJIT/LuaJIT/archive/refs/tags/v2.1.ROLLING.zip"
download_dir = "C:/LuaJIT/" ' auto-created if missing

' settings block end

Function Main()

    ' перезапуск самого себя с консолью
    If InStr(LCase(WScript.FullName), "wscript") > 0 Then
        ExecCmd "cmd /k cscript //Nologo " & QuoteString(WScript.ScriptFullName), 1, False
        WScript.Quit
    End If

    vs_command_prompt_path = VsCommandPromptPath()
    If vs_command_prompt_path <> "" Then
        WScript.Echo "vs command prompt found"
    Else
        WScript.Echo "vs command prompt not found"
        WScript.Quit
    End If

    WScript.Echo "installation initiated!"
    
    WScript.Echo "preparing folders..."
    If Not FolderExists(download_dir) Then CreateFolder download_dir
    
    archive_path = download_dir & "LuaJIT.zip"
    download_cmd = "curl -L -o " & QuoteString(archive_path) & " " & archive_url
    WScript.Echo "downloading sources..."
    ExecCmd "cmd /c " & download_cmd, 0, True
    WScript.Echo "unpacking archive with LuaJit..."
    UnzipArchive archive_path, download_dir

    WScript.Echo "LuaJIT folder search..."
    Set fs = CreateObject("Scripting.FileSystemObject")
    Set subfolders = fs.GetFolder(download_dir).SubFolders
    Dim extractedFolder
    For Each subfolder In subfolders
        If InStr(LCase(subfolder.Name), "luajit") > 0 Then
            extractedFolder = subfolder.Name
            Exit For
        End If
    Next
    If extractedFolder <> "" Then
        WScript.Echo "folder: " & extractedFolder
    Else
        WScript.Echo "luajit folder not found in" & destFolder
        Set fs = Nothing
        WScript.Quit
    End If
    Set fs = Nothing

    src_path = download_dir & extractedFolder & "/src"
    WScript.Echo "LuaJIT src path: " & src_path

    WScript.Echo "Building LuaJIT..."
    build_cmd = "cmd /c call " & QuoteString(vs_command_prompt_path) & _
                " && cd /D " & QuoteString(src_path) & _
                " && msvcbuild"
    ExecCmd build_cmd, 1, True

    WScript.Echo "you can close this window"
End Function

Function VsCommandPromptPath()
    Set shell = CreateObject("WScript.Shell")
    batPath = shell.Exec("cmd /c where /r ""C:\Program Files"" VsDevCmd.bat 2>nul").StdOut.ReadAll()
    If batPath = "" Then batPath = shell.Exec("cmd /c where /r ""C:\Program Files (x86)"" VsDevCmd.bat 2>nul").StdOut.ReadAll()
    
    If batPath <> "" Then
        batPath = Trim(Split(batPath, vbCrLf)(0))
        VsCommandPromptPath = batPath
    Else
        VsCommandPromptPath = ""
    End If
    Set shell = Nothing
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

Function QuoteString(str)
    QuoteString = Chr(34) & str & Chr(34)
End Function

Function ExecCmd(command, windowStyle, waitOnReturn)
    Set shell = CreateObject("WScript.Shell")
    shell.Run command, windowStyle, waitOnReturn
    Set shell = Nothing
End Function

Main()