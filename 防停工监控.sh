#!/bin/bash
# 医小伴APP防停工监控脚本
# 创建时间：2026年4月19日
# 执行频率：每小时执行一次

LOG_FILE="/root/.openclaw/workspace/yixiaoban_app/停工监控日志.md"
ALERT_FILE="/root/.openclaw/workspace/yixiaoban_app/停工警报.md"

echo "=== 医小伴APP防停工监控 ==="
echo "监控时间: $(date '+%Y-%m-%d %H:%M:%S')"
echo ""

# 1. 检查服务器状态
echo "1. 检查服务器状态:"
echo "------------------"

# 支付服务器
if curl -s -m 5 "http://localhost:3003/health" > /dev/null; then
    echo "   ✅ 支付服务器 (3003): 运行正常"
    PAYMENT_STATUS="正常"
else
    echo "   ❌ 支付服务器 (3003): 停止运行"
    PAYMENT_STATUS="停止"
    echo "   🚨 尝试重启支付服务器..."
    cd /root/.openclaw/workspace/yixiaoban_app
    pkill -f "node.*payment_dev" 2>/dev/null
    sleep 2
    NODE_PATH=./backend/node_modules nohup node payment_dev_server.js > payment_restart.log 2>&1 &
    echo "   重启命令已执行"
fi

# 陪诊师服务器
if curl -s -m 5 "http://localhost:3004/health" > /dev/null; then
    echo "   ✅ 陪诊师服务器 (3004): 运行正常"
    COMPANION_STATUS="正常"
else
    echo "   ❌ 陪诊师服务器 (3004): 停止运行"
    COMPANION_STATUS="停止"
    echo "   🚨 尝试重启陪诊师服务器..."
    cd /root/.openclaw/workspace/yixiaoban_app
    pkill -f "node.*companion_simple" 2>/dev/null
    sleep 2
    NODE_PATH=./backend/node_modules nohup node companion_simple.js > companion_restart.log 2>&1 &
    echo "   重启命令已执行"
fi

echo ""

# 2. 检查代码提交
echo "2. 检查代码提交:"
echo "----------------"

# 查找今天修改的文件
TODAY=$(date '+%Y-%m-%d')
TODAY_FILES=$(find /root/.openclaw/workspace/yixiaoban_app -type f -name "*.js" -o -name "*.py" -o -name "*.sh" -o -name "*.md" -o -name "*.sql" | xargs -I {} sh -c 'stat -c %y {} | grep "^$TODAY" && echo "  - {}"' 2>/dev/null | head -10)

if [ -n "$TODAY_FILES" ]; then
    echo "   ✅ 今日有文件修改:"
    echo "$TODAY_FILES" | head -5
    CODE_STATUS="有提交"
else
    echo "   ⚠️ 今日无代码文件修改"
    CODE_STATUS="无提交"
fi

echo ""

# 3. 检查进程运行时间
echo "3. 检查进程运行时间:"
echo "-------------------"

# 支付服务器进程
PAYMENT_PID=$(ps aux | grep "node.*payment_dev" | grep -v grep | awk '{print $2}')
if [ -n "$PAYMENT_PID" ]; then
    PAYMENT_UPTIME=$(ps -p $PAYMENT_PID -o etime= | xargs)
    echo "   📊 支付服务器运行时间: $PAYMENT_UPTIME"
else
    echo "   ❌ 支付服务器进程不存在"
fi

# 陪诊师服务器进程
COMPANION_PID=$(ps aux | grep "node.*companion_simple" | grep -v grep | awk '{print $2}')
if [ -n "$COMPANION_PID" ]; then
    COMPANION_UPTIME=$(ps -p $COMPANION_PID -o etime= | xargs)
    echo "   📊 陪诊师服务器运行时间: $COMPANION_UPTIME"
else
    echo "   ❌ 陪诊师服务器进程不存在"
fi

echo ""

# 4. 检查磁盘和内存
echo "4. 检查系统资源:"
echo "----------------"

DISK_USAGE=$(df -h / | tail -1 | awk '{print $5}')
MEMORY_USAGE=$(free -m | awk 'NR==2{printf "%.1f%%", $3*100/$2}')
echo "   💾 磁盘使用率: $DISK_USAGE"
echo "   🧠 内存使用率: $MEMORY_USAGE"

echo ""

# 5. 记录到日志文件
echo "## 监控记录 - $(date '+%Y-%m-%d %H:%M:%S')" >> "$LOG_FILE"
echo "" >> "$LOG_FILE"
echo "- 支付服务器状态: $PAYMENT_STATUS" >> "$LOG_FILE"
echo "- 陪诊师服务器状态: $COMPANION_STATUS" >> "$LOG_FILE"
echo "- 代码提交状态: $CODE_STATUS" >> "$LOG_FILE"
if [ -n "$PAYMENT_UPTIME" ]; then
    echo "- 支付服务器运行时间: $PAYMENT_UPTIME" >> "$LOG_FILE"
fi
if [ -n "$COMPANION_UPTIME" ]; then
    echo "- 陪诊师服务器运行时间: $COMPANION_UPTIME" >> "$LOG_FILE"
fi
echo "- 磁盘使用率: $DISK_USAGE" >> "$LOG_FILE"
echo "- 内存使用率: $MEMORY_USAGE" >> "$LOG_FILE"
echo "" >> "$LOG_FILE"

# 6. 检查是否需要报警
if [ "$PAYMENT_STATUS" = "停止" ] || [ "$COMPANION_STATUS" = "停止" ]; then
    echo "🚨 🚨 🚨 服务器异常！需要立即处理！" >> "$ALERT_FILE"
    echo "时间: $(date '+%Y-%m-%d %H:%M:%S')" >> "$ALERT_FILE"
    echo "异常服务:" >> "$ALERT_FILE"
    [ "$PAYMENT_STATUS" = "停止" ] && echo "- 支付服务器 (3003)" >> "$ALERT_FILE"
    [ "$COMPANION_STATUS" = "停止" ] && echo "- 陪诊师服务器 (3004)" >> "$ALERT_FILE"
    echo "" >> "$ALERT_FILE"
    echo "⚠️ 已记录到警报文件: $ALERT_FILE"
fi

# 7. 检查连续无代码提交
if [ "$CODE_STATUS" = "无提交" ]; then
    # 检查最近3次监控记录
    LAST_CODE_COUNT=$(grep -c "代码提交状态: 有提交" "$LOG_FILE" | tail -3)
    if [ "$LAST_CODE_COUNT" -eq 0 ]; then
        echo "⚠️ 警告：连续多次监控无代码提交！" >> "$ALERT_FILE"
        echo "时间: $(date '+%Y-%m-%d %H:%M:%S')" >> "$ALERT_FILE"
        echo "状态: 可能发生停工" >> "$ALERT_FILE"
        echo "" >> "$ALERT_FILE"
    fi
fi

echo ""
echo "=== 监控完成 ==="
echo "日志文件: $LOG_FILE"
if [ -f "$ALERT_FILE" ] && [ -s "$ALERT_FILE" ]; then
    echo "警报文件: $ALERT_FILE (有未处理警报)"
else
    echo "警报状态: 正常"
fi
echo ""