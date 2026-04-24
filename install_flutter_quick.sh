#!/bin/bash

echo "🚀 快速安装Flutter环境"
echo "====================="

# 1. 检查是否已安装
if command -v flutter &> /dev/null; then
    echo "✅ Flutter已安装"
    flutter --version
    exit 0
fi

# 2. 创建安装目录
FLUTTER_DIR="$HOME/flutter"
if [ ! -d "$FLUTTER_DIR" ]; then
    echo "📁 创建Flutter目录: $FLUTTER_DIR"
    mkdir -p "$FLUTTER_DIR"
fi

# 3. 下载Flutter SDK（使用较小的开发版本）
echo "⬇️  下载Flutter SDK..."
cd /tmp
if [ ! -f "flutter_linux.tar.xz" ]; then
    # 尝试从镜像下载
    wget -q --show-progress -O flutter_linux.tar.xz \
        https://storage.flutter-io.cn/flutter_infra_release/releases/stable/linux/flutter_linux_3.22.0-stable.tar.xz || \
    wget -q --show-progress -O flutter_linux.tar.xz \
        https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_3.22.0-stable.tar.xz
fi

# 4. 解压
if [ -f "flutter_linux.tar.xz" ]; then
    echo "📦 解压Flutter SDK..."
    tar xf flutter_linux.tar.xz -C "$HOME"
    echo "✅ Flutter SDK解压完成"
else
    echo "⚠️  下载失败，尝试Git克隆..."
    cd "$HOME"
    if [ ! -d "flutter" ]; then
        git clone --depth 1 https://github.com/flutter/flutter.git -b stable
    fi
fi

# 5. 配置环境变量
echo "⚙️  配置环境变量..."
if ! grep -q "flutter/bin" ~/.bashrc; then
    echo 'export PATH="$PATH:$HOME/flutter/bin"' >> ~/.bashrc
fi

if ! grep -q "PUB_HOSTED_URL" ~/.bashrc; then
    echo 'export PUB_HOSTED_URL=https://pub.flutter-io.cn' >> ~/.bashrc
fi

if ! grep -q "FLUTTER_STORAGE_BASE_URL" ~/.bashrc; then
    echo 'export FLUTTER_STORAGE_BASE_URL=https://storage.flutter-io.cn' >> ~/.bashrc
fi

# 立即生效
export PATH="$PATH:$HOME/flutter/bin"
export PUB_HOSTED_URL=https://pub.flutter-io.cn
export FLUTTER_STORAGE_BASE_URL=https://storage.flutter-io.cn

# 6. 验证安装
echo "🔍 验证安装..."
if command -v flutter &> /dev/null; then
    echo "🎉 Flutter安装成功！"
    echo ""
    echo "版本信息:"
    flutter --version
    echo ""
    echo "运行 'flutter doctor' 检查完整环境"
else
    echo "❌ Flutter安装失败"
    echo "请手动检查:"
    echo "1. 确保 ~/flutter/bin 目录存在"
    echo "2. 确保PATH环境变量包含 ~/flutter/bin"
    exit 1
fi

# 7. 预下载依赖
echo ""
echo "📥 预下载Flutter依赖..."
flutter precache

# 8. 检查医小伴项目
echo ""
echo "🏥 检查医小伴Flutter项目..."
if [ -f "mobile/patient_app/pubspec.yaml" ]; then
    echo "✅ 找到医小伴Flutter项目"
    echo "项目位置: $(pwd)/mobile/patient_app"
    echo ""
    echo "下一步:"
    echo "1. cd mobile/patient_app"
    echo "2. flutter pub get  # 安装依赖"
    echo "3. flutter run      # 运行应用"
else
    echo "⚠️  未找到医小伴Flutter项目"
fi

echo ""
echo "📋 安装完成！"
echo "重启终端或运行: source ~/.bashrc"