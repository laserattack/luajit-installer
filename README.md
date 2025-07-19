# 🌑 LuaJIT installer

## Windows 10+

### Prerequisites

This script is just an automated execution of the installation described here [luajit.org/install.html](https://luajit.org/install.html)

### Installing

`win/luajit_installer.vbs` - installer

- Update the `download_link` (if needed) 
- Update the `archive_url` in the installer to point to the newest LuaJIT release (or stick with version 2.1 if you prefer)

```VB
' settings block start

archive_url = "https://github.com/LuaJIT/LuaJIT/archive/refs/tags/v2.1.ROLLING.zip"
download_dir_path = "C:/LuaJIT/" ' auto-created if missing

' settings block end
```

The script launches with just a double-click