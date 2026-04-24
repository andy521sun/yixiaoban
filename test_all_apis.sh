#!/bin/bash

# 医小伴APP - API测试脚本
# 直接测试各个API端点

set -e

# 服务器配置
PAYMENT_API="http://localhost:3003"
COMPANION_API="http://localhost:3004"

# 颜色定义
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 测试函数
test_endpoint() {
    local name="$1"
    local url="$2"
    local method="${3:-GET}"
    local data="$4"
    
    echo -n "测试 ${name}... "
    
    if [ -n "$data" ]; then
        response=$(curl -s -X "$method" "$url" -H "Content-Type: application/json" -d "$data" 2>/dev/null || echo "ERROR")
    else
        response=$(curl -s -X "$method" "$url" 2>/dev/null || echo "ERROR")
    fi
    
    if [ "$response" = "ERROR" ]; then
        echo -e "${RED}❌ 连接失败${NC}"
        return 1
    elif echo "$response" | grep -q "<html>"; then
        echo -e "${RED}❌ 返回HTML错误${NC}"
        return 1
    else
        echo -e "${GREEN}✅ 成功${NC}"
        # 打印简洁的响应信息
        echo "   响应: $(echo $response | cut -c1-100)..."
        return 0
    fi
}

echo "🏥 医小伴APP API测试开始 🏥"
echo "测试时间: $(date)"
echo "服务器配置:"
echo "  支付API: $PAYMENT_API"
echo "  陪诊师API: $COMPANION_API"
echo ""

# 测试支付服务器健康检查
test_endpoint "支付服务器健康检查" "$PAYMENT_API/health"

# 测试陪诊师服务器健康检查
test_endpoint "陪诊师服务器健康检查" "$COMPANION_API/health"

echo ""
echo "📋 开始功能测试..."
echo ""

# 测试支付服务器功能
echo "💰 支付服务器功能测试:"
test_endpoint "获取订单列表" "$PAYMENT_API/api/orders"

# 创建测试订单
test_endpoint "创建订单" "$PAYMENT_API/api/orders" "POST" '{"patient_name": "测试用户", "hospital": "协和医院", "service_type": "陪诊", "amount": 100}'

echo ""

# 测试陪诊师服务器功能
echo "👨⚕️ 陪诊师服务器功能测试:"
# 先登录获取token
login_response=$(curl -s -X POST "$COMPANION_API/api/login" -H "Content-Type: application/json" -d '{"username": "doctor1", "password": "123"}')
token=$(echo $login_response | grep -o '"token":"[^"]*"' | cut -d'"' -f4)

if [ -n "$token" ]; then
    echo "   登录成功，token: ${token:0:20}..."
    test_endpoint "获取任务列表" "$COMPANION_API/api/tasks" "GET" "" "Authorization: Bearer $token"
else
    echo -e "${RED}❌ 登录失败${NC}"
fi

echo ""

# 测试支付统计
test_endpoint "支付统计" "$PAYMENT_API/api/payment/statistics"

echo ""
echo "🎯 测试完成！"

# 显示服务器状态
echo ""
echo "📊 服务器状态:"
ps aux | grep -E "(payment_dev_server|companion_simple)" | grep -v grep | while read line; do
    pid=$(echo $line | awk '{print $2}')
    cmd=$(echo $line | awk '{for(i=11;i<=NF;i++) printf $i" "; print ""}')
    runtime=$(ps -o etime= -p $pid 2>/dev/null || echo "未知")
    echo "  PID $pid: $cmd (运行时间: $runtime)"
done

# 测试API文档
echo "2. 测试API文档..."
curl -s http://localhost:3000/api | python3 -c "
import json, sys
data = json.load(sys.stdin)
if 'endpoints' in data:
    print('✅ API文档可访问')
    print('   可用端点:', list(data['endpoints'].keys()))
else:
    print('❌ API文档异常')
"
echo ""

# 测试用户登录
echo "3. 测试用户登录..."
curl -s -X POST http://localhost:3000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"phone": "13800138000", "password": "123456"}' | python3 -c "
import json, sys
data = json.load(sys.stdin)
if data.get('success') == True:
    print('✅ 用户登录成功')
    user = data.get('data', {})
    print(f'   用户ID: {user.get(\"user_id\")}')
    print(f'   用户名: {user.get(\"name\")}')
else:
    print('❌ 用户登录失败')
    print(data.get('message', '未知错误'))
"
echo ""

# 测试医院列表
echo "4. 测试医院列表..."
curl -s "http://localhost:3000/api/hospitals" | python3 -c "
import json, sys
data = json.load(sys.stdin)
if data.get('success') == True:
    hospitals = data.get('data', [])
    print(f'✅ 获取医院列表成功，共 {len(hospitals)} 家医院')
    for i, hosp in enumerate(hospitals[:3], 1):
        print(f'   {i}. {hosp.get(\"name\")} ({hosp.get(\"level\")})')
    if len(hospitals) > 3:
        print(f'   ... 还有 {len(hospitals)-3} 家医院')
else:
    print('❌ 获取医院列表失败')
    print(data.get('message', '未知错误'))
"
echo ""

# 测试陪诊师列表
echo "5. 测试陪诊师列表..."
curl -s "http://localhost:3000/api/companions" | python3 -c "
import json, sys
data = json.load(sys.stdin)
if data.get('success') == True:
    companions = data.get('data', [])
    print(f'✅ 获取陪诊师列表成功，共 {len(companions)} 位陪诊师')
    for i, comp in enumerate(companions[:3], 1):
        print(f'   {i}. {comp.get(\"name\")} ({comp.get(\"level\")}) - {comp.get(\"specialty\")}')
    if len(companions) > 3:
        print(f'   ... 还有 {len(companions)-3} 位陪诊师')
else:
    print('❌ 获取陪诊师列表失败')
    print(data.get('message', '未知错误'))
"
echo ""

# 测试订单列表
echo "6. 测试订单列表..."
curl -s "http://localhost:3000/api/orders?user_id=user_001" | python3 -c "
import json, sys
try:
    data = json.load(sys.stdin)
    if data.get('success') == True:
        orders = data.get('data', [])
        print(f'✅ 获取订单列表成功，共 {len(orders)} 个订单')
        for i, order in enumerate(orders, 1):
            status_map = {'pending': '待支付', 'confirmed': '待服务', 'completed': '已完成', 'cancelled': '已取消'}
            status = status_map.get(order.get('status'), order.get('status'))
            print(f'   {i}. 订单 {order.get(\"id\")} - ¥{order.get(\"price\")} - {status}')
    else:
        print('❌ 获取订单列表失败')
        print(f'   错误信息: {data.get(\"message\", \"未知错误\")}')
except Exception as e:
    print('❌ 订单API响应异常')
    print(f'   异常信息: {e}')
"
echo ""

# 测试订单详情
echo "7. 测试订单详情..."
curl -s "http://localhost:3000/api/orders/order_001" | python3 -c "
import json, sys
try:
    data = json.load(sys.stdin)
    if data.get('success') == True:
        order = data.get('data', {})
        print('✅ 获取订单详情成功')
        print(f'   订单号: {order.get(\"id\")}')
        print(f'   医院: {order.get(\"hospital_name\")}')
        print(f'   陪诊师: {order.get(\"companion_name\")}')
        print(f'   价格: ¥{order.get(\"price\")}')
        print(f'   状态: {order.get(\"status\")}')
    else:
        print('❌ 获取订单详情失败')
        print(f'   错误信息: {data.get(\"message\", \"未知错误\")}')
except Exception as e:
    print('❌ 订单详情API响应异常')
    print(f'   异常信息: {e}')
"
echo ""

# 测试订单统计
echo "8. 测试订单统计..."
curl -s "http://localhost:3000/api/orders/stats?user_id=user_001" | python3 -c "
import json, sys
try:
    data = json.load(sys.stdin)
    if data.get('success') == True:
        stats = data.get('data', {})
        print('✅ 获取订单统计成功')
        summary = stats.get('summary', {})
        print(f'   总订单数: {summary.get(\"total_orders\")}')
        print(f'   总金额: ¥{summary.get(\"total_amount\")}')
        print(f'   平均订单价: ¥{summary.get(\"avg_order_value\")}')
    else:
        print('❌ 获取订单统计失败')
        print(f'   错误信息: {data.get(\"message\", \"未知错误\")}')
except Exception as e:
    print('❌ 订单统计API响应异常')
    print(f'   异常信息: {e}')
"
echo ""

# 测试创建支付
echo "9. 测试创建支付..."
curl -s -X POST http://localhost:3000/api/payments/create \
  -H "Content-Type: application/json" \
  -d '{"order_id": "order_001", "amount": 229.00, "payment_method": "wechat"}' | python3 -c "
import json, sys
try:
    data = json.load(sys.stdin)
    if data.get('success') == True:
        payment = data.get('data', {})
        print('✅ 创建支付订单成功')
        print(f'   支付ID: {payment.get(\"payment_id\")}')
        print(f'   金额: ¥{payment.get(\"amount\")}')
        print(f'   支付方式: {payment.get(\"payment_method\")}')
    else:
        print('❌ 创建支付订单失败')
        print(f'   错误信息: {data.get(\"message\", \"未知错误\")}')
except Exception as e:
    print('❌ 支付API响应异常')
    print(f'   异常信息: {e}')
"
echo ""

echo "📊 测试完成！"
echo "请查看上面的测试结果，✅ 表示通过，❌ 表示失败。"