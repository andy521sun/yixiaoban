#!/bin/bash

# 医小伴陪诊APP - 简化部署脚本
# 适用于本地开发测试

set -e

echo "================================================"
echo "🚀 医小伴陪诊APP - 本地开发测试部署"
echo "================================================"

# 检查Docker
if ! command -v docker &> /dev/null; then
    echo "❌ Docker未安装"
    exit 1
fi

if ! docker info &> /dev/null; then
    echo "❌ Docker服务未运行"
    exit 1
fi

echo ""
echo "1. 创建必要的目录..."
mkdir -p backend/logs backend/uploads
mkdir -p admin/dist
mkdir -p nginx/conf.d ssl

echo ""
echo "2. 构建Docker镜像..."
echo "构建后端服务..."
cd backend
npm install --production 2>/dev/null || echo "使用现有依赖"
cd ..

echo "构建管理后台..."
cd admin
npm run build 2>/dev/null
cd ..

echo ""
echo "3. 启动Docker服务..."
docker-compose up -d --build

echo ""
echo "4. 等待服务启动..."
sleep 10

echo ""
echo "5. 检查服务状态..."
docker-compose ps

echo ""
echo "================================================"
echo "🎉 部署完成！"
echo "================================================"
echo ""
echo "📱 访问地址："
echo "   API服务:      http://localhost:3000"
echo "   管理后台:     http://localhost:8080"
echo "   监控面板:     http://localhost:3001"
echo "   MySQL数据库:  localhost:3306 (root/yixiaoban123)"
echo "   Redis缓存:    localhost:6379"
echo ""
echo "🔧 管理命令："
echo "   查看日志:     docker-compose logs -f"
echo "   停止服务:     docker-compose down"
echo "   重启服务:     docker-compose restart"
echo "   进入容器:     docker-compose exec backend bash"
echo ""
echo "🩺 健康检查："
echo "   curl http://localhost:3000/health"
echo "   curl http://localhost:3000/api"
echo ""
echo "================================================"
echo "🏥 医小伴陪诊APP - 温暖就医，专业陪伴"
echo "================================================"