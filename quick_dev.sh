#!/bin/bash

# 医小伴APP快速开发脚本
# 作者：OpenClaw AI Assistant
# 日期：2026-04-06

set -e

echo "================================================"
echo "🏥 医小伴陪诊APP - 快速开发环境"
echo "================================================"

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 函数：打印带颜色的消息
print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 函数：检查服务是否运行
check_service() {
    local port=$1
    local service=$2
    
    if nc -z localhost $port 2>/dev/null; then
        print_success "$service 运行在端口 $port"
        return 0
    else
        print_warning "$service 未在端口 $port 运行"
        return 1
    fi
}

# 函数：启动后端服务
start_backend() {
    print_info "启动后端API服务..."
    
    # 检查是否已运行
    if check_service 3000 "后端API"; then
        print_warning "后端服务已在运行，跳过启动"
        return
    fi
    
    cd backend
    nohup node src/server.js > server.log 2>&1 &
    BACKEND_PID=$!
    echo $BACKEND_PID > ../backend.pid
    
    # 等待启动
    sleep 3
    
    if check_service 3000 "后端API"; then
        print_success "后端API服务启动成功 (PID: $BACKEND_PID)"
    else
        print_error "后端API服务启动失败，请检查日志: backend/server.log"
        exit 1
    fi
    
    cd ..
}

# 函数：启动管理后台
start_admin() {
    print_info "启动管理后台..."
    
    # 检查是否已运行
    if check_service 8080 "管理后台"; then
        print_warning "管理后台已在运行，跳过启动"
        return
    fi
    
    cd admin
    nohup python3 -m http.server 8080 --directory dist > admin.log 2>&1 &
    ADMIN_PID=$!
    echo $ADMIN_PID > ../admin.pid
    
    # 等待启动
    sleep 2
    
    if check_service 8080 "管理后台"; then
        print_success "管理后台启动成功 (PID: $ADMIN_PID)"
    else
        print_warning "管理后台启动失败，但继续其他服务"
    fi
    
    cd ..
}

# 函数：停止服务
stop_services() {
    print_info "停止所有服务..."
    
    # 停止后端
    if [ -f backend.pid ]; then
        BACKEND_PID=$(cat backend.pid)
        if kill -0 $BACKEND_PID 2>/dev/null; then
            kill $BACKEND_PID
            print_success "已停止后端服务 (PID: $BACKEND_PID)"
        fi
        rm -f backend.pid
    fi
    
    # 停止管理后台
    if [ -f admin.pid ]; then
        ADMIN_PID=$(cat admin.pid)
        if kill -0 $ADMIN_PID 2>/dev/null; then
            kill $ADMIN_PID
            print_success "已停止管理后台 (PID: $ADMIN_PID)"
        fi
        rm -f admin.pid
    fi
    
    # 清理可能的残留进程
    pkill -f "node src/server.js" 2>/dev/null || true
    pkill -f "python3 -m http.server 8080" 2>/dev/null || true
}

# 函数：显示服务状态
show_status() {
    echo ""
    echo "================================================"
    echo "📊 服务状态"
    echo "================================================"
    
    check_service 3000 "后端API"
    check_service 8080 "管理后台"
    
    echo ""
    echo "🔗 访问地址："
    echo "   API服务:      http://localhost:3000"
    echo "   管理后台:     http://localhost:8080"
    echo ""
    echo "🩺 健康检查："
    echo "   curl http://localhost:3000/health"
    echo ""
    echo "📚 API文档："
    echo "   curl http://localhost:3000/api"
    echo ""
    echo "📁 项目目录："
    echo "   后端:         $(pwd)/backend"
    echo "   管理后台:     $(pwd)/admin"
    echo "   移动端:       $(pwd)/mobile"
    echo ""
    echo "📋 开发进度："
    echo "   总体进度:     80%"
    echo "   后端API:      95%"
    echo "   Flutter移动端: 75%"
    echo "   管理后台:     70%"
}

# 函数：测试API
test_api() {
    print_info "测试API接口..."
    
    echo ""
    echo "1. 健康检查："
    curl -s http://localhost:3000/health | python3 -m json.tool
    
    echo ""
    echo "2. 医院列表（增强版）："
    curl -s "http://localhost:3000/api/hospitals/enhanced?limit=2" | python3 -m json.tool | grep -A5 '"name"'
    
    echo ""
    echo "3. 陪诊师列表（增强版）："
    curl -s "http://localhost:3000/api/companions/enhanced?limit=2" | python3 -m json.tool | grep -A5 '"name"'
}

# 函数：显示帮助
show_help() {
    echo "使用方法: $0 [命令]"
    echo ""
    echo "命令:"
    echo "  start     启动所有服务"
    echo "  stop      停止所有服务"
    echo "  restart   重启所有服务"
    echo "  status    显示服务状态"
    echo "  test      测试API接口"
    echo "  help      显示帮助信息"
    echo ""
    echo "示例:"
    echo "  $0 start     # 启动开发环境"
    echo "  $0 status    # 查看服务状态"
    echo "  $0 test      # 测试API"
    echo "  $0 stop      # 停止服务"
}

# 主程序
case "$1" in
    "start")
        print_info "启动医小伴APP开发环境..."
        start_backend
        start_admin
        show_status
        ;;
    
    "stop")
        stop_services
        print_success "所有服务已停止"
        ;;
    
    "restart")
        print_info "重启医小伴APP开发环境..."
        stop_services
        sleep 2
        start_backend
        start_admin
        show_status
        ;;
    
    "status")
        show_status
        ;;
    
    "test")
        test_api
        ;;
    
    "help"|"-h"|"--help")
        show_help
        ;;
    
    *)
        if [ -z "$1" ]; then
            show_help
        else
            print_error "未知命令: $1"
            echo ""
            show_help
            exit 1
        fi
        ;;
esac

echo ""
echo "================================================"
echo "🏥 医小伴陪诊APP - 温暖就医，专业陪伴"
echo "================================================"