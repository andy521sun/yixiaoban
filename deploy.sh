#!/bin/bash
# 医小伴 - Docker部署脚本
# 用法: bash deploy.sh [start|stop|restart|status|logs]

set -e

NETWORK="yixiaoban_app_yixiaoban_net"
MYSQL_IMAGE="mysql:8.0"
BACKEND_IMAGE="yixiaoban_app_backend:latest"
NGINX_CONFIG="/root/.openclaw/workspace/yixiaoban_app/nginx-host.conf"

# 创建网络
create_network() {
  docker network inspect $NETWORK >/dev/null 2>&1 || docker network create $NETWORK
}

start() {
  echo "🚀 启动医小伴系统..."
  create_network

  # MySQL
  docker ps -a --format '{{.Names}}' | grep -q yixiaoban_mysql || \
  docker run -d --name yixiaoban_mysql --restart always \
    -e MYSQL_ROOT_PASSWORD=root123456 \
    -e MYSQL_DATABASE=yixiaoban \
    -e MYSQL_USER=yixiaoban \
    -e MYSQL_PASSWORD=yixiaoban123 \
    -p 3307:3306 \
    -v mysql_data:/var/lib/mysql \
    -v /root/.openclaw/workspace/yixiaoban_app/init.sql:/docker-entrypoint-initdb.d/init.sql \
    --network $NETWORK \
    $MYSQL_IMAGE \
    --character-set-server=utf8mb4 --collation-server=utf8mb4_unicode_ci
  echo "  ✅ MySQL 已启动 (端口 3307)"

  # 等待MySQL就绪
  echo "  ⏳ 等待MySQL就绪..."
  for i in $(seq 1 30); do
    docker exec yixiaoban_mysql mysqladmin ping -h localhost --silent 2>/dev/null && break
    sleep 2
  done

  # 构建并启动后端
  echo "  🔨 构建后端镜像..."
  cd /root/.openclaw/workspace/yixiaoban_app
  docker build -t $BACKEND_IMAGE . 2>&1 | tail -1

  docker rm -f yixiaoban_backend 2>/dev/null || true
  docker run -d --name yixiaoban_backend --restart always \
    -e NODE_ENV=production \
    -e DB_HOST=yixiaoban_mysql \
    -e DB_PORT=3306 \
    -e DB_USER=yixiaoban \
    -e DB_PASSWORD=yixiaoban123 \
    -e DB_NAME=yixiaoban \
    -e JWT_SECRET=yixiaoban_jwt_secret_20240331 \
    -e SMS_MOCK=true \
    -e SERVER_DOMAIN=https://andysun521.online \
    -p 3000:3000 \
    --network $NETWORK \
    $BACKEND_IMAGE
  echo "  ✅ 后端已启动 (端口 3000)"

  # 启动Nginx（宿主机）
  /usr/sbin/nginx -t 2>/dev/null && /usr/sbin/nginx -s reload 2>/dev/null || /usr/sbin/nginx
  echo "  ✅ Nginx 已启动 (端口 80/443, https://andysun521.online)"

  echo ""
  echo "🎉 所有服务已启动!"
  echo "   管理后台: https://andysun521.online/admin.html"
  echo "   API:      https://andysun521.online/api"
}

stop() {
  echo "🛑 停止系统..."
  docker stop yixiaoban_backend yixiaoban_mysql 2>/dev/null || true
  /usr/sbin/nginx -s stop 2>/dev/null || true
  echo "  ✅ 已停止"
}

status() {
  echo "📊 系统状态:"
  docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" 2>/dev/null
  echo ""
  echo "   管理后台: https://andysun521.online/admin.html"
}

logs() {
  docker logs -f --tail 50 yixiaoban_backend
}

case "${1:-start}" in
  start) start ;;
  stop) stop ;;
  restart) stop; sleep 2; start ;;
  status) status ;;
  logs) logs ;;
  *) echo "用法: bash deploy.sh [start|stop|restart|status|logs]" ;;
esac
