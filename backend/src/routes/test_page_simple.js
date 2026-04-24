const express = require('express');
const router = express.Router();

// 简单的测试页面
router.get('/', (req, res) => {
    const html = `
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>医小伴APP服务测试</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 40px; background: #f5f5f5; }
        .container { max-width: 800px; margin: 0 auto; background: white; padding: 30px; border-radius: 10px; box-shadow: 0 2px 10px rgba(0,0,0,0.1); }
        h1 { color: #4CAF50; text-align: center; }
        .server-info { background: #e8f5e9; padding: 15px; border-radius: 5px; margin: 20px 0; text-align: center; }
        .service { border: 1px solid #ddd; padding: 15px; margin: 10px 0; border-radius: 5px; }
        .service h3 { margin-top: 0; color: #333; }
        .url { background: #f5f5f5; padding: 8px; font-family: monospace; font-size: 14px; border-radius: 3px; margin: 5px 0; }
        .btn { background: #4CAF50; color: white; border: none; padding: 10px 15px; border-radius: 5px; cursor: pointer; margin: 5px; }
        .btn:hover { background: #45a049; }
        .result { margin-top: 10px; padding: 10px; border-radius: 5px; display: none; }
        .success { background: #d4edda; color: #155724; border: 1px solid #c3e6cb; }
        .error { background: #f8d7da; color: #721c24; border: 1px solid #f5c6cb; }
    </style>
</head>
<body>
    <div class="container">
        <h1>🏥 医小伴APP服务状态测试</h1>
        
        <div class="server-info">
            <strong>服务器IP:</strong> 122.51.179.136<br>
            <strong>当前时间:</strong> <span id="time">${new Date().toLocaleString('zh-CN')}</span>
        </div>
        
        <div class="service">
            <h3>🔗 API健康检查</h3>
            <div class="url" id="health-url">http://122.51.179.136:3000/health</div>
            <button class="btn" onclick="testHealth()">测试连接</button>
            <div id="health-result" class="result"></div>
        </div>
        
        <div class="service">
            <h3>📚 API文档</h3>
            <div class="url" id="api-url">http://122.51.179.136:3000/api</div>
            <button class="btn" onclick="testApi()">查看文档</button>
            <div id="api-result" class="result"></div>
        </div>
        
        <div class="service">
            <h3>🏥 医院数据</h3>
            <div class="url" id="hospitals-url">http://122.51.179.136:3000/api/hospitals/enhanced?limit=2</div>
            <button class="btn" onclick="testHospitals()">获取数据</button>
            <div id="hospitals-result" class="result"></div>
        </div>
        
        <div class="service">
            <h3>👨‍⚕️ 陪诊师数据</h3>
            <div class="url" id="companions-url">http://122.51.179.136:3000/api/companions/enhanced?limit=2</div>
            <button class="btn" onclick="testCompanions()">获取数据</button>
            <div id="companions-result" class="result"></div>
        </div>
        
        <div class="service">
            <h3>🖥️ 管理后台</h3>
            <div class="url" id="admin-url">http://122.51.179.136:8080</div>
            <button class="btn" onclick="testAdmin()">测试访问</button>
            <div id="admin-result" class="result"></div>
        </div>
        
        <div style="text-align: center; margin-top: 30px; color: #666;">
            <p>医小伴陪诊APP - 温暖就医，专业陪伴 🏥❤️</p>
            <p>最后更新: <span id="update-time">${new Date().toLocaleString('zh-CN')}</span></p>
        </div>
    </div>

    <script>
        async function testEndpoint(url, resultId) {
            const result = document.getElementById(resultId);
            result.style.display = 'none';
            
            try {
                const start = Date.now();
                const response = await fetch(url);
                const time = Date.now() - start;
                
                if (response.ok) {
                    const data = await response.json();
                    result.className = 'result success';
                    result.innerHTML = '✅ 连接成功 (' + time + 'ms)<br>' + 
                                      '状态码: ' + response.status + '<br>' +
                                      '时间: ' + new Date().toLocaleTimeString();
                    result.style.display = 'block';
                } else {
                    throw new Error('HTTP ' + response.status);
                }
            } catch (error) {
                result.className = 'result error';
                result.innerHTML = '❌ 连接失败<br>' + 
                                  '错误: ' + error.message + '<br>' +
                                  '时间: ' + new Date().toLocaleTimeString();
                result.style.display = 'block';
            }
        }
        
        function testHealth() {
            testEndpoint('http://122.51.179.136:3000/health', 'health-result');
        }
        
        function testApi() {
            testEndpoint('http://122.51.179.136:3000/api', 'api-result');
        }
        
        function testHospitals() {
            testEndpoint('http://122.51.179.136:3000/api/hospitals/enhanced?limit=2', 'hospitals-result');
        }
        
        function testCompanions() {
            testEndpoint('http://122.51.179.136:3000/api/companions/enhanced?limit=2', 'companions-result');
        }
        
        async function testAdmin() {
            const result = document.getElementById('admin-result');
            result.style.display = 'none';
            
            try {
                const start = Date.now();
                // 使用no-cors模式测试
                await fetch('http://122.51.179.136:8080', { mode: 'no-cors' });
                const time = Date.now() - start;
                
                result.className = 'result success';
                result.innerHTML = '✅ 管理后台可访问 (' + time + 'ms)<br>' + 
                                  '<a href="http://122.51.179.136:8080" target="_blank">点击访问管理后台</a><br>' +
                                  '时间: ' + new Date().toLocaleTimeString();
                result.style.display = 'block';
            } catch (error) {
                result.className = 'result error';
                result.innerHTML = '❌ 管理后台无法访问<br>' + 
                                  '错误: ' + error.message + '<br>' +
                                  '时间: ' + new Date().toLocaleTimeString();
                result.style.display = 'block';
            }
        }
        
        // 自动测试健康检查
        setTimeout(testHealth, 1000);
    </script>
</body>
</html>
    `;
    
    res.send(html);
});

module.exports = router;