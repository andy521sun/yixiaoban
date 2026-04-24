#!/bin/bash
cd /root/.openclaw/workspace/yixiaoban_app

echo "=== 启动医小伴APP开发服务器 ==="
echo "时间: $(date)"
echo ""

# 停止现有服务
echo "1. 停止现有服务..."
pkill -f "node.*(payment_dev|companion_simple)" 2>/dev/null
sleep 2

# 启动支付服务器
echo "2. 启动支付服务器 (端口: 3003)..."
NODE_PATH=./backend/node_modules node payment_dev_server.js &
PAYMENT_PID=$!
echo "支付服务器PID: $PAYMENT_PID"
sleep 3

# 启动陪诊师服务器
echo "3. 启动陪诊师服务器 (端口: 3004)..."
NODE_PATH=./backend/node_modules node companion_simple.js &
COMPANION_PID=$!
echo "陪诊师服务器PID: $COMPANION_PID"
sleep 3

# 保存PID
echo $PAYMENT_PID > payment.pid
echo $COMPANION_PID > companion.pid

# 测试连接
echo ""
echo "4. 测试服务器连接..."
echo "支付服务器 (3003):"
curl -s -m 3 "http://localhost:3003/health" && echo " ✅ 正常" || echo " ❌ 失败"

echo "陪诊师服务器 (3004):"
curl -s -m 3 "http://localhost:3004/health" && echo " ✅ 正常" || echo " ❌ 失败"

echo ""
echo "=== 服务器信息 ==="
echo "支付API: http://localhost:3003"
echo "陪诊师API: http://localhost:3004"
echo ""
echo "=== 测试命令 ==="
echo "支付测试: curl http://localhost:3003/api/orders"
echo "陪诊师登录: curl -X POST http://localhost:3004/api/login -d '{\"username\":\"doctor1\",\"password\":\"123\"}'"
echo ""
echo "服务器启动完成！"