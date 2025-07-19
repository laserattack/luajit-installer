' settings block start

archive_url = "https://github.com/LuaJIT/LuaJIT/archive/refs/tags/v2.1.ROLLING.zip"
download_dir_path = "C:/LuaJIT/" ' auto-created if missing

' settings block end

Function Main()

    ' перезапуск самого себя с консолью
    If InStr(LCase(WScript.FullName), "wscript") > 0 Then
        RunCmd "cmd /k cscript //Nologo " & QuoteString(WScript.ScriptFullName), 1, False
        WScript.Quit
    End If

    WScript.Echo "installation initiated!"
    WScript.Echo "vs command prompt search..."
    vs_command_prompt_path = VsCommandPromptPathSafe()
    If vs_command_prompt_path <> "" Then
        WScript.Echo "vs command prompt found"
    Else
        WScript.Echo "vs command prompt not found"
        WScript.Quit
    End If
    
    WScript.Echo "preparing folders..."
    If Not FolderExists(download_dir_path) Then CreateFolder download_dir_path
    
    archive_path = BuildPath(download_dir_path, "LuaJIT.zip")
    download_cmd = "curl -L -o " & QuoteString(archive_path) & " " & archive_url
    WScript.Echo "downloading sources..."
    RunCmd "cmd /c " & download_cmd, 0, True
    WScript.Echo "unpacking archive with LuaJIT..."
    UnzipArchiveSafe archive_path, download_dir_path

    WScript.Echo "LuaJIT folder search..."
    Set subfolders = GetFolder(download_dir_path).SubFolders
    Dim extracted_folder_path
    For Each subfolder In subfolders
        If InStr(subfolder.Name, "LuaJIT") > 0 Then
            extracted_folder_path = subfolder.Path
            Exit For
        End If
    Next
    If extracted_folder_path <> "" Then
        WScript.Echo "exctracted folder path: " & extracted_folder_path
    Else
        WScript.Echo "luajit folder not found in" & dest_folder
        WScript.Quit
    End If

    luajit_src_path = BuildPath(extracted_folder_path, "src")
    luajit_exe_path = BuildPath(luajit_src_path, "luajit.exe")
    lua51_dll_path = BuildPath(luajit_src_path, "lua51.dll")

    If Not FileExists(luajit_exe_path) Then
        RenameFileSafe BuildPath(luajit_src_path, "luajit_rolling.h"), BuildPath(luajit_src_path, "luajit.h")
        WScript.Echo "Building LuaJIT..."
        build_cmd = "cmd /c call " & QuoteString(vs_command_prompt_path) & _
                    " && cd /D " & QuoteString(luajit_src_path) & _
                    " && msvcbuild"
        RunCmd build_cmd, 1, True
    Else
        WScript.Echo "LuaJIT is already built"
    End If

    CopyFileSafe luajit_exe_path, download_dir_path
    CopyFileSafe lua51_dll_path, download_dir_path

    lua_folder_path = BuildPath(download_dir_path, "lua")
    If Not FolderExists(lua_folder_path) Then
        CreateFolder lua_folder_path
        WScript.Echo "folder created: " & BuildPath(download_dir_path, "lua")
    Else
        WScript.Echo "folder already exists: " & BuildPath(download_dir_path, "lua")
    End If

    jit_folder_path = BuildPath(lua_folder_path, "jit")
    If Not FolderExists(jit_folder_path) Then
        CreateFolder jit_folder_path
        WScript.Echo "folder created: " & jit_folder_path
    End If
    CopyFolderSafe BuildPath(luajit_src_path, "jit"),  jit_folder_path

    WScript.Echo "cleanup..."
    DeletePathSafe archive_path
    DeletePathSafe extracted_folder_path

    WScript.Echo "LuaJIT successfully installed! you can close this window"
End Function

'''''''''''''''''''''''''''''''''''''''''''''''''''''''

' Переименование файла с именем original_name, находящегося
' в директории folder_path в new_name

' В случае какой-то ошибки завершает работу скрипта

'''''''''''''''''''''''''''''''''''''''''''''''''''''''

Function RenameFileSafe(original_path, new_path)

    ' файл уже сущестувует
    If FileExists(new_path) Then
        WScript.Echo "file " & new_name & " already exists"
        Exit Function
    End If

    ' переименование
    If FileExists(original_path) Then
        On Error Resume Next
        MoveFile original_path, new_path
        If Err.Number <> 0 Then
            WScript.Echo "error: failed to rename file: " & Err.Description
        End If
        On Error GoTo 0
        WScript.Echo "file " & original_path & " renamed to " & new_path
    Else
        WScript.Echo "file " & original_path & " not found"
        WScript.Quit
    End If

End Function

'''''''''''''''''''''''''''''''''''''''''''''''''''''''

' Поиск Command Prompt for VS.
' В случае какой-то ошибки завершает работу скрипта

'''''''''''''''''''''''''''''''''''''''''''''''''''''''

Function VsCommandPromptPathSafe()
    On Error Resume Next
    batPath = ExecCmd("cmd /c where /r ""C:\Program Files"" VsDevCmd.bat 2>nul").StdOut.ReadAll()
    If batPath = "" Then batPath = ExecCmd("cmd /c where /r ""C:\Program Files (x86)"" VsDevCmd.bat 2>nul").StdOut.ReadAll()
    If Err.Number <> 0 Then
        WScript.Echo "error: failed to execute command: " & Err.Description
        WScript.Quit
    End If
    On Error GoTo 0

    If batPath <> "" Then
        batPath = Trim(Split(batPath, vbCrLf)(0))
        VsCommandPromptPathSafe = batPath
    Else
        VsCommandPromptPathSafe = ""
    End If
End Function

'''''''''''''''''''''''''''''''''''''''''''''''''''''''

' Распаковка архива archive_path в папку dst_folder_path.
' В случае какой-то ошибки завершает работу скрипта

'''''''''''''''''''''''''''''''''''''''''''''''''''''''

Function UnzipArchiveSafe(archive_path, dst_folder_path)

    ' проверки наличия файлов
    If Not FileExists(archive_path) Then
        WScript.Echo "error: archive path not found: " & archive_path
        WScript.Quit
    End If
    
    If Not FolderExists(dst_folder_path) Then
        WScript.Echo "error: dst folder not found: " & dst_folder_path
        WScript.Quit
    End If

    tar_cmd = "tar -xf " & QuoteString(archive_path) & " -C " & QuoteString(dst_folder_path)
    On Error Resume Next
    RunCmd "cmd /c " & tar_cmd, 0, True
    
    ' обработка ошибок выполнения
    If Err.Number <> 0 Then
        WScript.Echo "error during unzip: " & Err.Description
        WScript.Echo "command that failed: " & tar_cmd
        WScript.Quit
    End If
    On Error GoTo 0
End Function

'''''''''''''''''''''''''''''''''''''''''''''''''''''''

' Копирование С ПЕРЕЗАПИСЬЮ папки src_folder_path в папку dst_folder_path.
' В случае какой-то ошибки завершает работу скрипта

'''''''''''''''''''''''''''''''''''''''''''''''''''''''

Function CopyFolderSafe(src_folder_path, dst_folder_path)

    ' не существует src директории
    If Not FolderExists(dst_folder_path) Then
        WScript.Echo "error: dst folder not found: " & dst_folder_path
        WScript.Quit
    End If

    ' не существует dst директории
    If Not FolderExists(src_folder_path) Then
        WScript.Echo "error: src folder not found: " & src_folder_path
        WScript.Quit
    End If
    
    On Error Resume Next
    CopyFolder src_folder_path, dst_folder_path, True

    ' вывод ошибки если была какая то
    If Err.Number <> 0 Then
        WScript.Echo "error: " & Err.Description
        WScript.Quit
    End If
    On Error GoTo 0
    
End Function

'''''''''''''''''''''''''''''''''''''''''''''''''''''''

' Копирование С ПЕРЕЗАПИСЬЮ файла source_path в dst_folder_path.
' В случае какой-то ошибки завершает работу скрипта

'''''''''''''''''''''''''''''''''''''''''''''''''''''''

Function CopyFileSafe(src_path, dst_folder_path)

    ' не существует файла
    If Not FileExists(src_path) Then
        WScript.Echo "error: file not found: " & src_path
        WScript.Quit
    End If
    
    ' не существует папки
    If Not FolderExists(dst_folder_path) Then
        WScript.Echo "error: folder not found: " & dst_folder_path
        WScript.Quit
    End If

    On Error Resume Next
    CopyFile src_path, dst_folder_path, True

    ' вывод ошибки если была какая то
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

Function DeletePathSafe(path)
    
    ' Либо нет такого файла либо нет такой папки
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
    
    ' вывод ошибки если была какая то
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

Function MoveFile(src_path, dst_path)
    Set fs = CreateObject("Scripting.FileSystemObject")
    fs.MoveFile src_path, dst_path
    Set fs = Nothing
End Function

Function BuildPath(path1, path2)
    Set fs = CreateObject("Scripting.FileSystemObject")
    BuildPath = fs.BuildPath(path1, path2)
    Set fs = Nothing
End Function

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

Function DeleteFile(path, force_deletion)
    Set fs = CreateObject("Scripting.FileSystemObject")
    fs.DeleteFile path, force_deletion
    Set fs = Nothing
End Function

Function DeleteFolder(path, force_deletetion)
    Set fs = CreateObject("Scripting.FileSystemObject")
    fs.DeleteFolder path, force_deletion
    Set fs = Nothing
End Function

Function FileExists(path)
    Set fs = CreateObject("Scripting.FileSystemObject")
    FileExists = fs.FileExists(path)
    Set fs = Nothing
End Function

Function GetFolder(path)
    Set fs = CreateObject("Scripting.FileSystemObject")
    Set GetFolder = fs.GetFolder(path)
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

Function ExecCmd(cmd)
    Set shell = CreateObject("WScript.Shell")
    Set ExecCmd = shell.Exec(cmd)
    Set shell = Nothing
End Function

Function RunCmd(command, window_style, wait_on_return)
    Set shell = CreateObject("WScript.Shell")
    shell.Run command, window_style, wait_on_return
    Set shell = Nothing
End Function

'''''''''''''''''''''''''''''''''''''''''''''''''''''''

Main()