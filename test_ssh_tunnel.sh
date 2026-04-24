#!/bin/bash

echo "================================================"
echo "🔍 SSH隧道测试脚本"
echo "================================================"

echo ""
echo "1. 检查SSH服务状态..."
systemctl status sshd --no-pager | head -10

echo ""
echo "2. 检查SSH配置..."
grep -i "AllowTcpForwarding\|GatewayPorts" /etc/ssh/sshd_config

echo ""
echo "3. 检查服务运行状态..."
echo "   端口 5050: $(netstat -tln | grep ':5050' | wc -l) 个监听"
echo "   端口 7070: $(netstat -tln | grep ':7070' | wc -l) 个监听"
echo "   端口 3000: $(netstat -tln | grep ':3000' | wc -l) 个监听"

echo ""
echo "4. 本地连接测试..."
curl -s -o /dev/null -w "localhost:5050 -> %{http_code}\n" http://localhost:5050/test_connection.html
curl -s -o /dev/null -w "localhost:7070 -> %{http_code}\n" http://localhost:7070/direct_test.html
curl -s -o /dev/null -w "localhost:3000/health -> %{http_code}\n" http://localhost:3000/health

echo ""
echo "5. 检查SSH连接..."
echo "   当前SSH连接数: $(who | wc -l)"
echo "   活动SSH会话:"
netstat -tpn | grep sshd

echo ""
echo "================================================"
echo "🎯 Windows端测试命令:"
echo "================================================"
echo ""
echo "# 方法1: 使用OpenSSH"
echo "C:\Windows\System32\OpenSSH\ssh.exe -v -L 5050:localhost:5050 root@122.51.179.136"
echo ""
echo "# 方法2: 使用PuTTY plink"
echo '"C:\Program Files\PuTTY\plink.exe" -L 5050:localhost:5050 root@122.51.179.136'
echo ""
echo "# 方法3: 测试连接"
echo "Test-NetConnection localhost -Port 5050"
echo "telnet localhost 5050"
echo ""
echo "================================================"