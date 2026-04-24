#!/bin/bash

# 医小伴APP进度更新工具
# 用法: ./update_progress.sh <模块> <完成度> [备注]

set -e

PROGRESS_FILE="/root/.openclaw/workspace/yixiaoban_app/开发进度看板.md"
DATE=$(date '+%Y年%m月%d日 %H:%M')

if [ $# -lt 2 ]; then
    echo "用法: $0 <模块> <完成度> [备注]"
    echo ""
    echo "可用模块:"
    echo "  backend      - 后端API系统"
    echo "  mobile       - Flutter移动端（患者）"
    echo "  companion    - Flutter移动端（陪诊师）"
    echo "  admin        - 管理后台"
    echo "  deploy       - 部署运维"
    echo "  overall      - 总体进度"
    echo ""
    echo "示例:"
    echo "  $0 backend 95 \"完成订单API开发\""
    echo "  $0 mobile 80 \"完成预约页面\""
    exit 1
fi

MODULE=$1
PROGRESS=$2
NOTE=${3:-"无备注"}

# 验证完成度
if ! [[ "$PROGRESS" =~ ^[0-9]+$ ]] || [ "$PROGRESS" -lt 0 ] || [ "$PROGRESS" -gt 100 ]; then
    echo "错误: 完成度必须是0-100的整数"
    exit 1
fi

case $MODULE in
    "backend")
        MODULE_NAME="后端API系统"
        ;;
    "mobile")
        MODULE_NAME="Flutter移动端（患者）"
        ;;
    "companion")
        MODULE_NAME="Flutter移动端（陪诊师）"
        ;;
    "admin")
        MODULE_NAME="管理后台"
        ;;
    "deploy")
        MODULE_NAME="部署运维"
        ;;
    "overall")
        MODULE_NAME="总体进度"
        ;;
    *)
        echo "错误: 未知模块 '$MODULE'"
        exit 1
        ;;
esac

echo "更新进度: $MODULE_NAME -> $PROGRESS%"
echo "备注: $NOTE"
echo "时间: $DATE"

# 备份原文件
cp "$PROGRESS_FILE" "${PROGRESS_FILE}.bak"

# 更新进度看板
if [ "$MODULE" = "overall" ]; then
    # 更新总体进度
    sed -i "s/## 📊 总体进度：.*%/## 📊 总体进度：$PROGRESS%/g" "$PROGRESS_FILE"
    
    # 在文件末尾添加更新记录
    echo "" >> "$PROGRESS_FILE"
    echo "## 📝 更新记录" >> "$PROGRESS_FILE"
    echo "- **$DATE**: 总体进度更新为 $PROGRESS% - $NOTE" >> "$PROGRESS_FILE"
else
    # 更新模块进度
    sed -i "s/| $MODULE_NAME | [0-9]*% |/| $MODULE_NAME | $PROGRESS% |/g" "$PROGRESS_FILE"
    
    # 在文件末尾添加更新记录
    echo "" >> "$PROGRESS_FILE"
    echo "## 📝 更新记录" >> "$PROGRESS_FILE"
    echo "- **$DATE**: $MODULE_NAME 进度更新为 $PROGRESS% - $NOTE" >> "$PROGRESS_FILE"
fi

echo ""
echo "✅ 进度更新成功!"
echo "📁 文件: $PROGRESS_FILE"
echo "📋 备份: ${PROGRESS_FILE}.bak"

# 显示当前总体进度
OVERALL=$(grep "## 📊 总体进度：" "$PROGRESS_FILE" | head -1 | grep -o '[0-9]*%')
echo ""
echo "📈 当前总体进度: $OVERALL"