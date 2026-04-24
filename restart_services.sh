#!/bin/bash

echo "================================================"
echo "🔄 医小伴陪诊APP - 服务重启工具"
echo "================================================"

echo ""
echo "停止所有服务..."
pkill -f "node.*server" 2>/dev/null
pkill -f "python.*http.server" 2>/dev/null
sleep 2

echo ""
echo "启动服务（使用常用端口）..."

echo "1. 启动后端API服务 (端口: 3000)..."
cd backend
node src/server.js &
BACKEND_PID=$!
cd ..

echo "2. 启动管理后台 (端口: 8080)..."
cd admin
python3 -m http.server 8080 --directory dist &
ADMIN_PID=$!
cd ..

echo "3. 启动测试页面 (端口: 8000)..."
python3 -m http.server 8000 --bind 0.0.0.0 &
TEST_PID=$!

echo ""
echo "等待服务启动..."
sleep 3

echo ""
echo "服务状态:"
echo "  后端API (PID: $BACKEND_PID) -> 端口 3000"
echo "  管理后台 (PID: $ADMIN_PID) -> 端口 8080"
echo "  测试页面 (PID: $TEST_PID) -> 端口 8000"

echo ""
echo "测试连接..."
echo "  http://localhost:3000/health -> $(curl -s -o /dev/null -w "%{http_code}" http://localhost:3000/health 2>/dev/null || echo "失败")"
echo "  http://localhost:8080 -> $(curl -s -o /dev/null -w "%{http_code}" http://localhost:8080 2>/dev/null || echo "失败")"
echo "  http://localhost:8000 -> $(curl -s -o /dev/null -w "%{http_code}" http://localhost:8000 2>/dev/null || echo "失败")"

echo ""
echo "================================================"
echo "🎯 访问地址:"
echo "================================================"

IPS=$(hostname -I)
echo "服务器IP地址:"
for ip in $IPS; do
    echo ""
    echo "📱 IP: $ip"
    echo "   管理后台: http://$ip:8080"
    echo "   API服务: http://$ip:3000"
    echo "   测试页面: http://$ip:8000/test_access.html"
done

echo ""
echo "🔧 如果无法访问，请尝试:"
echo "   1. 检查防火墙/安全组设置"
echo "   2. 使用SSH隧道: ssh -L 8080:localhost:8080 用户名@服务器IP"
echo "   3. 如果是云服务器，确保安全组开放端口 3000, 8080, 8000"

echo ""
echo "🛑 停止服务命令:"
echo "   pkill -f \"node.*server\" && pkill -f \"python.*http.server\""
echo "================================================"