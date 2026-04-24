#!/bin/bash

# 医小伴APP - API测试脚本（修复版）
# 直接测试各个API端点

set -e

# 服务器配置
PAYMENT_API="http://localhost:3003"
COMPANION_API="http://localhost:3004"

# 颜色定义
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 计数器
total_tests=0
passed_tests=0
failed_tests=0

# 测试函数
test_endpoint() {
    local name="$1"
    local url="$2"
    local method="${3:-GET}"
    local data="$4"
    local headers="$5"
    
    total_tests=$((total_tests + 1))
    
    echo -n "测试 ${name}... "
    
    # 构建curl命令
    cmd="curl -s -X \"$method\" \"$url\""
    
    if [ -n "$headers" ]; then
        cmd="$cmd -H \"$headers\""
    fi
    
    if [ -n "$data" ]; then
        cmd="$cmd -H \"Content-Type: application/json\" -d '$data'"
    fi
    
    # 执行请求
    response=$(eval $cmd 2>/dev/null || echo "CONNECTION_ERROR")
    
    if [ "$response" = "CONNECTION_ERROR" ]; then
        echo -e "${RED}❌ 连接失败${NC}"
        failed_tests=$((failed_tests + 1))
        return 1
    elif echo "$response" | grep -q "<html>"; then
        echo -e "${RED}❌ 返回HTML错误${NC}"
        echo "   错误详情: $(echo "$response" | grep -o '<pre>[^<]*</pre>' | sed 's/<[^>]*>//g')"
        failed_tests=$((failed_tests + 1))
        return 1
    else
        echo -e "${GREEN}✅ 成功${NC}"
        # 打印简洁的响应信息
        if [ -n "$response" ] && [ "$response" != "{}" ]; then
            echo "   响应: $(echo "$response" | cut -c1-80)..."
        fi
        passed_tests=$((passed_tests + 1))
        return 0
    fi
}

print_header() {
    echo -e "${BLUE}════════════════════════════════════════════════════════════════${NC}"
    echo -e "${BLUE}  $1${NC}"
    echo -e "${BLUE}════════════════════════════════════════════════════════════════${NC}"
}

print_result() {
    echo ""
    echo -e "${BLUE}════════════════════════════════════════════════════════════════${NC}"
    echo -e "${BLUE}  测试结果汇总${NC}"
    echo -e "${BLUE}════════════════════════════════════════════════════════════════${NC}"
    echo ""
    echo -e "  总测试数: $total_tests"
    echo -e "  ${GREEN}通过: $passed_tests${NC}"
    if [ $failed_tests -gt 0 ]; then
        echo -e "  ${RED}失败: $failed_tests${NC}"
    else
        echo -e "  ${GREEN}失败: $failed_tests${NC}"
    fi
    
    if [ $failed_tests -eq 0 ]; then
        echo ""
        echo -e "${GREEN}🎉 所有测试通过！系统运行正常。${NC}"
    else
        echo ""
        echo -e "${YELLOW}⚠️  有 $failed_tests 个测试失败，请检查相关服务。${NC}"
    fi
}

# 主测试流程
echo ""
print_header "🏥 医小伴APP API测试开始"
echo "测试时间: $(date)"
echo "服务器配置:"
echo "  支付API: $PAYMENT_API"
echo "  陪诊师API: $COMPANION_API"
echo ""

print_header "🔍 健康检查测试"
test_endpoint "支付服务器健康检查" "$PAYMENT_API/health"
test_endpoint "陪诊师服务器健康检查" "$COMPANION_API/health"

print_header "💰 支付服务器功能测试"
test_endpoint "获取订单列表" "$PAYMENT_API/api/orders"
test_endpoint "创建订单" "$PAYMENT_API/api/orders" "POST" '{"patient_name": "测试用户", "hospital": "协和医院", "service_type": "陪诊", "amount": 100}'
test_endpoint "支付统计" "$PAYMENT_API/api/payment/statistics"

print_header "👨⚕️ 陪诊师服务器功能测试"
# 先登录获取token
echo -n "获取登录token... "
login_response=$(curl -s -X POST "$COMPANION_API/api/login" -H "Content-Type: application/json" -d '{"username": "doctor1", "password": "123"}')
token=$(echo "$login_response" | grep -o '"token":"[^"]*"' | cut -d'"' -f4)

if [ -n "$token" ]; then
    echo -e "${GREEN}✅ 成功${NC}"
    echo "   token: ${token:0:20}..."
    
    test_endpoint "获取任务列表" "$COMPANION_API/api/tasks" "GET" "" "Authorization: Bearer $token"
    test_endpoint "获取陪诊师信息" "$COMPANION_API/api/companion/profile" "GET" "" "Authorization: Bearer $token"
else
    echo -e "${RED}❌ 失败${NC}"
    echo "   响应: $login_response"
    failed_tests=$((failed_tests + 1))
fi

print_header "📊 服务器状态检查"
echo "正在运行的服务器进程:"
ps aux | grep -E "(payment_dev_server|companion_simple)" | grep -v grep | while read line; do
    pid=$(echo "$line" | awk '{print $2}')
    cmd=$(echo "$line" | awk '{for(i=11;i<=NF;i++) printf $i" "; print ""}')
    runtime=$(ps -o etime= -p "$pid" 2>/dev/null || echo "未知")
    echo -e "  ${GREEN}✓${NC} PID $pid: $cmd (运行时间: $runtime)"
done

echo ""
echo "端口监听状态:"
if ss -tlnp | grep -q ":3003"; then
    echo -e "  ${GREEN}✓${NC} 端口 3003 (支付服务器) 正在监听"
else
    echo -e "  ${RED}✗${NC} 端口 3003 未监听"
fi

if ss -tlnp | grep -q ":3004"; then
    echo -e "  ${GREEN}✓${NC} 端口 3004 (陪诊师服务器) 正在监听"
else
    echo -e "  ${RED}✗${NC} 端口 3004 未监听"
fi

print_result

# 生成测试报告
echo ""
echo "📋 生成测试报告..."
report_file="test_report_$(date +%Y%m%d_%H%M%S).md"
cat > "$report_file" << EOF
# 医小伴APP API测试报告
**测试时间:** $(date)
**测试环境:** 开发环境

## 服务器配置
- 支付API: $PAYMENT_API
- 陪诊师API: $COMPANION_API

## 测试结果
- 总测试数: $total_tests
- 通过: $passed_tests
- 失败: $failed_tests

## 服务器状态
$(ps aux | grep -E "(payment_dev_server|companion_simple)" | grep -v grep | while read line; do
    pid=\$(echo "\$line" | awk '{print \$2}')
    cmd=\$(echo "\$line" | awk '{for(i=11;i<=NF;i++) printf \$i" "; print ""}')
    runtime=\$(ps -o etime= -p "\$pid" 2>/dev/null || echo "未知")
    echo "- \`\$cmd\` (PID: \$pid, 运行时间: \$runtime)"
done)

## 端口状态
$(ss -tlnp | grep -E ":3003|:3004" | while read line; do
    echo "- \$line"
done)

## 建议
$(if [ \$failed_tests -eq 0 ]; then
    echo "✅ 所有服务运行正常，可以继续开发工作。"
else
    echo "⚠️  发现 \$failed_tests 个问题，建议："
    echo "   1. 检查相关服务日志"
    echo "   2. 验证API端点配置"
    echo "   3. 重新启动失败的服务"
fi)

---
*测试脚本: test_all_apis_fixed.sh*
*生成时间: $(date)*
EOF

echo -e "${GREEN}✅ 测试报告已保存到: $report_file${NC}"
echo ""

# 退出码
if [ $failed_tests -eq 0 ]; then
    exit 0
else
    exit 1
fi