#!/bin/bash

# 医小伴陪诊APP - 本地开发启动脚本

echo "================================================"
echo "🏥 医小伴陪诊APP - 本地开发环境"
echo "================================================"

# 检查Node.js
if ! command -v node &> /dev/null; then
    echo "❌ Node.js未安装"
    echo "   请安装Node.js: https://nodejs.org/"
    exit 1
fi

echo "✅ Node.js版本: $(node --version)"

# 进入项目目录
cd "$(dirname "$0")"

echo ""
echo "1. 启动后端API服务..."
cd backend
if [ ! -d "node_modules" ]; then
    echo "📦 安装后端依赖..."
    npm install
fi

echo "🚀 启动后端服务 (端口: 3000)..."
node src/server.js &
BACKEND_PID=$!
cd ..

echo ""
echo "2. 启动管理后台..."
cd admin
if [ ! -d "dist" ]; then
    echo "📦 构建管理后台..."
    npm run build
fi

echo "🚀 启动管理后台 (端口: 8080)..."
# 使用Python启动简单的HTTP服务器
python3 -m http.server 8080 --directory dist &
ADMIN_PID=$!
cd ..

echo ""
echo "3. 等待服务启动..."
sleep 3

echo ""
echo "================================================"
echo "🎉 医小伴陪诊APP已启动！"
echo "================================================"
echo ""
echo "📱 访问地址："
echo "   🔗 API服务:      http://localhost:3000"
echo "   🔗 管理后台:     http://localhost:8080"
echo ""
echo "🩺 健康检查："
echo "   curl http://localhost:3000/health"
echo "   curl http://localhost:3000/api"
echo ""
echo "🧪 测试API："
echo "   注册用户: curl -X POST http://localhost:3000/api/auth/register \\"
echo "     -H \"Content-Type: application/json\" \\"
echo "     -d '{\"phone\":\"13800138000\",\"password\":\"123456\",\"name\":\"测试用户\"}'"
echo ""
echo "   获取医院列表: curl http://localhost:3000/api/hospitals"
echo ""
echo "🔧 管理命令："
echo "   停止服务: kill $BACKEND_PID $ADMIN_PID"
echo "   查看日志: tail -f backend/logs/*.log"
echo ""
echo "================================================"
echo "🏥 温暖就医，专业陪伴"
echo "================================================"

# 等待用户输入
echo ""
read -p "按回车键停止服务..." -n 1

echo ""
echo "🛑 停止服务..."
kill $BACKEND_PID $ADMIN_PID 2>/dev/null
wait $BACKEND_PID $ADMIN_PID 2>/dev/null

echo "✅ 服务已停止"
echo "👋 再见！"