@echo off
echo ================================================
echo 🏥 医小伴陪诊APP - SSH隧道一键修复工具
echo ================================================
echo.

echo 步骤1: 检查PuTTY安装...
where putty >nul 2>nul
if %errorlevel% neq 0 (
    echo ❌ PuTTY未安装
    echo 请访问 https://www.putty.org/ 下载安装
    pause
    exit /b 1
)
echo ✅ PuTTY已安装

echo.
echo 步骤2: 检查端口占用...
for %%p in (7070 8080 3000 8082 9090) do (
    netstat -ano | findstr ":%%p" >nul
    if not errorlevel 1 (
        echo ⚠️  端口 %%p 被占用
        for /f "tokens=5" %%a in ('netstat -ano ^| findstr ":%%p"') do (
            echo    正在停止进程 PID: %%a
            taskkill /F /PID %%a >nul 2>nul
        )
    ) else (
        echo ✅ 端口 %%p 可用
    )
)

echo.
echo 步骤3: 创建PuTTY快捷方式...
echo 正在创建桌面快捷方式...

(
echo set WshShell = WScript.CreateObject("WScript.Shell")
echo set oShellLink = WshShell.CreateShortcut(WshShell.SpecialFolders("Desktop") ^& "\医小伴服务器.lnk")
echo oShellLink.TargetPath = "C:\Program Files\PuTTY\putty.exe"
echo oShellLink.Arguments = "-load ""医小伴服务器"""
echo oShellLink.WorkingDirectory = ""
echo oShellLink.Description = "医小伴陪诊APP SSH连接"
echo oShellLink.Save
) > "%TEMP%\create_shortcut.vbs"

cscript //nologo "%TEMP%\create_shortcut.vbs"
del "%TEMP%\create_shortcut.vbs"

echo.
echo 步骤4: 创建PuTTY配置文件...
echo 请手动配置PuTTY:
echo   1. 打开PuTTY
echo   2. Host: 122.51.179.136
echo   3. Port: 22
echo   4. Connection -> SSH -> Tunnels
echo   5. 添加以下隧道:
echo      - Source: 7070 -> Destination: localhost:7070
echo      - Source: 8080 -> Destination: localhost:8080
echo      - Source: 3000 -> Destination: localhost:3000
echo   6. 每个都要点击Add
echo   7. 回到Session，保存为"医小伴服务器"
echo   8. 点击Open连接
echo   9. 点击"是(Y)"接受密钥
echo   10. 登录: root / yixiaoban123

echo.
echo 步骤5: 测试连接...
echo 请打开浏览器访问:
echo   http://localhost:7070/direct_test.html
echo   http://localhost:8080
echo   http://localhost:3000/health

echo.
echo ================================================
echo 🎯 快速测试命令 (在PowerShell中运行):
echo ================================================
echo.
echo # 测试端口
echo Test-NetConnection localhost -Port 7070
echo.
echo # 使用Windows SSH (备用方案)
echo ssh -L 7070:localhost:7070 root@122.51.179.136
echo # 密码: yixiaoban123
echo.
echo ================================================
echo 按任意键打开PuTTY...
pause >nul
start "" "C:\Program Files\PuTTY\putty.exe" -load "医小伴服务器"