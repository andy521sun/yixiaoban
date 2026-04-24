FROM node:22-alpine

WORKDIR /app

# 安装pm2
RUN npm install -g pm2

# 复制依赖文件
COPY backend/package*.json ./
RUN npm install --production

# 复制源码
COPY backend/src ./src
COPY backend/public ./public

EXPOSE 3000

CMD ["pm2-runtime", "src/server.js"]
