# 🏥 医小伴陪诊APP - SSH隧道完整图文指南

## 📋 问题概述
无法通过SSH隧道访问医小伴陪诊APP服务。

## 🎯 解决方案
使用PuTTY建立SSH隧道，将远程服务器的端口转发到本地。

## 🚀 详细步骤

### 第一步：下载和安装PuTTY

1. **访问官网**：https://www.putty.org/
2. **下载安装包**：选择 `putty-64bit-0.81-installer.msi`
3. **安装PuTTY**：
   - 运行安装程序
   - 按照向导完成安装
   - 建议安装到默认位置

### 第二步：配置PuTTY连接

#### 1. 打开PuTTY
![打开PuTTY](https://via.placeholder.com/600x400/667eea/ffffff?text=PuTTY+主界面)

#### 2. 基本配置
```
Host Name: 122.51.179.136
Port: 22
Connection type: SSH
```

#### 3. 配置隧道（关键步骤！）
1. 左侧选择 `Connection` → `SSH` → `Tunnels`
2. **添加以下隧道**（每个都要单独添加）：

   **隧道1**（直接测试）：
   ```
   Source port: 7070
   Destination: localhost:7070
   ```
   **点击 `Add`**

   **隧道2**（管理后台）：
   ```
   Source port: 8080
   Destination: localhost:8080
   ```
   **点击 `Add`**

   **隧道3**（API服务）：
   ```
   Source port: 3000
   Destination: localhost:3000
   ```
   **点击 `Add`**

3. **检查添加的隧道**：
   - 应该看到列表中有：
     ```
     L7070 localhost:7070
     L8080 localhost:8080
     L3000 localhost:3000
     ```

#### 4. 保存配置
1. 回到 `Session`
2. Saved Sessions: 输入 `医小伴服务器`
3. 点击 `Save`
4. 点击 `Open`

### 第三步：连接服务器

#### 1. 接受安全警告
第一次连接会显示安全警告：
```
The server's host key is not cached in the registry...
```
- **点击"是(Y)"** 或 "Accept"

#### 2. 登录服务器
```
login as: root
password: yixiaoban123
```

#### 3. 验证登录成功
登录后应该看到：
```
Welcome to Ubuntu...
root@VM-0-12-ubuntu:~#
```

### 第四步：测试连接

#### 在浏览器中访问：
1. **直接测试页面**：http://localhost:7070/direct_test.html
2. **管理后台**：http://localhost:8080
3. **API健康检查**：http://localhost:3000/health

#### 在PowerShell中测试：
```powershell
# 检查端口是否监听
Test-NetConnection localhost -Port 7070

# 如果显示 TcpTestSucceeded: True，说明隧道正常
```

## 🔧 故障排除

### 问题1：PuTTY连接失败
**可能原因**：
1. 网络连接问题
2. 服务器IP地址错误
3. 防火墙阻止

**解决方案**：
```powershell
# 测试网络连接
ping 122.51.179.136

# 测试SSH端口
Test-NetConnection 122.51.179.136 -Port 22
```

### 问题2：浏览器无法访问
**可能原因**：
1. SSH隧道未建立
2. 本地端口被占用
3. 浏览器缓存问题

**解决方案**：
```powershell
# 检查端口占用
netstat -ano | findstr :7070

# 如果被占用，停止进程
Stop-Process -Id (Get-NetTCPConnection -LocalPort 7070).OwningProcess -Force

# 清除浏览器缓存
# Chrome/Firefox/Edge: Ctrl+Shift+Delete
```

### 问题3：密码错误
**正确密码**：`yixiaoban123`

如果密码错误：
1. 确认输入正确
2. 密码输入时不会显示字符，正常输入即可
3. 按Enter提交

## 🎯 备用方案：使用Windows内置SSH

如果PuTTY有问题，使用Windows PowerShell：

```powershell
# 建立SSH隧道
ssh -L 7070:localhost:7070 -L 8080:localhost:8080 -L 3000:localhost:3000 root@122.51.179.136

# 输入密码: yixiaoban123
```

## 📱 访问地址汇总

### 通过SSH隧道访问：
- **直接测试**：http://localhost:7070/direct_test.html
- **管理后台**：http://localhost:8080
- **API服务**：http://localhost:3000/health
- **API文档**：http://localhost:3000/api

### 测试账号：
- **患者**：手机号 `13800138001` 密码 `patient123`
- **陪诊师**：手机号 `13900139001` 密码 `companion123`
- **管理员**：手机号 `13800000000` 密码 `admin123`

## ⚠️ 重要提醒

1. **保持PuTTY窗口打开**：SSH隧道需要持续连接
2. **不要关闭登录窗口**：关闭窗口会断开隧道
3. **首次连接接受密钥**：点击"是(Y)"接受服务器密钥
4. **密码不显示**：输入密码时不会显示字符，正常输入即可

## 🆘 如果还是无法解决

请提供以下信息：
1. PuTTY连接截图
2. 浏览器错误截图
3. PowerShell测试结果

**联系技术支持**：提供上述信息，我们会帮你远程解决问题。

---

## ✅ 成功标志

如果一切正常，你应该能看到：
1. ✅ PuTTY显示登录成功提示
2. ✅ 浏览器显示测试页面
3. ✅ 可以访问管理后台
4. ✅ API返回健康状态

**现在开始配置吧！** 🚀