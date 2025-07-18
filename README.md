# 🌑 LuaJIT installer

`win/luajit_install.vbs` - installer for win 10+

## Windows 10+

- Update the `download_link` (if needed)
- Update the `archive_url` in the installer to point to the newest LuaJIT release (or stick with version 2.1 if you prefer)

```VB
' settings block start

archive_url = "https://github.com/LuaJIT/LuaJIT/archive/refs/tags/v2.1.ROLLING.zip"
download_dir = "C:/LuaJIT/" ' it will be created automatically if it does not exist

' settings block end
```

The script launches with just a double-click