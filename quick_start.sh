#!/bin/bash

echo "================================================"
echo "🚀 医小伴陪诊APP - 快速启动（开发模式）"
echo "================================================"

echo ""
echo "这个脚本将帮助您在不使用 Docker 的情况下快速启动开发环境。"
echo "适合开发和测试使用。"
echo ""

# 检查 Node.js
if ! command -v node &> /dev/null; then
    echo "❌ Node.js 未安装"
    echo ""
    echo "安装 Node.js:"
    echo "1. 访问 https://nodejs.org/ 下载安装"
    echo "2. 或使用包管理器:"
    echo "   - macOS: brew install node"
    echo "   - Ubuntu: sudo apt install nodejs npm"
    echo "   - Windows: 下载安装包"
    exit 1
else
    NODE_VERSION=$(node --version)
    echo "✅ Node.js 已安装: $NODE_VERSION"
fi

# 检查 npm
if ! command -v npm &> /dev/null; then
    echo "❌ npm 未安装"
    exit 1
else
    NPM_VERSION=$(npm --version)
    echo "✅ npm 已安装: $NPM_VERSION"
fi

# 检查 MySQL（可选）
if command -v mysql &> /dev/null; then
    echo "✅ MySQL 客户端已安装"
else
    echo "⚠️  MySQL 客户端未安装，将使用 SQLite 替代"
fi

echo ""
echo "1. 启动后端服务..."
cd backend

if [ ! -f "package.json" ]; then
    echo "❌ backend/package.json 不存在"
    exit 1
fi

echo "   安装依赖..."
npm install

echo "   创建开发环境配置..."
cat > .env.development << 'EOF'
NODE_ENV=development
PORT=3000
DB_CLIENT=sqlite3
DB_CONNECTION_FILENAME=./dev.sqlite3
JWT_SECRET=dev_jwt_secret_123456
API_BASE_URL=http://localhost:3000
FRONTEND_URL=http://localhost:3000
EOF

echo "   启动开发服务器..."
echo ""
echo "   🔗 后端服务将在 http://localhost:3000 启动"
echo "   📊 健康检查: http://localhost:3000/health"
echo "   📚 API 文档: http://localhost:3000/api-docs"
echo ""
echo "   按 Ctrl+C 停止服务"
echo ""

# 在新终端中启动后端（如果支持）
if [[ "$OSTYPE" == "darwin"* ]]; then
    # macOS
    osascript -e 'tell app "Terminal" to do script "cd \"'$(pwd)'\" && npm run dev"'
elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
    # Linux
    gnome-terminal -- bash -c "cd $(pwd) && npm run dev; exec bash"
else
    # 直接在当前终端启动
    npm run dev
fi

cd ..