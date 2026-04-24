#!/bin/bash

echo "================================================"
echo "🔍 医小伴陪诊APP - 环境检查工具"
echo "================================================"

echo ""
echo "1. 检查操作系统..."
if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    echo "   ✅ Linux 系统"
    OS="linux"
elif [[ "$OSTYPE" == "darwin"* ]]; then
    echo "   ✅ macOS 系统"
    OS="macos"
elif [[ "$OSTYPE" == "cygwin" ]] || [[ "$OSTYPE" == "msys" ]] || [[ "$OSTYPE" == "win32" ]]; then
    echo "   ⚠️  Windows 系统 - 建议使用 WSL2"
    OS="windows"
else
    echo "   ❓ 未知系统: $OSTYPE"
    OS="unknown"
fi

echo ""
echo "2. 检查 Docker..."
if command -v docker &> /dev/null; then
    DOCKER_VERSION=$(docker --version | cut -d' ' -f3 | tr -d ',')
    echo "   ✅ Docker 已安装: $DOCKER_VERSION"
    
    # 检查 Docker 服务状态
    if docker info &> /dev/null; then
        echo "   ✅ Docker 服务运行正常"
    else
        echo "   ❌ Docker 服务未运行"
        echo "     请启动 Docker Desktop 或运行: sudo systemctl start docker"
    fi
else
    echo "   ❌ Docker 未安装"
    echo ""
    echo "   安装指南:"
    if [[ "$OS" == "macos" ]]; then
        echo "   - 下载 Docker Desktop: https://www.docker.com/products/docker-desktop"
        echo "   - 或使用 Homebrew: brew install --cask docker"
    elif [[ "$OS" == "linux" ]]; then
        echo "   - Ubuntu/Debian: sudo apt update && sudo apt install -y docker.io"
        echo "   - CentOS/RHEL: sudo yum install -y docker"
        echo "   - 启动服务: sudo systemctl start docker && sudo systemctl enable docker"
        echo "   - 添加用户到 docker 组: sudo usermod -aG docker \$USER"
    else
        echo "   - 请访问 https://www.docker.com/products/docker-desktop"
    fi
fi

echo ""
echo "3. 检查 Docker Compose..."
if command -v docker-compose &> /dev/null; then
    DOCKER_COMPOSE_VERSION=$(docker-compose --version | cut -d' ' -f3 | tr -d ',')
    echo "   ✅ Docker Compose 已安装: $DOCKER_COMPOSE_VERSION"
else
    echo "   ❌ Docker Compose 未安装"
    echo ""
    echo "   安装指南:"
    if [[ "$OS" == "macos" ]]; then
        echo "   - Docker Desktop 已包含 Docker Compose"
        echo "   - 或使用 Homebrew: brew install docker-compose"
    elif [[ "$OS" == "linux" ]]; then
        echo "   - Ubuntu/Debian: sudo apt install -y docker-compose"
        echo "   - 或从 GitHub 下载:"
        echo "     sudo curl -L \"https://github.com/docker/compose/releases/latest/download/docker-compose-\$(uname -s)-\$(uname -m)\" -o /usr/local/bin/docker-compose"
        echo "     sudo chmod +x /usr/local/bin/docker-compose"
    fi
fi

echo ""
echo "4. 检查系统资源..."
if [[ "$OS" == "linux" ]]; then
    TOTAL_MEM=$(free -h | awk '/^Mem:/ {print $2}')
    AVAIL_MEM=$(free -h | awk '/^Mem:/ {print $7}')
    echo "   📊 总内存: $TOTAL_MEM, 可用内存: $AVAIL_MEM"
    
    TOTAL_DISK=$(df -h / | awk 'NR==2 {print $2}')
    AVAIL_DISK=$(df -h / | awk 'NR==2 {print $4}')
    echo "   💾 总磁盘: $TOTAL_DISK, 可用磁盘: $AVAIL_DISK"
    
    CPU_CORES=$(nproc)
    echo "   ⚙️  CPU 核心数: $CPU_CORES"
fi

echo ""
echo "5. 检查项目文件..."
if [ -f "docker-compose.yml" ]; then
    echo "   ✅ docker-compose.yml 存在"
else
    echo "   ❌ docker-compose.yml 不存在"
    echo "     请确保在项目根目录运行此脚本"
fi

if [ -f "deploy.sh" ]; then
    echo "   ✅ deploy.sh 存在"
    chmod +x deploy.sh 2>/dev/null && echo "   ✅ deploy.sh 已设置为可执行"
else
    echo "   ❌ deploy.sh 不存在"
fi

if [ -d "backend" ] && [ -d "frontend" ] && [ -d "admin" ]; then
    echo "   ✅ 项目目录结构完整"
else
    echo "   ❌ 项目目录不完整"
fi

echo ""
echo "6. 检查端口占用..."
PORTS=(3000 8080 3001 3306 6379 80)
for port in "${PORTS[@]}"; do
    if [[ "$OS" == "linux" ]] || [[ "$OS" == "macos" ]]; then
        if lsof -i :$port &> /dev/null; then
            echo "   ⚠️  端口 $port 已被占用"
        else
            echo "   ✅ 端口 $port 可用"
        fi
    else
        echo "   ℹ️  端口检查跳过 (Windows)"
        break
    fi
done

echo ""
echo "================================================"
echo "📋 部署建议:"
echo "================================================"

if command -v docker &> /dev/null && command -v docker-compose &> /dev/null && docker info &> /dev/null; then
    echo ""
    echo "✅ 环境检查通过！可以开始部署。"
    echo ""
    echo "部署步骤:"
    echo "1. 配置环境变量:"
    echo "   cp .env.example .env"
    echo "   nano .env  # 编辑配置文件"
    echo ""
    echo "2. 运行部署脚本:"
    echo "   ./deploy.sh"
    echo ""
    echo "3. 访问服务:"
    echo "   - API: http://localhost:3000"
    echo "   - 管理后台: http://localhost:8080"
    echo "   - 监控: http://localhost:3001"
else
    echo ""
    echo "❌ 环境检查未通过，请先安装和配置 Docker。"
    echo ""
    echo "请按照上面的提示安装必要的软件，然后重新运行此脚本。"
fi

echo ""
echo "📚 更多信息请查看:"
echo "   - INSTALL.md - 完整安装指南"
echo "   - README_COMPLETE.md - 项目文档"
echo "================================================"