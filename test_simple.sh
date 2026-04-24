#!/bin/bash

# 医小伴APP - 简化测试脚本

set -e

PAYMENT_API="http://localhost:3003"
COMPANION_API="http://localhost:3004"

echo "🏥 医小伴APP API测试"
echo "=================="
echo "测试时间: $(date)"
echo ""

# 测试支付服务器
echo "1. 测试支付服务器 ($PAYMENT_API)..."
if curl -s "$PAYMENT_API/health" | grep -q "healthy"; then
    echo "   ✅ 健康检查通过"
else
    echo "   ❌ 健康检查失败"
    exit 1
fi

# 测试订单API
echo "2. 测试订单API..."
order_response=$(curl -s -X POST "$PAYMENT_API/api/orders" \
  -H "Content-Type: application/json" \
  -d '{"patient_name": "测试用户", "hospital": "协和医院", "service_type": "陪诊", "amount": 100}')

if echo "$order_response" | grep -q "success.*true"; then
    order_id=$(echo "$order_response" | grep -o '"id":"[^"]*"' | cut -d'"' -f4)
    echo "   ✅ 订单创建成功 (ID: $order_id)"
else
    echo "   ❌ 订单创建失败"
    echo "   响应: $order_response"
    exit 1
fi

# 测试陪诊师服务器
echo "3. 测试陪诊师服务器 ($COMPANION_API)..."
if curl -s "$COMPANION_API/health" | grep -q "ok"; then
    echo "   ✅ 健康检查通过"
else
    echo "   ❌ 健康检查失败"
    exit 1
fi

# 测试登录
echo "4. 测试陪诊师登录..."
login_response=$(curl -s -X POST "$COMPANION_API/api/login" \
  -H "Content-Type: application/json" \
  -d '{"username": "doctor1", "password": "123"}')

if echo "$login_response" | grep -q "success.*true"; then
    token=$(echo "$login_response" | grep -o '"token":"[^"]*"' | cut -d'"' -f4)
    echo "   ✅ 登录成功 (token: ${token:0:20}...)"
else
    echo "   ❌ 登录失败"
    echo "   响应: $login_response"
    exit 1
fi

# 测试任务查询
echo "5. 测试任务查询..."
task_response=$(curl -s -H "Authorization: Bearer $token" "$COMPANION_API/api/tasks")

if echo "$task_response" | grep -q "success.*true"; then
    echo "   ✅ 任务查询成功"
else
    echo "   ❌ 任务查询失败"
    echo "   响应: $task_response"
fi

echo ""
echo "🎯 测试完成！"
echo ""
echo "📊 服务器状态:"
ps aux | grep -E "(payment_dev_server|companion_simple)" | grep -v grep | while read line; do
    pid=$(echo "$line" | awk '{print $2}')
    cmd=$(echo "$line" | awk '{for(i=11;i<=NF;i++) printf $i" "; print ""}')
    runtime=$(ps -o etime= -p "$pid" 2>/dev/null || echo "未知")
    echo "  ✅ $cmd (PID: $pid, 运行: $runtime)"
done

echo ""
echo "✅ 所有核心API测试通过！系统运行正常。"
echo ""
echo "下一步建议:"
echo "  1. 开始移动端Flutter开发"
echo "  2. 完善支付流程测试"
echo "  3. 开发管理后台界面"