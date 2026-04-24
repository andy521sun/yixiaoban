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
