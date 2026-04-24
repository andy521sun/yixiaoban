#!/bin/bash

echo "================================================"
echo "🔧 修复localhost访问问题"
echo "================================================"

echo ""
echo "1. 停止所有相关服务..."
pkill -f "node.*server" 2>/dev/null
pkill -f "python.*http.server" 2>/dev/null
sleep 2

echo ""
echo "2. 检查端口占用..."
echo "   端口 3000: $(lsof -i:3000 2>/dev/null | wc -l) 个进程"
echo "   端口 8080: $(lsof -i:8080 2>/dev/null | wc -l) 个进程"
echo "   端口 8000: $(lsof -i:8000 2>/dev/null | wc -l) 个进程"

echo ""
echo "3. 强制释放端口..."
fuser -k 3000/tcp 2>/dev/null
fuser -k 8080/tcp 2>/dev/null
fuser -k 8000/tcp 2>/dev/null
sleep 1

echo ""
echo "4. 启动后端API服务..."
cd backend
node src/server.js &
BACKEND_PID=$!
echo "   后端服务PID: $BACKEND_PID (端口: 3000)"
cd ..

echo ""
echo "5. 启动管理后台..."
cd admin
python3 -m http.server 8080 --directory dist &
ADMIN_PID=$!
echo "   管理后台PID: $ADMIN_PID (端口: 8080)"
cd ..

echo ""
echo "6. 启动测试页面..."
python3 -m http.server 8000 --bind 0.0.0.0 &
TEST_PID=$!
echo "   测试页面PID: $TEST_PID (端口: 8000)"

echo ""
echo "7. 等待服务启动..."
sleep 5

echo ""
echo "8. 测试连接..."
echo "   测试 localhost:3000/health ..."
curl -s -o /dev/null -w "   -> HTTP状态码: %{http_code}\n" http://localhost:3000/health

echo "   测试 localhost:8080 ..."
curl -s -o /dev/null -w "   -> HTTP状态码: %{http_code}\n" http://localhost:8080

echo "   测试 localhost:8000 ..."
curl -s -o /dev/null -w "   -> HTTP状态码: %{http_code}\n" http://localhost:8000

echo ""
echo "9. 检查服务状态..."
ps -p $BACKEND_PID,$ADMIN_PID,$TEST_PID -o pid,cmd | grep -v PID

echo ""
echo "================================================"
echo "🎯 访问地址:"
echo "================================================"
echo ""
echo "如果上述测试显示200状态码，请尝试访问:"
echo "1. 管理后台: http://localhost:8080"
echo "2. API健康检查: http://localhost:3000/health"
echo "3. 测试页面: http://localhost:8000/test_access.html"
echo ""
echo "🔧 如果还是无法访问，请尝试:"
echo "   1. 清除浏览器缓存"
echo "   2. 使用无痕/隐私模式"
echo "   3. 尝试不同浏览器"
echo "   4. 检查本地防火墙设置"
echo ""
echo "📱 备用访问地址 (使用IP):"
echo "   http://127.0.0.1:8080"
echo "   http://127.0.0.1:3000/health"
echo "   http://127.0.0.1:8000/test_access.html"
echo "================================================"