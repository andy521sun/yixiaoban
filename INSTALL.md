# 医小伴陪诊APP - 安装部署指南

## 📦 快速开始

### 第一步：环境准备

#### 1. 安装 Docker 和 Docker Compose

**macOS:**
```bash
# 使用 Homebrew 安装
brew install docker docker-compose

# 或者下载 Docker Desktop
# https://www.docker.com/products/docker-desktop
```

**Ubuntu/Debian:**
```bash
# 更新包列表
sudo apt update

# 安装 Docker
sudo apt install -y docker.io docker-compose

# 启动 Docker 服务
sudo systemctl start docker
sudo systemctl enable docker

# 将当前用户加入 docker 组（避免使用 sudo）
sudo usermod -aG docker $USER
# 需要重新登录生效
```

**Windows:**
1. 下载 Docker Desktop：https://www.docker.com/products/docker-desktop
2. 安装并启动
3. 启用 WSL2（推荐）

#### 2. 验证安装
```bash
docker --version
docker-compose --version
```

### 第二步：获取项目代码

#### 方法A：直接使用当前目录
如果您已经在本目录中，直接进入下一步。

#### 方法B：下载项目包
```bash
# 创建项目目录
mkdir -p ~/projects/yixiaoban
cd ~/projects/yixiaoban

# 将当前所有文件复制到该目录
# （根据您的实际情况操作）
```

### 第三步：配置环境变量

```bash
# 进入项目目录
cd yixiaoban_app

# 创建环境变量文件
cp .env.example .env

# 编辑 .env 文件，配置必要的密钥
nano .env  # 或使用其他编辑器
```

**需要配置的密钥：**
```env
# 数据库配置（可以先用默认值）
DB_PASSWORD=yixiaoban123

# JWT密钥（生成随机密钥）
JWT_SECRET=yixiaoban_jwt_secret_$(date +%s)

# 阿里云百炼API（测试时可留空）
ALIYUN_BAILIAN_ACCESS_KEY=your_access_key_here
ALIYUN_BAILIAN_SECRET_KEY=your_secret_key_here

# 微信支付（测试时可留空）
WECHAT_APP_ID=your_wechat_app_id
WECHAT_MCH_ID=your_wechat_mch_id
WECHAT_API_KEY=your_wechat_api_key

# 支付宝（测试时可留空）
ALIPAY_APP_ID=your_alipay_app_id
ALIPAY_PRIVATE_KEY=your_alipay_private_key
ALIPAY_PUBLIC_KEY=your_alipay_public_key

# 高德地图（测试时可留空）
AMAP_WEB_KEY=your_amap_web_key
```

### 第四步：一键部署

```bash
# 给予部署脚本执行权限
chmod +x deploy.sh

# 运行部署脚本
./deploy.sh
```

部署脚本会自动：
1. 创建必要的目录结构
2. 配置 Nginx 反向代理
3. 构建 Docker 镜像
4. 启动所有服务
5. 运行数据库迁移
6. 导入初始数据

### 第五步：访问服务

部署完成后，可以通过以下方式访问：

#### 1. 直接访问（本地开发）
- **API服务**：http://localhost:3000
- **管理后台**：http://localhost:8080
- **监控面板**：http://localhost:3001

#### 2. 配置 hosts 文件（可选）
编辑 `/etc/hosts`（Linux/macOS）或 `C:\Windows\System32\drivers\etc\hosts`（Windows）：
```
127.0.0.1   api.yixiaoban.com
127.0.0.1   admin.yixiaoban.com
127.0.0.1   monitor.yixiaoban.com
```

然后可以通过域名访问：
- **API服务**：http://api.yixiaoban.com
- **管理后台**：http://admin.yixiaoban.com
- **监控面板**：http://monitor.yixiaoban.com

### 第六步：验证安装

#### 1. 检查服务状态
```bash
# 查看所有容器状态
docker-compose ps

# 查看日志
docker-compose logs -f

# 健康检查
curl http://localhost:3000/health
```

#### 2. 测试API接口
```bash
# 注册测试用户
curl -X POST http://localhost:3000/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "phone": "13800138000",
    "password": "123456",
    "name": "测试用户"
  }'

# 登录获取token
curl -X POST http://localhost:3000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "phone": "13800138000",
    "password": "123456"
  }'
```

## 🛠️ 管理命令

### 常用 Docker 命令
```bash
# 启动所有服务
docker-compose up -d

# 停止所有服务
docker-compose down

# 重启特定服务
docker-compose restart backend

# 查看日志
docker-compose logs -f backend
docker-compose logs --tail=100 backend

# 进入容器
docker-compose exec backend bash
docker-compose exec mysql mysql -u root -p

# 清理无用资源
docker system prune -a
```

### 数据库管理
```bash
# 进入 MySQL 容器
docker-compose exec mysql mysql -u root -p

# 运行数据库迁移
docker-compose exec backend npm run migrate

# 运行种子数据
docker-compose exec backend npm run seed

# 备份数据库
docker-compose exec mysql mysqldump -u root -p yixiaoban > backup.sql
```

## 🔧 开发模式

### 后端开发
```bash
cd backend

# 安装依赖
npm install

# 开发模式运行
npm run dev

# 运行测试
npm test

# 构建生产版本
npm run build
```

### 前端开发
```bash
cd frontend

# 安装 Flutter 依赖
flutter pub get

# 运行 iOS 模拟器
flutter run -d ios

# 运行 Android 模拟器
flutter run -d android

# 构建发布版本
flutter build ios
flutter build apk
```

### 管理后台开发
```bash
cd admin

# 安装依赖
npm install

# 开发模式运行
npm run dev

# 构建生产版本
npm run build
```

## 🚨 故障排除

### 常见问题

#### 1. 端口冲突
如果端口被占用，修改 `docker-compose.yml` 中的端口映射：
```yaml
ports:
  - "3001:3000"  # 改为其他端口
```

#### 2. 数据库连接失败
```bash
# 检查 MySQL 容器状态
docker-compose logs mysql

# 重启数据库
docker-compose restart mysql

# 检查网络
docker network ls
```

#### 3. 内存不足
```bash
# 查看 Docker 资源使用
docker stats

# 限制容器内存
# 在 docker-compose.yml 中添加：
#   deploy:
#     resources:
#       limits:
#         memory: 512M
```

#### 4. 镜像构建失败
```bash
# 清理缓存
docker system prune -a

# 重新构建
docker-compose build --no-cache
```

### 查看日志
```bash
# 查看所有服务日志
docker-compose logs -f

# 查看特定服务日志
docker-compose logs -f backend
docker-compose logs -f mysql
docker-compose logs -f nginx

# 查看错误日志
docker-compose logs --tail=100 | grep ERROR
```

## 📡 生产环境部署

### 云服务器部署建议

#### 1. 服务器要求
- **CPU**：2核以上
- **内存**：4GB以上
- **存储**：50GB以上
- **系统**：Ubuntu 20.04/22.04 LTS

#### 2. 安全配置
```bash
# 更新系统
sudo apt update && sudo apt upgrade -y

# 配置防火墙
sudo ufw allow 22/tcp
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw enable

# 配置 SSH 密钥登录
# 禁用密码登录
```

#### 3. 域名和 SSL
```bash
# 安装 Certbot 获取 SSL 证书
sudo apt install -y certbot python3-certbot-nginx

# 获取证书
sudo certbot --nginx -d api.yixiaoban.com -d admin.yixiaoban.com

# 自动续期
sudo certbot renew --dry-run
```

### 性能优化

#### 1. 数据库优化
```sql
-- 添加索引
CREATE INDEX idx_orders_status ON orders(status);
CREATE INDEX idx_users_phone ON users(phone);

-- 优化查询
EXPLAIN SELECT * FROM orders WHERE status = 'pending';
```

#### 2. Nginx 优化
```nginx
# 在 nginx.conf 中添加
worker_processes auto;
worker_connections 1024;
keepalive_timeout 65;
gzip on;
```

#### 3. Docker 优化
```yaml
# 在 docker-compose.yml 中添加资源限制
services:
  backend:
    deploy:
      resources:
        limits:
          memory: 512M
          cpus: '0.5'
```

## 📞 技术支持

### 获取帮助
- **文档**：查看 README_COMPLETE.md 获取完整文档
- **问题反馈**：记录错误日志并联系技术支持
- **社区支持**：加入开发者社区讨论

### 紧急恢复
```bash
# 备份重要数据
docker-compose exec mysql mysqldump -u root -p yixiaoban > backup_$(date +%Y%m%d).sql

# 快速重启
docker-compose down && docker-compose up -d

# 回滚到上一个版本
git checkout previous-version
docker-compose up -d --build
```

---

**医小伴陪诊APP** - 温暖就医，专业陪伴 🏥❤️

如有问题，请查看日志文件或联系技术支持。