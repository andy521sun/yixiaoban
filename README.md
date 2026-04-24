# 医小伴陪诊APP

温暖亲切的医疗陪诊服务平台

## 技术栈
- 前端：Flutter 3.19 (iOS/Android/Web)
- 后端：Node.js + Express + TypeScript
- 数据库：MySQL 8.0 + Redis
- AI：通义千问API
- 支付：微信支付 + 支付宝
- 地图：高德地图
- 推送：极光推送

## 项目结构
```
yixiaoban_app/
├── frontend/          # Flutter用户端+陪诊师端
├── backend/           # Node.js后端API
├── admin/             # 管理后台(Vue3)
├── docs/              # 文档
└── scripts/           # 部署脚本
```

## 快速开始
```bash
# 安装依赖
cd frontend && flutter pub get
cd backend && npm install
cd admin && npm install

# 启动开发
flutter run
npm run dev
```

## 功能模块
- 用户端：预约陪诊、AI问诊、支付评价
- 陪诊师端：接单服务、路线导航、收入管理
- 管理后台：审核监控、财务统计、数据报表