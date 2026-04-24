#!/bin/bash

echo "================================================"
echo "🌐 医小伴陪诊APP - 公网访问诊断"
echo "================================================"

echo ""
echo "1. 获取公网IP地址..."
PUBLIC_IP=$(curl -s ifconfig.me)
echo "   公网IP: $PUBLIC_IP"

echo ""
echo "2. 检查服务状态..."
echo "   端口 3000 (API): $(netstat -tln | grep ':3000' | wc -l) 个监听"
echo "   端口 8080 (管理后台): $(netstat -tln | grep ':8080' | wc -l) 个监听"
echo "   端口 8000 (测试页面): $(netstat -tln | grep ':8000' | wc -l) 个监听"
echo "   端口 8888 (备用测试): $(netstat -tln | grep ':8888' | wc -l) 个监听"

echo ""
echo "3. 快速本地测试（5秒超时）..."
timeout 5 curl -s http://localhost:8080 >/dev/null && echo "   localhost:8080 -> ✅ 可访问" || echo "   localhost:8080 -> ❌ 超时"
timeout 5 curl -s http://localhost:3000/health >/dev/null && echo "   localhost:3000/health -> ✅ 可访问" || echo "   localhost:3000/health -> ❌ 超时"

echo ""
echo "4. 公网IP测试（10秒超时）..."
echo "   测试 $PUBLIC_IP:8080 ..."
timeout 10 curl -s "http://$PUBLIC_IP:8080" >/dev/null
if [ $? -eq 0 ]; then
    echo "   $PUBLIC_IP:8080 -> ✅ 可访问"
else
    echo "   $PUBLIC_IP:8080 -> ❌ 无法访问 (可能原因: 安全组/防火墙)"
fi

echo ""
echo "5. 检查防火墙..."
if command -v ufw >/dev/null; then
    echo "   UFW状态: $(sudo ufw status | head -1)"
else
    echo "   UFW未安装"
fi

echo ""
echo "6. 检查iptables规则..."
sudo iptables -L -n | grep -E "(8080|3000|8000|8888)" | head -5
if [ $? -ne 0 ]; then
    echo "   未找到相关iptables规则"
fi

echo ""
echo "================================================"
echo "🎯 解决方案建议:"
echo "================================================"

echo ""
echo "方案A: 配置云服务器安全组 (如果是云服务器)"
echo "   1. 登录云控制台 (腾讯云/阿里云)"
echo "   2. 找到'安全组'设置"
echo "   3. 添加入站规则:"
echo "      - 协议: TCP"
echo "      - 端口: 3000, 8080, 8000, 8888"
echo "      - 来源: 0.0.0.0/0 (或你的IP)"
echo "      - 策略: 允许"

echo ""
echo "方案B: 使用SSH隧道 (推荐)"
echo "   在你的电脑上执行:"
echo "   ssh -L 8080:localhost:8080 -L 3000:localhost:3000 root@$PUBLIC_IP"
echo "   然后访问:"
echo "   - 管理后台: http://localhost:8080"
echo "   - API服务: http://localhost:3000/health"

echo ""
echo "方案C: 临时开放端口"
echo "   在服务器上执行:"
echo "   sudo iptables -A INPUT -p tcp --dport 8080 -j ACCEPT"
echo "   sudo iptables -A INPUT -p tcp --dport 3000 -j ACCEPT"
echo "   sudo iptables -A INPUT -p tcp --dport 8000 -j ACCEPT"
echo "   sudo iptables -A INPUT -p tcp --dport 8888 -j ACCEPT"

echo ""
echo "方案D: 使用反向代理 (高级)"
echo "   安装nginx并配置:"
echo "   sudo apt install nginx"
echo "   配置 /etc/nginx/sites-available/yixiaoban"
echo "   将端口80代理到3000和8080"

echo ""
echo "================================================"
echo "📞 需要的信息:"
echo "================================================"
echo "1. 这是云服务器吗？ (腾讯云/阿里云/AWS)"
echo "2. 你有云控制台访问权限吗？"
echo "3. 你可以使用SSH连接吗？"
echo "4. 错误信息是什么？ (截图或描述)"
echo "================================================"