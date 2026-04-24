#!/bin/bash
cd /root/.openclaw/workspace/yixiaoban_app
echo "停止现有服务..."
pkill -f "node.*payment_dev" 2>/dev/null
sleep 1
echo "启动支付开发服务器..."
NODE_PATH=./backend/node_modules node payment_dev_server.js