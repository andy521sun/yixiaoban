# 医小伴陪诊APP · 完整版

温暖亲切的医疗陪诊服务平台 - 全栈可运行版本

## 🚀 项目概述

医小伴是一个专业的医疗陪诊服务平台，连接患者与专业陪诊师，提供温暖、专业的就医陪伴服务。

### 核心功能
- 👤 **双端用户系统**：患者端 + 陪诊师端
- 🏥 **智能预约**：医院科室选择、时间预约
- 💬 **实时聊天**：患者与陪诊师实时沟通
- 🤖 **AI问诊**：通义千问AI症状咨询、报告解读
- 💳 **全渠道支付**：微信支付 + 支付宝
- 🗺️ **地图定位**：高德地图集成
- 📊 **管理后台**：数据统计、订单管理、财务监控

## 🏗️ 技术架构

### 后端技术栈
- **运行时**：Node.js + TypeScript
- **框架**：Express.js
- **数据库**：MySQL 8.0 + Redis
- **ORM**：Knex.js
- **实时通信**：Socket.IO
- **AI服务**：阿里云百炼（通义千问）
- **支付集成**：微信支付 + 支付宝
- **地图服务**：高德地图API

### 前端技术栈
- **移动端**：Flutter 3.19（iOS/Android/Web）
- **状态管理**：Provider + Riverpod
- **路由**：Go Router
- **网络请求**：Dio + Retrofit
- **地图**：高德地图Flutter插件
- **支付**：微信/支付宝Flutter插件
- **实时通信**：Socket.IO Client

### 管理后台
- **框架**：Vue 3 + TypeScript
- **UI组件**：Element Plus
- **状态管理**：Pinia
- **图表**：ECharts

### 部署运维
- **容器化**：Docker + Docker Compose
- **反向代理**：Nginx
- **监控**：Prometheus + Grafana
- **数据库**：MySQL + Redis
- **CI/CD**：GitHub Actions（预留）

## 📁 项目结构

```
yixiaoban_app/
├── backend/                    # Node.js后端API
│   ├── src/
│   │   ├── config/           # 配置文件
│   │   ├── middleware/       # 中间件
│   │   ├── routes/          # API路由
│   │   ├── services/        # 业务服务
│   │   ├── validators/      # 数据验证
│   │   └── server.ts        # 主入口
│   ├── migrations/          # 数据库迁移
│   ├── seeds/              # 种子数据
│   └── package.json
│
├── frontend/                 # Flutter移动端
│   ├── lib/
│   │   ├── core/           # 核心配置
│   │   ├── features/       # 功能模块
│   │   └── main.dart       # 主入口
│   └── pubspec.yaml
│
├── admin/                    # Vue管理后台
│   ├── src/
│   │   ├── views/          # 页面组件
│   │   ├── components/     # 通用组件
│   │   ├── api/           # API接口
│   │   └── main.ts        # 主入口
│   └── package.json
│
├── nginx/                    # Nginx配置
├── monitoring/              # 监控配置
├── scripts/                 # 部署脚本
└── docker-compose.yml       # Docker编排
```

## 🚀 快速开始

### 1. 环境准备

```bash
# 安装依赖工具
brew install docker docker-compose  # macOS
# 或
apt-get install docker docker-compose  # Ubuntu

# 克隆项目
git clone <repository-url>
cd yixiaoban_app
```

### 2. 配置环境变量

```bash
# 复制环境变量模板
cp .env.example .env

# 编辑 .env 文件，配置以下密钥：
# - 数据库密码
# - JWT密钥
# - 阿里云百炼API密钥
# - 微信支付配置
# - 支付宝配置
# - 高德地图API密钥
```

### 3. 一键部署

```bash
# 给予执行权限
chmod +x deploy.sh

# 运行部署脚本
./deploy.sh
```

### 4. 访问服务

部署完成后，可以通过以下地址访问：

- **API服务**：http://api.yixiaoban.com
- **管理后台**：http://admin.yixiaoban.com
- **监控面板**：http://monitor.yixiaoban.com

## 📱 功能模块详解

### 1. 用户认证系统
- 手机号注册/登录
- 微信一键登录
- JWT令牌认证
- 角色权限控制（患者/陪诊师/管理员）

### 2. 陪诊预约系统
- 医院科室选择
- 时间预约
- 服务类型选择（小时/全天/定制）
- 费用实时计算
- 订单状态跟踪

### 3. 实时通信系统
- WebSocket实时聊天
- 文字/图片/语音消息
- 消息已读状态
- 聊天记录存储

### 4. AI智能服务
- 症状咨询（通义千问）
- 报告解读
- 用药指导
- 健康知识问答
- 7×24智能客服

### 5. 支付系统
- 微信支付（JSAPI/NATIVE）
- 支付宝支付
- 余额支付
- 退款处理
- 支付回调

### 6. 地图服务
- 医院位置展示
- 路线规划
- 实时定位
- 地理围栏

### 7. 管理后台
- 数据统计仪表板
- 用户管理
- 订单管理
- 财务管理
- 系统设置

## 🔧 开发指南

### 后端开发

```bash
cd backend

# 安装依赖
npm install

# 开发模式
npm run dev

# 构建
npm run build

# 数据库迁移
npm run migrate

# 种子数据
npm run seed
```

### 移动端开发

```bash
cd frontend

# 安装依赖
flutter pub get

# 运行iOS
flutter run -d ios

# 运行Android
flutter run -d android

# 构建发布版
flutter build ios
flutter build apk
```

### 管理后台开发

```bash
cd admin

# 安装依赖
npm install

# 开发模式
npm run dev

# 构建
npm run build
```

## 🗄️ 数据库设计

### 核心表结构

1. **users** - 用户表
2. **companions** - 陪诊师资料表
3. **hospitals** - 医院表
4. **orders** - 订单表
5. **payments** - 支付记录表
6. **chat_messages** - 聊天消息表
7. **reviews** - 评价表
8. **ai_consultations** - AI问诊记录表

### 数据库迁移

```bash
# 创建新迁移
npx knex migrate:make <migration_name>

# 运行迁移
npx knex migrate:latest

# 回滚迁移
npx knex migrate:rollback
```

## 🔐 安全配置

### 1. JWT配置
```env
JWT_SECRET=your_jwt_secret_key
JWT_EXPIRES_IN=7d
```

### 2. 数据库安全
- 使用强密码
- 限制远程访问
- 定期备份
- 启用SSL连接

### 3. API安全
- 请求频率限制
- SQL注入防护
- XSS攻击防护
- CSRF保护

### 4. 支付安全
- 支付回调验证
- 敏感信息加密
- 交易日志记录
- 异常监控

## 📊 监控告警

### 1. 应用监控
- 接口响应时间
- 错误率监控
- 服务健康检查
- 数据库性能监控

### 2. 业务监控
- 订单转化率
- 用户活跃度
- 支付成功率
- 客服响应时间

### 3. 告警配置
- 服务宕机告警
- 支付失败告警
- 异常流量告警
- 数据库连接告警

## 🔄 持续集成

### GitHub Actions 配置
```yaml
name: CI/CD Pipeline

on:
  push:
    branches: [ main ]
  pull_request:
    branches: [ main ]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Run tests
        run: |
          cd backend && npm test
          cd frontend && flutter test
          
  deploy:
    needs: test
    runs-on: ubuntu-latest
    if: github.ref == 'refs/heads/main'
    steps:
      - uses: actions/checkout@v3
      - name: Deploy to production
        run: |
          ./deploy.sh
```

## 📈 性能优化

### 1. 前端优化
- 图片懒加载
- 代码分割
- 缓存策略
- 离线支持

### 2. 后端优化
- 数据库索引优化
- Redis缓存
- 连接池配置
- 负载均衡

### 3. 网络优化
- CDN加速
- HTTP/2支持
- Gzip压缩
- 资源合并

## 🆘 故障排除

### 常见问题

1. **数据库连接失败**
   ```bash
   # 检查数据库服务状态
   docker-compose ps mysql
   
   # 查看日志
   docker-compose logs mysql
   ```

2. **支付回调失败**
   - 检查回调URL配置
   - 验证签名算法
   - 查看支付日志

3. **Socket连接失败**
   - 检查WebSocket端口
   - 验证CORS配置
   - 查看Socket.IO日志

4. **AI服务不可用**
   - 检查API密钥
   - 验证网络连接
   - 查看服务配额

### 日志查看

```bash
# 查看所有服务日志
docker-compose logs -f

# 查看特定服务日志
docker-compose logs -f backend

# 查看错误日志
docker-compose logs --tail=100 | grep ERROR
```

## 📞 技术支持

### 文档资源
- [API接口文档](http://api.yixiaoban.com/docs)
- [部署指南](docs/deployment.md)
- [开发规范](docs/development.md)
- [故障手册](docs/troubleshooting.md)

### 联系支持
- **技术支持**：support@yixiaoban.com
- **商务合作**：business@yixiaoban.com
- **紧急故障**：+86 400-123-4567

## 📄 许可证

本项目采用 MIT 许可证 - 查看 [LICENSE](LICENSE) 文件了解详情。

## 🙏 致谢

感谢以下开源项目和技术：

- Flutter - Google的跨平台UI工具包
- Node.js - JavaScript运行时
- Vue.js - 渐进式JavaScript框架
- Docker - 容器化平台
- 阿里云百炼 - AI大模型服务
- 微信支付/支付宝 - 支付服务
- 高德地图 - 地图服务

---

**医小伴陪诊APP** - 让就医更温暖，让陪伴更专业 🏥❤️