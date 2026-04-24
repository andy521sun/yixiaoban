#!/bin/bash

echo "================================================"
echo "🔍 医小伴陪诊APP - 网络诊断工具"
echo "================================================"

echo ""
echo "1. 系统信息:"
echo "   主机名: $(hostname)"
echo "   IP地址: $(hostname -I)"
echo "   时间: $(date)"

echo ""
echo "2. 服务状态:"
echo "   后端API (3000): $(ps aux | grep 'node.*server' | grep -v grep | wc -l) 个进程"
echo "   管理后台 (8080): $(ps aux | grep 'python.*http.server.*8080' | grep -v grep | wc -l) 个进程"
echo "   测试页面 (8000): $(ps aux | grep 'python.*http.server.*8000' | grep -v grep | wc -l) 个进程"

echo ""
echo "3. 端口监听状态:"
netstat -tlnp | grep -E "(3000|8080|8000)" | while read line; do
    echo "   $line"
done

echo ""
echo "4. 防火墙状态:"
if command -v ufw &> /dev/null; then
    sudo ufw status
else
    echo "   UFW未安装"
fi

echo ""
echo "5. 本地访问测试:"
echo "   http://localhost:3000/health -> $(curl -s -o /dev/null -w "%{http_code}" http://localhost:3000/health)"
echo "   http://localhost:8080 -> $(curl -s -o /dev/null -w "%{http_code}" http://localhost:8080)"
echo "   http://localhost:8000 -> $(curl -s -o /dev/null -w "%{http_code}" http://localhost:8000)"

echo ""
echo "6. IP地址访问测试:"
for ip in $(hostname -I); do
    echo "   使用IP: $ip"
    echo "   http://$ip:3000/health -> $(curl -s -o /dev/null -w "%{http_code}" http://$ip:3000/health 2>/dev/null || echo "失败")"
    echo "   http://$ip:8080 -> $(curl -s -o /dev/null -w "%{http_code}" http://$ip:8080 2>/dev/null || echo "失败")"
    echo "   http://$ip:8000 -> $(curl -s -o /dev/null -w "%{http_code}" http://$ip:8000 2>/dev/null || echo "失败")"
    echo ""
done

echo ""
echo "7. 网络接口信息:"
ip addr show | grep -E "inet |state" | grep -v "127.0.0.1" | while read line; do
    echo "   $line"
done

echo ""
echo "8. 路由信息:"
ip route | head -5

echo ""
echo "================================================"
echo "🎯 访问建议:"
echo "================================================"

IPS=$(hostname -I)
echo "请尝试以下地址:"
for ip in $IPS; do
    echo ""
    echo "📱 使用IP地址: $ip"
    echo "   管理后台: http://$ip:8080"
    echo "   API健康检查: http://$ip:3000/health"
    echo "   测试页面: http://$ip:8000/test_access.html"
done

echo ""
echo "🔧 如果都无法访问，可能是:"
echo "   1. 网络隔离（服务器在内网）"
echo "   2. 云服务器安全组未开放端口"
echo "   3. 本地防火墙阻止"
echo "   4. 浏览器/网络代理问题"

echo ""
echo "🔄 重启服务命令:"
echo "   cd yixiaoban_app && ./restart_services.sh"

echo "================================================"