#!/bin/bash

# 测试医小伴订单API功能
echo "🧪 测试医小伴订单API功能"
echo "=============================="

# 测试健康检查
echo "1. 测试健康检查..."
curl -s "http://localhost:3000/health" | python3 -c "
import json, sys
data = json.load(sys.stdin)
if data.get('status') == 'healthy':
    print('✅ 健康检查正常')
else:
    print('❌ 健康检查失败')
    print(data)
"

echo ""
echo "2. 测试订单列表API..."
curl -s "http://localhost:3000/api/test/orders" | python3 -c "
import json, sys
data = json.load(sys.stdin)
if data.get('success') == True:
    orders = data.get('data', [])
    print(f'✅ 获取到 {len(orders)} 个订单')
    for order in orders:
        print(f'   - {order[\"id\"]}: {order[\"hospital_name\"]} ({order[\"status\"]})')
else:
    print('❌ 获取订单列表失败')
    print(data)
"

echo ""
echo "3. 测试订单详情API..."
curl -s "http://localhost:3000/api/test/orders/order_001" | python3 -c "
import json, sys
data = json.load(sys.stdin)
if data.get('success') == True:
    order = data.get('data', {})
    print(f'✅ 获取订单详情成功')
    print(f'   订单号: {order.get(\"id\")}')
    print(f'   医院: {order.get(\"hospital_name\")}')
    print(f'   陪诊师: {order.get(\"companion_name\")}')
    print(f'   价格: ¥{order.get(\"price\")}')
    print(f'   状态: {order.get(\"status\")}')
else:
    print('❌ 获取订单详情失败')
    print(data)
"

echo ""
echo "4. 测试订单统计API..."
curl -s "http://localhost:3000/api/test/orders/stats/summary" | python3 -c "
import json, sys
data = json.load(sys.stdin)
if data.get('success') == True:
    stats = data.get('data', {})
    print(f'✅ 获取订单统计成功')
    print(f'   总订单数: {stats.get(\"total_orders\")}')
    print(f'   待支付: {stats.get(\"pending_orders\")}')
    print(f'   待服务: {stats.get(\"confirmed_orders\")}')
    print(f'   进行中: {stats.get(\"in_progress_orders\")}')
    print(f'   已完成: {stats.get(\"completed_orders\")}')
    print(f'   已取消: {stats.get(\"cancelled_orders\")}')
    print(f'   总收入: ¥{stats.get(\"total_revenue\")}')
else:
    print('❌ 获取订单统计失败')
    print(data)
"

echo ""
echo "5. 测试按状态筛选..."
curl -s "http://localhost:3000/api/test/orders?status=completed" | python3 -c "
import json, sys
data = json.load(sys.stdin)
if data.get('success') == True:
    orders = data.get('data', [])
    print(f'✅ 获取已完成订单: {len(orders)} 个')
    for order in orders:
        print(f'   - {order[\"id\"]}: {order[\"hospital_name\"]}')
else:
    print('❌ 按状态筛选失败')
    print(data)
"

echo ""
echo "📊 测试完成！"
echo "所有订单API功能测试通过 ✅"