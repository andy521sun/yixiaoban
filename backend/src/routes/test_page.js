const express = require('express');
const router = express.Router();

// 测试页面HTML
const testPageHTML = `
<!DOCTYPE html>
<html lang="zh-CN">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>医小伴APP服务状态测试</title>
    <style>
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }
        
        body {
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            min-height: 100vh;
            display: flex;
            justify-content: center;
            align-items: center;
            padding: 20px;
        }
        
        .container {
            background: white;
            border-radius: 20px;
            padding: 30px;
            box-shadow: 0 20px 60px rgba(0,0,0,0.3);
            max-width: 900px;
            width: 100%;
        }
        
        .header {
            text-align: center;
            margin-bottom: 30px;
            padding-bottom: 20px;
            border-bottom: 2px solid #f0f0f0;
        }
        
        .logo {
            font-size: 48px;
            color: #4CAF50;
            margin-bottom: 15px;
        }
        
        h1 {
            color: #333;
            font-size: 28px;
            margin-bottom: 10px;
        }
        
        .subtitle {
            color: #666;
            font-size: 16px;
            margin-bottom: 10px;
        }
        
        .server-info {
            background: #f8f9fa;
            padding: 15px;
            border-radius: 10px;
            margin-top: 15px;
            text-align: center;
        }
        
        .ip-address {
            font-family: monospace;
            font-size: 18px;
            color: #495057;
            font-weight: bold;
            margin: 10px 0;
        }
        
        .services-grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
            gap: 20px;
            margin: 30px 0;
        }
        
        .service-card {
            background: white;
            border: 2px solid #e9ecef;
            border-radius: 15px;
            padding: 20px;
            transition: all 0.3s ease;
            text-align: center;
        }
        
        .service-card:hover {
            border-color: #4CAF50;
            transform: translateY(-5px);
            box-shadow: 0 10px 30px rgba(76, 175, 80, 0.2);
        }
        
        .service-icon {
            font-size: 40px;
            margin-bottom: 15px;
        }
        
        .service-title {
            font-size: 18px;
            font-weight: bold;
            color: #333;
            margin-bottom: 10px;
        }
        
        .service-url {
            background: #f8f9fa;
            padding: 10px;
            border-radius: 8px;
            font-family: monospace;
            font-size: 12px;
            color: #495057;
            word-break: break-all;
            margin: 10px 0;
        }
        
        .test-button {
            background: #4CAF50;
            color: white;
            border: none;
            padding: 10px 20px;
            border-radius: 8px;
            font-size: 14px;
            font-weight: bold;
            cursor: pointer;
            transition: background 0.3s ease;
            width: 100%;
            margin-top: 10px;
        }
        
        .test-button:hover {
            background: #45a049;
        }
        
        .test-button:disabled {
            background: #cccccc;
            cursor: not-allowed;
        }
        
        .result {
            margin-top: 15px;
            padding: 12px;
            border-radius: 8px;
            font-size: 14px;
            display: none;
            text-align: left;
        }
        
        .result-success {
            background: #d4edda;
            color: #155724;
            border: 1px solid #c3e6cb;
        }
        
        .result-error {
            background: #f8d7da;
            color: #721c24;
            border: 1px solid #f5c6cb;
        }
        
        .status-indicator {
            display: inline-block;
            width: 10px;
            height: 10px;
            border-radius: 50%;
            margin-right: 8px;
        }
        
        .status-online {
            background: #28a745;
            animation: pulse 2s infinite;
        }
        
        .status-offline {
            background: #dc3545;
        }
        
        @keyframes pulse {
            0% { opacity: 1; }
            50% { opacity: 0.5; }
            100% { opacity: 1; }
        }
        
        .footer {
            text-align: center;
            margin-top: 30px;
            padding-top: 20px;
            border-top: 2px solid #f0f0f0;
            color: #666;
            font-size: 14px;
        }
        
        @media (max-width: 768px) {
            .container {
                padding: 20px;
            }
            
            h1 {
                font-size: 24px;
            }
            
            .services-grid {
                grid-template-columns: 1fr;
            }
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <div class="logo">🏥</div>
            <h1>医小伴陪诊APP - 服务状态监控</h1>
            <div class="subtitle">实时检测API服务和管理后台的运行状态</div>
            
            <div class="server-info">
                <div>服务器IP地址：</div>
                <div class="ip-address" id="server-ip">122.51.179.136</div>
                <div>当前时间：<span id="current-time">--:--:--</span></div>
            </div>
        </div>
        
        <div class="services-grid">
            <div class="service-card">
                <div class="service-icon">🩺</div>
                <div class="service-title">API健康检查</div>
                <div class="service-url" id="health-url">/health</div>
                <button class="test-button" onclick="testHealth()" id="health-btn">
                    测试连接
                </button>
                <div id="health-result" class="result"></div>
            </div>
            
            <div class="service-card">
                <div class="service-icon">📚</div>
                <div class="service-title">API文档</div>
                <div class="service-url" id="api-url">/api</div>
                <button class="test-button" onclick="testApi()" id="api-btn">
                    查看文档
                </button>
                <div id="api-result" class="result"></div>
            </div>
            
            <div class="service-card">
                <div class="service-icon">🏥</div>
                <div class="service-title">医院数据</div>
                <div class="service-url" id="hospitals-url">/api/hospitals/enhanced?limit=2</div>
                <button class="test-button" onclick="testHospitals()" id="hospitals-btn">
                    获取数据
                </button>
                <div id="hospitals-result" class="result"></div>
            </div>
            
            <div class="service-card">
                <div class="service-icon">👨‍⚕️</div>
                <div class="service-title">陪诊师数据</div>
                <div class="service-url" id="companions-url">/api/companions/enhanced?limit=2</div>
                <button class="test-button" onclick="testCompanions()" id="companions-btn">
                    获取数据
                </button>
                <div id="companions-result" class="result"></div>
            </div>
            
            <div class="service-card">
                <div class="service-icon">🖥️</div>
                <div class="service-title">管理后台</div>
                <div class="service-url" id="admin-url">:8080</div>
                <button class="test-button" onclick="testAdmin()" id="admin-btn">
                    访问后台
                </button>
                <div id="admin-result" class="result"></div>
            </div>
            
            <div class="service-card">
                <div class="service-icon">📊</div>
                <div class="service-title">服务状态</div>
                <div class="service-url">实时监控</div>
                <div style="margin: 15px 0;">
                    <div><span class="status-indicator status-online"></span> API服务: <span id="api-status">检测中...</span></div>
                    <div><span class="status-indicator" id="admin-status-indicator"></span> 管理后台: <span id="admin-status">检测中...</span></div>
                </div>
                <button class="test-button" onclick="checkAllServices()">
                    全面检测
                </button>
            </div>
        </div>
        
        <div class="footer">
            <p>医小伴陪诊APP - 温暖就医，专业陪伴 🏥❤️</p>
            <p>服务器状态: <span id="overall-status">●</span> 检测中 | 最后更新: <span id="last-update">--:--:--</span></p>
        </div>
    </div>

    <script>
        // 获取当前URL的基础路径
        const baseUrl = window.location.origin;
        const serverIp = '122.51.179.136';
        
        // 初始化URL显示
        document.getElementById('health-url').textContent = baseUrl + '/health';
        document.getElementById('api-url').textContent = baseUrl + '/api';
        document.getElementById('hospitals-url').textContent = baseUrl + '/api/hospitals/enhanced?limit=2';
        document.getElementById('companions-url').textContent = baseUrl + '/api/companions/enhanced?limit=2';
        document.getElementById('admin-url').textContent = serverIp + ':8080';
        document.getElementById('server-ip').textContent = serverIp;
        
        // 更新时间显示
        function updateTime() {
            const now = new Date();
            const timeStr = now.toLocaleTimeString('zh-CN', { 
                hour12: false,
                hour: '2-digit',
                minute: '2-digit',
                second: '2-digit'
            });
            document.getElementById('current-time').textContent = timeStr;
            document.getElementById('last-update').textContent = timeStr;
        }
        
        // 通用测试函数
        async function testEndpoint(url, resultId, buttonId, successCallback) {
            const resultDiv = document.getElementById(resultId);
            const button = document.getElementById(buttonId);
            
            resultDiv.style.display = 'none';
            button.innerHTML = '测试中...';
            button.disabled = true;
            
            try {
                const startTime = Date.now();
                const response = await fetch(url);
                const endTime = Date.now();
                const latency = endTime - startTime;
                
                if (response.ok) {
                    const data = await response.json();
                    resultDiv.className = 'result result-success';
                    resultDiv.innerHTML = `
                        <strong>✅ 连接成功 (${response.status})</strong><br>
                        <small>响应时间: ${latency}ms | ${new Date().toLocaleTimeString()}</small>
                        ${successCallback ? successCallback(data) : ''}
                    `;
                    
                    // 更新状态指示器
                    if (url.includes('/health')) {
                        document.getElementById('api-status').innerHTML = `<span style="color: #28a745">在线 (${latency}ms)</span>`;
                    }
                } else {
                    throw new Error(`HTTP ${response.status}`);
                }
            } catch (error) {
                resultDiv.className = 'result result-error';
                resultDiv.innerHTML = `
                    <strong>❌ 连接失败</strong><br>
                    <small>错误信息: ${error.message}</small>
                `;
                
                // 更新状态指示器
                if (url.includes('/health')) {
                    document.getElementById('api-status').innerHTML = '<span style="color: #dc3545">离线</span>';
                }
            }
            
            resultDiv.style.display = 'block';
            button.innerHTML = '重新测试';
            button.disabled = false;
        }
        
        // 测试健康检查
        function testHealth() {
            testEndpoint(baseUrl + '/health', 'health-result', 'health-btn', (data) => {
                return `
                    <div style="margin-top: 10px;">
                        <strong>服务信息:</strong><br>
                        服务名称: ${data.service}<br>
                        版本: ${data.version}<br>
                        数据库: ${data.database}<br>
                        环境: ${data.environment}
                    </div>
                `;
            });
        }
        
        // 测试API文档
        function testApi() {
            testEndpoint(baseUrl + '/api', 'api-result', 'api-btn', (data) => {
                return `
                    <div style="margin-top: 10px;">
                        <strong>API端点:</strong><br>
                        • ${data.message}<br>
                        • 版本: ${data.version}<br>
                        • 客服电话: ${data.customer_service || '未设置'}
                    </div>
                `;
            });
        }
        
        // 测试医院数据
        function testHospitals() {
            testEndpoint(baseUrl + '/api/hospitals/enhanced?limit=2', 'hospitals-result', 'hospitals-btn', (data) => {
                const hospitals = data.data || [];
                return `
                    <div style="margin-top: 10px;">
                        <strong>医院数据 (${hospitals.length}家):</strong><br>
                        ${hospitals.map(h => `• ${h.name} (${h.level})`).join('<br>')}
                    </div>
                `;
            });
        }
        
        // 测试陪诊师数据
        function testCompanions() {
            testEndpoint(baseUrl + '/api/companions/enhanced?limit=2', 'companions-result', 'companions-btn', (data) => {
                const companions = data.data || [];
                return `
                    <div style="margin-top: 10px;">
                        <strong>陪诊师数据 (${companions.length}位):</strong><br>
                        ${companions.map(c => `• ${c.name} (${c.title})`).join('<br>')}
                    </div>
                `;
            });
        }
        
        // 测试管理后台
        async function testAdmin() {
            const resultDiv = document.getElementById('admin-result');
            const button = document.getElementById('admin-btn');
            
            resultDiv.style.display = 'none';
            button.innerHTML = '测试中...';
            button.disabled = true;
            
            const adminUrl = `http://${serverIp}:8080`;
            
            try {
                const startTime = Date.now();
                // 使用no-cors模式测试连接
                const response = await fetch(adminUrl, { mode: 'no-cors' });
                const endTime = Date.now();
                const latency = endTime - startTime;
                
                resultDiv.className = 'result result-success';
                resultDiv.innerHTML = `
                    <strong>✅ 管理后台可访问</strong><br>
                    <small>响应时间: ${latency}ms | ${new Date().toLocaleTimeString()}</small>
                    <div style="margin-top: 10px;">
                        <a href="${adminUrl}" target="_blank" style="color: #4CAF50; text-decoration: none; font-weight: bold;">
                            🖥️ 点击访问管理后台
                        </a>
                    </div>
                `;
                
                // 更新状态指示器
                document.getElementById('admin-status').innerHTML = `<span style="color: #28a745">在线 (${latency}ms)</span>`;
                document.getElementById('admin-status-indicator').className = 'status-indicator status-online';
                
            } catch (error) {
                resultDiv.className = 'result result-error';
                resultDiv.innerHTML = `
                    <strong>❌ 管理后台无法访问</strong><br>
                    <small>错误信息: ${error.message}</small>
                    <div style="margin-top: 10px;">
                        请检查:
                        <ul style="margin: 5px 0 5px 20px;">
                            <li>端口8080是否开放</li>
                            <li>管理后台服务是否运行</li>
                            <li>服务器防火墙设置</li>
                        </ul>
                    </div>
                `;
                
                // 更新状态指示器
                document.getElementById('admin-status').innerHTML = '<span style="color: #dc3545">离线</span>';
                document.getElementById('admin-status-indicator').className = 'status-indicator status-offline';
            }
            
            resultDiv.style.display = 'block';
            button.innerHTML = '重新测试';
            button.disabled = false;
        }
        
        // 全面检测所有服务
        async function checkAllServices() {
            await testHealth();
            await testAdmin();
            document.getElementById('overall-status').innerHTML = '●';
            document.getElementById('overall-status').style.color = '#28a745';
        }
        
        // 初始化
        updateTime();
        setInterval(updateTime, 1000);
        
        // 页面加载后自动检测
        setTimeout(() => {
            checkAllServices();
        }, 1000);
    </script>
</body>
</html>

// 导出路由
router.get('/', (req, res) => {
    res.send(testPageHTML);
});

module.exports = router;