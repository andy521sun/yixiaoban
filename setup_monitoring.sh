#!/bin/bash
# 设置医小伴APP定时监控任务
# 创建时间：2026年4月19日

echo "=== 设置医小伴APP定时监控 ==="
echo "时间: $(date)"
echo ""

# 1. 创建监控目录
echo "1. 创建监控目录..."
mkdir -p /root/.openclaw/workspace/yixiaoban_app/monitoring
mkdir -p /root/.openclaw/workspace/yixiaoban_app/logs

# 2. 设置定时监控任务（每小时执行一次）
echo "2. 设置cron定时任务..."
CRON_JOB="0 * * * * /root/.openclaw/workspace/yixiaoban_app/防停工监控.sh >> /root/.openclaw/workspace/yixiaoban_app/logs/monitoring.log 2>&1"

# 检查是否已存在
if crontab -l 2>/dev/null | grep -q "防停工监控.sh"; then
    echo "   ⚠️ 定时任务已存在，更新中..."
    crontab -l 2>/dev/null | grep -v "防停工监控.sh" | crontab -
fi

# 添加新任务
(crontab -l 2>/dev/null; echo "$CRON_JOB") | crontab -
echo "   ✅ 定时任务设置完成：每小时执行一次"

# 3. 设置每日进度汇报提醒（每天17:55）
echo "3. 设置每日进度汇报提醒..."
DAILY_REMIND="55 17 * * * echo '🚨 5分钟后需要提交每日进度汇报！当前时间: \$(date)' >> /root/.openclaw/workspace/yixiaoban_app/logs/reminder.log"
(crontab -l 2>/dev/null; echo "$DAILY_REMIND") | crontab -
echo "   ✅ 每日提醒设置完成：17:55提醒"

# 4. 创建监控状态页面
echo "4. 创建监控状态页面..."
cat > /root/.openclaw/workspace/yixiaoban_app/monitoring/status.html << 'EOF'
<!DOCTYPE html>
<html>
<head>
    <title>医小伴APP - 监控状态</title>
    <meta charset="utf-8">
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; }
        .status { padding: 10px; margin: 10px 0; border-radius: 5px; }
        .healthy { background-color: #d4edda; color: #155724; }
        .warning { background-color: #fff3cd; color: #856404; }
        .error { background-color: #f8d7da; color: #721c24; }
        .timestamp { color: #666; font-size: 12px; }
    </style>
</head>
<body>
    <h1>🏥 医小伴APP监控状态</h1>
    <p class="timestamp">最后更新: <span id="lastUpdate">加载中...</span></p>
    
    <div class="status" id="paymentStatus">
        <h3>💰 支付服务器 (端口: 3003)</h3>
        <p>状态: 检查中...</p>
        <p>运行时间: --</p>
    </div>
    
    <div class="status" id="companionStatus">
        <h3>👨‍⚕️ 陪诊师服务器 (端口: 3004)</h3>
        <p>状态: 检查中...</p>
        <p>运行时间: --</p>
    </div>
    
    <div class="status" id="codeStatus">
        <h3>💻 代码提交状态</h3>
        <p>今日提交: 检查中...</p>
        <p>最后修改: --</p>
    </div>
    
    <div class="status" id="progressStatus">
        <h3>📊 项目进度</h3>
        <p>总体进度: 40%</p>
        <p>目标日期: 2026年4月28日</p>
        <p>剩余天数: 8天</p>
    </div>
    
    <script>
        function updateStatus() {
            fetch('/api/status')
                .then(response => response.json())
                .then(data => {
                    document.getElementById('lastUpdate').textContent = new Date().toLocaleString();
                    
                    // 更新支付服务器状态
                    const paymentDiv = document.getElementById('paymentStatus');
                    paymentDiv.className = 'status ' + (data.payment.healthy ? 'healthy' : 'error');
                    paymentDiv.innerHTML = `
                        <h3>💰 支付服务器 (端口: 3003)</h3>
                        <p>状态: ${data.payment.healthy ? '✅ 正常' : '❌ 异常'}</p>
                        <p>运行时间: ${data.payment.uptime || '--'}</p>
                    `;
                    
                    // 更新陪诊师服务器状态
                    const companionDiv = document.getElementById('companionStatus');
                    companionDiv.className = 'status ' + (data.companion.healthy ? 'healthy' : 'error');
                    companionDiv.innerHTML = `
                        <h3>👨‍⚕️ 陪诊师服务器 (端口: 3004)</h3>
                        <p>状态: ${data.companion.healthy ? '✅ 正常' : '❌ 异常'}</p>
                        <p>运行时间: ${data.companion.uptime || '--'}</p>
                    `;
                    
                    // 更新代码状态
                    const codeDiv = document.getElementById('codeStatus');
                    const hasCode = data.code.has_today_commits;
                    codeDiv.className = 'status ' + (hasCode ? 'healthy' : 'warning');
                    codeDiv.innerHTML = `
                        <h3>💻 代码提交状态</h3>
                        <p>今日提交: ${hasCode ? '✅ 有提交' : '⚠️ 无提交'}</p>
                        <p>最后修改: ${data.code.last_modified || '--'}</p>
                    `;
                })
                .catch(error => {
                    console.error('状态更新失败:', error);
                    document.getElementById('lastUpdate').textContent = '更新失败: ' + new Date().toLocaleString();
                });
        }
        
        // 初始加载
        updateStatus();
        // 每分钟更新一次
        setInterval(updateStatus, 60000);
    </script>
</body>
</html>
EOF

echo "   ✅ 监控状态页面创建完成"

# 5. 创建简单的状态API
echo "5. 创建状态检查API..."
cat > /root/.openclaw/workspace/yixiaoban_app/monitoring/status_api.js << 'EOF'
const express = require('../../backend/node_modules/express');
const app = express();
const PORT = 3005;

app.get('/api/status', (req, res) => {
    const { execSync } = require('child_process');
    
    try {
        // 检查支付服务器
        let paymentHealthy = false;
        let paymentUptime = '';
        try {
            execSync('curl -s -m 3 http://localhost:3003/health', { stdio: 'pipe' });
            paymentHealthy = true;
            const pid = execSync("ps aux | grep 'node.*payment_dev' | grep -v grep | awk '{print $2}'").toString().trim();
            if (pid) {
                paymentUptime = execSync(`ps -p ${pid} -o etime=`).toString().trim();
            }
        } catch (e) {
            paymentHealthy = false;
        }
        
        // 检查陪诊师服务器
        let companionHealthy = false;
        let companionUptime = '';
        try {
            execSync('curl -s -m 3 http://localhost:3004/health', { stdio: 'pipe' });
            companionHealthy = true;
            const pid = execSync("ps aux | grep 'node.*companion_simple' | grep -v grep | awk '{print $2}'").toString().trim();
            if (pid) {
                companionUptime = execSync(`ps -p ${pid} -o etime=`).toString().trim();
            }
        } catch (e) {
            companionHealthy = false;
        }
        
        // 检查代码提交
        const today = new Date().toISOString().split('T')[0];
        const hasTodayCommits = execSync(`find /root/.openclaw/workspace/yixiaoban_app -type f -name "*.js" -o -name "*.py" -o -name "*.md" -o -name "*.sql" | xargs -I {} sh -c 'stat -c %y {} | grep "^${today}" && echo "found"' | head -1`).toString().trim().length > 0;
        
        const lastModified = execSync(`find /root/.openclaw/workspace/yixiaoban_app -type f -name "*.js" -o -name "*.py" -o -name "*.md" -o -name "*.sql" | xargs stat -c %y | sort -r | head -1`).toString().trim();
        
        res.json({
            timestamp: new Date().toISOString(),
            payment: {
                healthy: paymentHealthy,
                uptime: paymentUptime,
                port: 3003
            },
            companion: {
                healthy: companionHealthy,
                uptime: companionUptime,
                port: 3004
            },
            code: {
                has_today_commits: hasTodayCommits,
                last_modified: lastModified
            },
            progress: {
                current: 40,
                target_date: '2026-04-28',
                days_remaining: 8
            }
        });
    } catch (error) {
        res.status(500).json({
            error: error.message,
            timestamp: new Date().toISOString()
        });
    }
});

app.listen(PORT, () => {
    console.log(`监控API运行在 http://localhost:${PORT}`);
});
EOF

echo "   ✅ 状态API创建完成"

# 6. 启动监控API
echo "6. 启动监控API..."
cd /root/.openclaw/workspace/yixiaoban_app
NODE_PATH=./backend/node_modules nohup node monitoring/status_api.js > logs/status_api.log 2>&1 &
MONITOR_PID=$!
echo $MONITOR_PID > monitoring/status_api.pid
echo "   ✅ 监控API启动完成，PID: $MONITOR_PID"

# 7. 立即执行一次监控
echo "7. 执行首次监控检查..."
/root/.openclaw/workspace/yixiaoban_app/防停工监控.sh

echo ""
echo "=== 监控设置完成 ==="
echo ""
echo "📊 监控系统已启用："
echo "  - 定时监控：每小时执行一次"
echo "  - 每日提醒：17:55提醒进度汇报"
echo "  - 状态API：http://localhost:3005/api/status"
echo "  - 状态页面：file:///root/.openclaw/workspace/yixiaoban_app/monitoring/status.html"
echo ""
echo "🚨 防停工机制已激活："
echo "  - 服务器异常自动重启"
echo "  - 代码提交每日监控"
echo "  - 进度偏差及时预警"
echo ""
echo "✅ 从现在开始，医小伴APP开发将受到严格监控，确保不再停工！"