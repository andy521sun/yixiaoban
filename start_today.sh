#!/bin/bash

# 医小伴APP今日开发启动脚本
# 自动启动所需服务，打开相关文件

echo "🚀 医小伴APP开发环境启动"
echo "📅 日期: $(date '+%Y年%m月%d日 %H:%M')"
echo "🎯 今日目标: 完成预约流程核心页面 (+5%进度)"
echo ""

# 检查服务状态
echo "🔍 检查服务状态..."
if curl -s http://localhost:3000/health > /dev/null 2>&1; then
    echo "✅ 后端API服务运行正常"
else
    echo "⚠️  后端API服务未运行，正在启动..."
    cd /root/.openclaw/workspace/yixiaoban_app/backend
    nohup npm start > server.log 2>&1 &
    sleep 3
    echo "✅ 后端API服务已启动"
fi

if curl -s http://localhost:8080 > /dev/null 2>&1; then
    echo "✅ 管理后台运行正常"
else
    echo "⚠️  管理后台未运行"
fi

echo ""
echo "📋 今日任务清单:"
echo "1. 📱 移动端 - 预约选择页面 (appointment_select_page.dart)"
echo "2. 📱 移动端 - 预约确认页面 (appointment_confirm_page.dart)"
echo "3. 📱 移动端 - 支付页面 (payment_page.dart)"
echo "4. 📱 移动端 - 订单状态页面 (order_status_page.dart)"
echo "5. 🔧 后端 - 订单API开发 (orders.js)"
echo "6. 🔧 后端 - 数据库迁移"
echo ""

echo "📁 相关文件路径:"
echo "移动端页面: /root/.openclaw/workspace/yixiaoban_app/mobile/patient_app/lib/ui/pages/"
echo "后端API: /root/.openclaw/workspace/yixiaoban_app/backend/src/routes/"
echo "数据库迁移: /root/.openclaw/workspace/yixiaoban_app/backend/migrations/"
echo ""

echo "🛠️ 开发命令:"
echo "启动Flutter开发: cd /root/.openclaw/workspace/yixiaoban_app/mobile/patient_app && flutter run --debug"
echo "查看后端日志: tail -f /root/.openclaw/workspace/yixiaoban_app/backend/server.log"
echo "测试API: curl http://localhost:3000/api/health"
echo "更新进度: ./update_progress.sh <模块> <完成度> \"备注\""
echo ""

echo "📊 当前进度:"
echo "总体进度: 85%"
echo "后端API: 95%"
echo "移动端: 75%"
echo "管理后台: 70%"
echo "部署运维: 80%"
echo ""

echo "🎯 今日目标进度: 90% (+5%)"
echo ""

echo "📝 今日检查点:"
echo "上午12:00 - 预约选择页面完成80%，预约确认页面完成50%"
echo "下午16:00 - 支付页面完成70%，订单状态页面完成60%"
echo "晚上20:00 - 所有页面开发完成，基本流程联调成功"
echo ""

echo "🔗 有用链接:"
echo "开发文档: /root/.openclaw/workspace/yixiaoban_app/详细开发计划.md"
echo "今日任务: /root/.openclaw/workspace/yixiaoban_app/今日开发任务.md"
echo "进度看板: /root/.openclaw/workspace/yixiaoban_app/开发进度看板.md"
echo ""

echo "💡 温馨提示:"
echo "1. 每完成一个任务，记得更新进度看板"
echo "2. 遇到问题及时记录和沟通"
echo "3. 保持代码规范，及时提交"
echo "4. 注意休息，保持高效"
echo ""

echo "🏁 开始今天的开发工作吧！祝您顺利！"