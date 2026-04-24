#!/bin/bash

echo "🔍 检查Flutter开发环境"
echo "======================"

# 检查Flutter是否安装
echo "1. 检查Flutter安装..."
if command -v flutter &> /dev/null; then
    echo "   ✅ Flutter已安装"
    flutter --version
else
    echo "   ❌ Flutter未安装"
    echo "   建议安装方法:"
    echo "   - 方法1: snap install flutter --classic"
    echo "   - 方法2: 手动下载 https://flutter.dev/docs/get-started/install/linux"
fi

echo ""
echo "2. 检查Dart SDK..."
if command -v dart &> /dev/null; then
    echo "   ✅ Dart SDK已安装"
    dart --version
else
    echo "   ⚠️  Dart SDK未单独安装 (Flutter自带Dart)"
fi

echo ""
echo "3. 检查Flutter项目依赖..."
if [ -f "mobile/patient_app/pubspec.yaml" ]; then
    echo "   ✅ 找到Flutter项目: mobile/patient_app/"
    echo "   项目名称: $(grep 'name:' mobile/patient_app/pubspec.yaml | head -1 | cut -d':' -f2 | xargs)"
    echo "   Flutter版本: $(grep 'sdk:' mobile/patient_app/pubspec.yaml | head -1 | cut -d':' -f2 | xargs)"
else
    echo "   ❌ 未找到Flutter项目文件"
fi

echo ""
echo "4. 检查Android开发环境..."
if command -v adb &> /dev/null; then
    echo "   ✅ ADB已安装"
    adb --version | head -1
else
    echo "   ⚠️  ADB未安装 (Android调试桥)"
fi

if [ -d "$HOME/Android" ] || [ -d "$HOME/android-sdk" ]; then
    echo "   ✅ Android SDK目录存在"
else
    echo "   ⚠️  Android SDK目录未找到"
fi

echo ""
echo "5. 检查系统依赖..."
echo "   - Git: $(which git 2>/dev/null && echo '✅ 已安装' || echo '❌ 未安装')"
echo "   - Curl: $(which curl 2>/dev/null && echo '✅ 已安装' || echo '❌ 未安装')"
echo "   - Unzip: $(which unzip 2>/dev/null && echo '✅ 已安装' || echo '❌ 未安装')"

echo ""
echo "6. 检查网络连接 (中国区镜像)..."
if ping -c 1 -W 2 storage.flutter-io.cn &> /dev/null; then
    echo "   ✅ 可以访问Flutter中国镜像"
else
    echo "   ⚠️  无法访问Flutter中国镜像"
fi

if ping -c 1 -W 2 pub.flutter-io.cn &> /dev/null; then
    echo "   ✅ 可以访问Pub中国镜像"
else
    echo "   ⚠️  无法访问Pub中国镜像"
fi

echo ""
echo "7. 环境变量检查..."
echo "   - PATH中的Flutter: $(echo $PATH | grep -o 'flutter' | head -1 && echo '✅' || echo '❌')"
echo "   - PUB_HOSTED_URL: ${PUB_HOSTED_URL:-未设置}"
echo "   - FLUTTER_STORAGE_BASE_URL: ${FLUTTER_STORAGE_BASE_URL:-未设置}"

echo ""
echo "📋 建议:"
if command -v flutter &> /dev/null; then
    echo "1. 运行 'flutter doctor' 检查完整环境"
    echo "2. 运行 'flutter pub get' 安装项目依赖"
    echo "3. 运行 'flutter run' 启动应用"
else
    echo "1. 安装Flutter SDK"
    echo "2. 配置环境变量"
    echo "3. 运行 'flutter doctor' 检查环境"
fi

echo ""
echo "🚀 快速开始命令:"
echo "cd /root/.openclaw/workspace/yixiaoban_app/mobile/patient_app"
echo "flutter pub get"
echo "flutter run"