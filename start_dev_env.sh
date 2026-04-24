#!/bin/bash
# 医小伴APP开发环境启动脚本
# 创建时间：2026年4月19日

echo "=== 医小伴APP开发环境启动 ==="
echo "时间: $(date)"
echo ""

# 1. 检查并启动MySQL
echo "1. 检查MySQL数据库..."
if systemctl is-active --quiet mysql; then
    echo "   ✅ MySQL已运行"
else
    echo "   ⚠️ MySQL未运行，尝试启动..."
    sudo systemctl start mysql 2>/dev/null && echo "   ✅ MySQL启动成功" || echo "   ❌ MySQL启动失败"
fi

# 2. 创建数据库和表
echo ""
echo "2. 初始化数据库..."
mysql -u root -pyixiaoban123 -e "CREATE DATABASE IF NOT EXISTS yixiaoban_dev CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;" 2>/dev/null
if [ $? -eq 0 ]; then
    echo "   ✅ 数据库创建/验证成功"
else
    echo "   ❌ 数据库连接失败"
    exit 1
fi

# 3. 运行基础迁移
echo ""
echo "3. 运行数据库迁移..."
for sql_file in backend/migrations/00[1-3]*.sql; do
    if [ -f "$sql_file" ]; then
        echo "   执行: $(basename $sql_file)"
        mysql -u root -pyixiaoban123 yixiaoban_dev < "$sql_file" 2>/dev/null | grep -v "Using a password" | grep -v "Warning"
    fi
done
echo "   ✅ 基础迁移完成"

# 4. 运行支付系统迁移
echo ""
echo "4. 运行支付系统迁移..."
if [ -f "backend/migrations/007_simple_payment_system.sql" ]; then
    mysql -u root -pyixiaoban123 yixiaoban_dev < backend/migrations/007_simple_payment_system.sql 2>/dev/null
    echo "   ✅ 支付系统迁移完成"
else
    echo "   ⚠️ 支付迁移文件不存在，创建中..."
    # 这里可以添加创建迁移文件的逻辑
fi

# 5. 检查后端依赖
echo ""
echo "5. 检查后端依赖..."
cd backend
if [ -f "package.json" ]; then
    echo "   ✅ package.json存在"
    if [ -d "node_modules" ]; then
        echo "   ✅ node_modules存在"
    else
        echo "   ⚠️ node_modules不存在，需要运行: npm install"
    fi
else
    echo "   ❌ package.json不存在"
fi
cd ..

# 6. 启动开发服务器（如果未运行）
echo ""
echo "6. 检查开发服务器..."
if pgrep -f "node.*server.js" > /dev/null; then
    echo "   ✅ 开发服务器已在运行"
else
    echo "   ⚠️ 开发服务器未运行"
    echo "   启动命令: cd backend && npm start"
fi

# 7. 显示开发信息
echo ""
echo "=== 开发环境信息 ==="
echo "数据库: yixiaoban_dev (MySQL)"
echo "后端API: http://localhost:3000 (如果运行)"
echo "管理后台: http://localhost:8080 (如果运行)"
echo "工作目录: /root/.openclaw/workspace/yixiaoban_app"
echo ""
echo "=== 常用命令 ==="
echo "启动后端: cd backend && npm start"
echo "查看日志: tail -f backend.log"
echo "测试API: curl http://localhost:3000/api/hospitals"
echo "数据库连接: mysql -u root -pyixiaoban123 yixiaoban_dev"
echo ""
echo "环境检查完成！"