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
    WScript.Echo "unpacking archive with LuaJIT..."
    UnzipArchive archive_path, download_dir

    WScript.Echo "LuaJIT folder search..."
    Set fs = CreateObject("Scripting.FileSystemObject")
    Set subfolders = fs.GetFolder(download_dir).SubFolders
    Dim extracted_folder
    For Each subfolder In subfolders
        If InStr(LCase(subfolder.Name), "luajit") > 0 Then
            extracted_folder = subfolder.Name
            Exit For
        End If
    Next
    If extracted_folder <> "" Then
        WScript.Echo "folder: " & extracted_folder
    Else
        WScript.Echo "luajit folder not found in" & dest_folder
        Set fs = Nothing
        WScript.Quit
    End If
    Set fs = Nothing

    src_path = download_dir & extracted_folder & "/src"
    luajit_exe_path = src_path & "/luajit.exe"
    lua51_dll_path = src_path & "/lua51.dll"

    If Not FileExists(src_path & "/luajit.exe") Then
        RenameFileIfExists src_path, "luajit_rolling.h", "luajit.h"
        WScript.Echo "Building LuaJIT..."
        build_cmd = "cmd /c call " & QuoteString(vs_command_prompt_path) & _
                    " && cd /D " & QuoteString(src_path) & _
                    " && msvcbuild"
        ExecCmd build_cmd, 1, True
    Else
        WScript.Echo "LuaJIT is already built"
    End If

    CopyFileSafe luajit_exe_path, download_dir
    CopyFileSafe lua51_dll_path, download_dir

    If Not FolderExists(download_dir & "lua") Then
        CreateFolder download_dir & "lua"
        WScript.Echo "folder created: " & download_dir & "lua"
    Else
        WScript.Echo "folder already exists: " & download_dir & "lua"
    End If

    jit_folder_path = download_dir & "lua/jit"
    CopyFolderSafe src_path & "/jit",  jit_folder_path

    WScript.Echo "cleanup..."
    DeletePath archive_path
    DeletePath download_dir & extracted_folder

    WScript.Echo "LuaJIT successfully installed! you can close this window"
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

Function RenameFileIfExists(folder_path, original_name, new_name)
    Set fs = CreateObject("Scripting.FileSystemObject")
    originalPath = fs.BuildPath(folder_path, original_name)
    newPath = fs.BuildPath(folder_path, new_name)

    If FileExists(newPath) Then
        WScript.Echo "file " & new_name & " already exists"
        Exit Function
    End If

    If FileExists(originalPath) Then
        fs.MoveFile originalPath, newPath
        WScript.Echo "file " & original_name & " renamed to " & new_name
    Else
        WScript.Echo "file " & original_name & " not found"
        Set fs = Nothing
        WScript.Quit
    End If

    Set fs = Nothing
End Function

'''''''''''''''''''''''''''''''''''''''''''''''''''''''

' Распаковка архива archive_path в папку dst_folder_path.
' В случае какой-то ошибки завершает работу скрипта

'''''''''''''''''''''''''''''''''''''''''''''''''''''''

Function UnzipArchive(archive_path, dst_folder_path)
    tar_cmd = "tar -xf " & QuoteString(archive_path) & " -C " & QuoteString(dst_folder_path)
    ExecCmd "cmd /c " & tar_cmd, 0, True
End Function

'''''''''''''''''''''''''''''''''''''''''''''''''''''''

' Копирование папки source_folder_path в папку dst_folder_path.
' В случае какой-то ошибки завершает работу скрипта

'''''''''''''''''''''''''''''''''''''''''''''''''''''''

Function CopyFolderSafe(source_folder_path, dst_folder_path)
    
    If Not FolderExists(source_folder_path) Then
        WScript.Echo "error: source folder not found: " & source_folder_path
        WScript.Quit
    End If
    
    If FileExists(dst_folder_path) Then
        WScript.Echo "error: destination path is a file, not a folder: " & dst_folder_path
        WScript.Quit
    End If
    
    On Error Resume Next
    CopyFolder source_folder_path, dst_folder_path, True
    If Err.Number <> 0 Then
        WScript.Echo "error: " & Err.Description
        WScript.Quit
    End If
    On Error GoTo 0
    
    Set fs = Nothing
End Function

'''''''''''''''''''''''''''''''''''''''''''''''''''''''

' Копирование файла source_path в dest_folder.
' В случае какой-то ошибки завершает работу скрипта

'''''''''''''''''''''''''''''''''''''''''''''''''''''''

Function CopyFileSafe(source_path, dest_folder)
    
    If Not FileExists(source_path) Then
        WScript.Echo "error: file not found"
        WScript.Quit
    End If
    
    On Error Resume Next
    CopyFile source_path, dest_folder & "/", True
    If Err.Number <> 0 Then
        WScript.Echo "error: " & Err.Description
        WScript.Quit
    End If
    On Error GoTo 0
    
End Function

'''''''''''''''''''''''''''''''''''''''''''''''''''''''

' Удаление файла/папки по переданному пути.
' В случае какой-то ошибки завершает работу скрипта

'''''''''''''''''''''''''''''''''''''''''''''''''''''''

Function DeletePath(path)
    
    If Not FileExists(path) And Not FolderExists(path) Then
        WScript.Echo "error: path not found: " & path
        WScript.Quit
    End If
    
    On Error Resume Next
    If FileExists(path) Then
        DeleteFile path, True
        WScript.Echo "file deleted: " & path
    ElseIf FolderExists(path) Then
        DeleteFolder path, True
        WScript.Echo "folder deleted: " & path
    End If
    
    If Err.Number <> 0 Then
        WScript.Echo "error: " & Err.Description
        WScript.Quit
    End If
    On Error GoTo 0
    
End Function

'''''''''''''''''''''''''''''''''''''''''''''''''''''''

' Базовые функции. Не делают никаких проверок.
' Просто выполняют указанное действие.
' Просто обертки над соответствующими COM-функциями

'''''''''''''''''''''''''''''''''''''''''''''''''''''''

Function CopyFolder(src_path, dst_path, overwriting)
    Set fs = CreateObject("Scripting.FileSystemObject")
    fs.CopyFolder src_path, dst_path, overwriting
    Set fs = Nothing
End Function

Function CopyFile(src_path, dst_path, overwriting)
    Set fs = CreateObject("Scripting.FileSystemObject")
    fs.CopyFile src_path, dst_path, overwriting
    Set fs = Nothing
End Function

Function DeleteFile(path, force_deletetion)
    Set fs = CreateObject("Scripting.FileSystemObject")
    fs.DeleteFile path, True
    Set fs = Nothing
End Function

Function DeleteFolder(path, force_deletetion)
    Set fs = CreateObject("Scripting.FileSystemObject")
    fs.DeleteFolder path, True
    Set fs = Nothing
End Function

Function FileExists(path)
    Set fs = CreateObject("Scripting.FileSystemObject")
    FileExists = fs.FileExists(path)
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

Function ExecCmd(command, window_style, wait_on_return)
    Set shell = CreateObject("WScript.Shell")
    shell.Run command, window_style, wait_on_return
    Set shell = Nothing
End Function

'''''''''''''''''''''''''''''''''''''''''''''''''''''''

Main()