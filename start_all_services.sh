#!/bin/bash

echo "================================================"
echo "🚀 启动医小伴陪诊APP所有服务"
echo "================================================"

echo ""
echo "1. 停止旧服务..."
pkill -f "node.*server" 2>/dev/null
pkill -f "python.*http.server" 2>/dev/null
sleep 2

echo ""
echo "2. 启动后端API服务 (端口: 3000)..."
cd backend
node src/server.js &
echo "   PID: $! - http://localhost:3000"
cd ..

echo ""
echo "3. 启动管理后台 (端口: 8080)..."
cd admin
python3 -m http.server 8080 --directory dist &
echo "   PID: $! - http://localhost:8080"
cd ..

echo ""
echo "4. 启动测试页面 (端口: 8000)..."
python3 -m http.server 8000 --bind 0.0.0.0 &
echo "   PID: $! - http://localhost:8000/test_access.html"

echo ""
echo "5. 启动欢迎页面 (端口: 8082)..."
python3 -m http.server 8082 --bind 0.0.0.0 &
echo "   PID: $! - http://localhost:8082/welcome_test.html"

echo ""
echo "6. 等待服务启动..."
sleep 5

echo ""
echo "7. 验证服务..."
echo "   端口 3000: $(netstat -tln | grep ':3000' | wc -l) 个监听"
echo "   端口 8080: $(netstat -tln | grep ':8080' | wc -l) 个监听"
echo "   端口 8000: $(netstat -tln | grep ':8000' | wc -l) 个监听"
echo "   端口 8082: $(netstat -tln | grep ':8082' | wc -l) 个监听"

echo ""
echo "8. 本地测试..."
curl -s -o /dev/null -w "localhost:3000/health -> %{http_code}\n" http://localhost:3000/health
curl -s -o /dev/null -w "localhost:8080 -> %{http_code}\n" http://localhost:8080
curl -s -o /dev/null -w "localhost:8082 -> %{http_code}\n" http://localhost:8082

echo ""
echo "================================================"
echo "🎯 SSH隧道配置指南:"
echo "================================================"
echo "在PuTTY中配置隧道:"
echo "1. Connection → SSH → Tunnels"
echo "2. 添加以下转发:"
echo "   - Source: 8080 → Destination: localhost:8080"
echo "   - Source: 3000 → Destination: localhost:3000"
echo "   - Source: 8082 → Destination: localhost:8082"
echo "3. 保存并连接"
echo "4. 登录: root / yixiaoban123"
echo ""
echo "📱 浏览器访问:"
echo "   http://localhost:8082/welcome_test.html"
echo "   http://localhost:8080"
echo "   http://localhost:3000/health"
echo "================================================"