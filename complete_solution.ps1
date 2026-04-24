# 医小伴陪诊APP - SSH隧道完整解决方案
# 在Windows PowerShell中以管理员身份运行

Write-Host "================================================" -ForegroundColor Cyan
Write-Host "🏥 医小伴陪诊APP - SSH隧道自动配置工具" -ForegroundColor Cyan
Write-Host "================================================" -ForegroundColor Cyan
Write-Host ""

# 检查管理员权限
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Host "⚠️  请以管理员身份运行此脚本！" -ForegroundColor Yellow
    Write-Host "   右键点击PowerShell，选择'以管理员身份运行'" -ForegroundColor Yellow
    pause
    exit
}

# 步骤1：检查并安装PuTTY
Write-Host "步骤1: 检查PuTTY安装..." -ForegroundColor Green
$puttyPath = "C:\Program Files\PuTTY\putty.exe"
if (-not (Test-Path $puttyPath)) {
    Write-Host "❌ PuTTY未安装" -ForegroundColor Red
    $installChoice = Read-Host "是否下载并安装PuTTY? (Y/N)"
    if ($installChoice -eq 'Y' -or $installChoice -eq 'y') {
        Write-Host "正在下载PuTTY..." -ForegroundColor Yellow
        $url = "https://the.earth.li/~sgtatham/putty/latest/w64/putty-64bit-0.81-installer.msi"
        $installer = "$env:TEMP\putty-installer.msi"
        Invoke-WebRequest -Uri $url -OutFile $installer
        Write-Host "正在安装PuTTY..." -ForegroundColor Yellow
        Start-Process msiexec.exe -ArgumentList "/i `"$installer`" /quiet" -Wait
        Write-Host "✅ PuTTY安装完成" -ForegroundColor Green
    } else {
        Write-Host "❌ 需要PuTTY才能继续" -ForegroundColor Red
        exit
    }
} else {
    Write-Host "✅ PuTTY已安装" -ForegroundColor Green
}

# 步骤2：检查端口占用
Write-Host "`n步骤2: 检查端口占用..." -ForegroundColor Green
$ports = @(7070, 8080, 3000, 8082, 9090)
foreach ($port in $ports) {
    $process = Get-NetTCPConnection -LocalPort $port -ErrorAction SilentlyContinue
    if ($process) {
        Write-Host "⚠️  端口 $port 被进程 $($process.OwningProcess) 占用" -ForegroundColor Yellow
        $killChoice = Read-Host "是否停止占用进程? (Y/N)"
        if ($killChoice -eq 'Y' -or $killChoice -eq 'y') {
            Stop-Process -Id $process.OwningProcess -Force -ErrorAction SilentlyContinue
            Write-Host "✅ 已停止占用端口 $port 的进程" -ForegroundColor Green
        }
    } else {
        Write-Host "✅ 端口 $port 可用" -ForegroundColor Green
    }
}

# 步骤3：创建PuTTY配置文件
Write-Host "`n步骤3: 创建PuTTY配置文件..." -ForegroundColor Green
$puttyConfig = @"
Windows Registry Editor Version 5.00

[HKEY_CURRENT_USER\Software\SimonTatham\PuTTY\Sessions\医小伴服务器]
"HostName"="122.51.179.136"
"Protocol"="ssh"
"PortNumber"=dword:00000016
"UserName"="root"
"PublicKeyFile"=""
"PortForwardings"="L7070=localhost:7070,L8080=localhost:8080,L3000=localhost:3000"
"ConnectionSharing"=dword:00000000
"SSHManualHostKeys"="ssh-ed25519 255 SHA256:YOUR_SERVER_KEY_HERE"
"Present"=dword:00000001
"LogFileName"="putty.log"
"LogType"=dword:00000000
"LogFileClash"=dword:ffffffff
"LogFlush"=dword:00000001
"SSHLogOmitPasswords"=dword:00000001
"SSHLogOmitData"=dword:00000000
"TerminalType"="xterm"
"TerminalSpeed"="38400,38400"
"TerminalModes"="CS7=A,CS8=A,DISCARD=A,DSUSP=A,ECHO=A,ECHOCTL=A,ECHOE=A,ECHOK=A,ECHOKE=A,ECHONL=A,EOF=A,EOL=A,EOL2=A,ERASE=A,FLUSH=A,ICANON=A,ICRNL=A,IEXTEN=A,IGNCR=A,IGNPAR=A,IMAXBEL=A,INLCR=A,INPCK=A,ISIG=A,ISTRIP=A,IUCLC=A,IXANY=A,IXOFF=A,IXON=A,KILL=A,LNEXT=A,NOFLSH=A,OCRNL=A,OLCUC=A,ONLCR=A,ONLRET=A,ONOCR=A,OPOST=A,PARENB=A,PARMRK=A,PARODD=A,PENDIN=A,QUIT=A,REPRINT=A,START=A,STATUS=A,STOP=A,SUSP=A,SWTCH=A,TOSTOP=A,WERASE=A,XCASE=A"
"AddressFamily"=dword:00000000
"CloseOnExit"=dword:00000001
"WarnOnClose"=dword:00000000
"PingInterval"=dword:00000000
"PingIntervalSecs"=dword:00000000
"TCPNoDelay"=dword:00000001
"TCPKeepalives"=dword:00000000
"RFCEnviron"=dword:00000000
"PassiveTelnet"=dword:00000000
"BackspaceIsDelete"=dword:00000001
"RXVTHomeEnd"=dword:00000000
"LinuxFunctionKeys"=dword:00000000
"NoApplicationKeys"=dword:00000000
"NoApplicationCursors"=dword:00000000
"NoMouseReporting"=dword:00000000
"NoRemoteResize"=dword:00000000
"NoAltScreen"=dword:00000000
"NoRemoteWinTitle"=dword:00000000
"RemoteQTitleAction"=dword:00000001
"NoDBackspace"=dword:00000000
"NoRemoteCharset"=dword:00000000
"ApplicationCursorKeys"=dword:00000000
"ApplicationKeypad"=dword:00000000
"NetHackKeypad"=dword:00000000
"AltF4"=dword:00000001
"AltSpace"=dword:00000000
"AltOnly"=dword:00000000
"Locale"=dword:00000409
"iSubSys"=dword:00000000
"ScrollbackLines"=dword:00002710
"DECOriginMode"=dword:00000000
"AutoWrapMode"=dword:00000001
"LFImpliesCR"=dword:00000000
"CRImpliesLF"=dword:00000000
"DisableArabicShaping"=dword:00000000
"DisableBidi"=dword:00000000
"WinNameAlways"=dword:00000001
"WinTitle"="医小伴服务器"
"TermWidth"=dword:00000050
"TermHeight"=dword:00000018
"Font"="Courier New"
"FontHeight"=dword:0000000a
"FontCharSet"=dword:00000000
"FontQuality"=dword:00000000
"FontVTMode"=dword:00000004
"UseSystemColours"=dword:00000000
"TryPalette"=dword:00000000
"ANSIColour"=dword:00000001
"Xterm256Colour"=dword:00000001
"TrueColour"=dword:00000001
"BoldAsColour"=dword:00000001
"Colour0"="187,187,187"
"Colour1"="255,255,255"
"Colour2"="0,0,0"
"Colour3"="85,85,85"
"Colour4"="0,0,0"
"Colour5"="0,255,0"
"Colour6"="0,0,0"
"Colour7"="85,85,85"
"Colour8"="187,0,0"
"Colour9"="255,85,85"
"Colour10"="0,187,0"
"Colour11"="85,255,85"
"Colour12"="187,187,0"
"Colour13"="255,255,85"
"Colour14"="0,0,187"
"Colour15"="85,85,255"
"Colour16"="187,0,187"
"Colour17"="255,85,255"
"Colour18"="0,187,187"
"Colour19"="85,255,255"
"Colour20"="187,187,187"
"Colour21"="255,255,255"
"RawCNP"=dword:00000000
"PasteRTF"=dword:00000000
"MouseIsXterm"=dword:00000000
"RectSelect"=dword:00000000
"PasteControls"=dword:00000000
"MouseOverride"=dword:00000001
"Wordness0"="0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0"
"Wordness32"="0,1,2,1,1,1,1,1,1,1,1,1,1,2,2,2,2,2,2,2,2,2,2,2,2,2,1,1,1,1,1,1"
"Wordness64"="1,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,1,1,1,1,2"
"Wordness96"="1,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,1,1,1,1,1"
"Wordness128"="0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0"
"Wordness160"="0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0"
"Wordness192"="0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0"
"Wordness224"="0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0"
"LineCodePage"="UTF-8"
"CJKAmbigWide"=dword:00000000
"UTF8Override"=dword:00000001
"Printer"=""
"CapsLockCyr"=dword:00000000
"ScrollBar"=dword:00000001
"ScrollBarFullScreen"=dword:00000000
"ScrollOnKey"=dword:00000000
"ScrollOnDisp"=dword:00000001
"EraseToScrollback"=dword:00000001
"LockSize"=dword:00000000
"BCE"=dword:00000001
"BlinkText"=dword:00000000
"X11Forward"=dword:00000000
"X11Display"=""
"X11AuthType"=dword:00000001
"X11AuthFile"=""
"LocalPortAcceptAll"=dword:00000000
"RemotePortAcceptAll"=dword:00000000
"Portable"=dword:00000000
"BugIgnore1"=dword:00000000
"BugPlainPW1"=dword:00000000
"BugRSA1"=dword:00000000
"BugIgnore2"=dword:00000000
"BugHMAC2"=dword:00000000
"BugDeriveKey2"=dword:00000000
"BugRSAPad2"=dword:00000000
"BugPKSessID2"=dword:00000000
"BugRekey2"=dword:00000000
"BugMaxPkt2"=dword:00000000
"BugOldGex2"=dword:00000000
"BugWinadj"=dword:00000000
"BugChanReq"=dword:00000000
"StampUtmp"=dword:00000001
"LoginShell"=dword:00000001
"ScrollbarOnLeft"=dword:00000000
"BoldFont"=""
"BoldFontHeight"=dword:00000000
"BoldFontCharSet"=dword:00000000
"BoldFontQuality"=dword:00000000
"WideFont"=""
"WideFontHeight"=dword:00000000
"WideFontCharSet"=dword:00000000
"WideFontQuality"=dword:00000000
"WideBoldFont"=""
"WideBoldFontHeight"=dword:00000000
"WideBoldFontCharSet"=dword:00000000
"WideBoldFontQuality"=dword:00000000
"ShadowBold"=dword:00000000
"ShadowBoldOffset"=dword:00000001
"SerialLine"="COM1"
"SerialSpeed"=dword:00002580
"SerialDataBits"=dword:00000008
"SerialStopHalfbits"=dword:00000002
"SerialParity"=dword:00000000
"SerialFlowControl"=dword:00000001
"WindowClass"=""
"ConnectionSharingUpstream"=dword:00000000
"ConnectionSharingDownstream"=dword:00000000
"SSH2DES"=dword:00000000
"SSHAutoVersion"=dword:00000002
"Kex"="ecdh,dh-gex-sha1,dh-group14-sha1,rsa,wtf"
"RekeyTime"=dword:0000003c
"RekeyBytes"="1G"
"SshNoAuth"=dword:00000000
"SshBanner"=dword:00000001
"AuthTIS"=dword:00000000
"AuthKI"=dword:00000001
"AuthGSSAPI"=dword:00000001
"AuthGSSAPIKEX"=dword:00000001
"GSSLibs"="gssapi32"
"GSSCustom"=""
"LogHost"=""
"ProxyDNS"=dword:00000001
"ProxyLocalhost"=dword:00000000
"ProxyMethod"=dword:00000000
"ProxyHost"="proxy"
"ProxyPort"=dword:00000050
"ProxyUsername"=""
"ProxyPassword"=""
"ProxyTelnetCommand"="connect %host %port\\n"
"ProxyLogToTerm"=dword:00000001
"Environment"=""
"UserNameFromEnvironment"=dword:00000000
"Compression"=dword:00000000
"TryAgent"=dword:00000001
"AgentFwd"=dword:00000000
"ChangeUsername"=dword:00000000
"Cipher"="aes,blowfish,3des,WARN