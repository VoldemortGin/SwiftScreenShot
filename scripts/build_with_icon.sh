#!/bin/bash

# SwiftScreenShot 构建脚本
# 包含图标资源的完整构建流程

set -e  # 遇到错误时退出

echo "======================================"
echo "SwiftScreenShot 构建脚本"
echo "======================================"
echo ""

# 获取脚本所在目录
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

cd "$PROJECT_ROOT"

echo "项目根��录: $PROJECT_ROOT"
echo ""

# 步骤 1: 清理之前的构建
echo "[1/4] 清理之前的构建..."
swift package clean
echo "✓ 清理完成"
echo ""

# 步骤 2: 生成图标（如果需要）
ICON_DIR="$PROJECT_ROOT/Sources/SwiftScreenShot/Resources/Assets.xcassets/AppIcon.appiconset"
if [ ! -f "$ICON_DIR/icon_512x512@2x.png" ]; then
    echo "[2/4] 生成应用图标..."
    "$SCRIPT_DIR/generate_icons.swift"
    echo "✓ 图标生成完成"
else
    echo "[2/4] 跳过图标生成（图标已存在）"
fi
echo ""

# 步骤 3: 构建项目
echo "[3/4] 构建项目..."
swift build -c release
echo "✓ 构建完成"
echo ""

# 步骤 4: 创建应用包（可选）
echo "[4/4] 创建应用包..."

APP_NAME="SwiftScreenShot"
RELEASE_DIR="$PROJECT_ROOT/.build/release"
EXECUTABLE="$RELEASE_DIR/$APP_NAME"
APP_BUNDLE="$PROJECT_ROOT/$APP_NAME.app"

# 清理旧的应用包
if [ -d "$APP_BUNDLE" ]; then
    rm -rf "$APP_BUNDLE"
fi

# 创建应用包结构
mkdir -p "$APP_BUNDLE/Contents/MacOS"
mkdir -p "$APP_BUNDLE/Contents/Resources"

# 复制可执行文件
cp "$EXECUTABLE" "$APP_BUNDLE/Contents/MacOS/$APP_NAME"

# 复制 Info.plist
cp "$PROJECT_ROOT/Sources/SwiftScreenShot/Resources/Info.plist" "$APP_BUNDLE/Contents/Info.plist"

# 处理 Info.plist 中的变量
sed -i '' 's/\$(EXECUTABLE_NAME)/SwiftScreenShot/g' "$APP_BUNDLE/Contents/Info.plist"
sed -i '' 's/\$(PRODUCT_BUNDLE_IDENTIFIER)/com.swiftscreenshot.app/g' "$APP_BUNDLE/Contents/Info.plist"
sed -i '' 's/\$(PRODUCT_NAME)/SwiftScreenShot/g' "$APP_BUNDLE/Contents/Info.plist"
sed -i '' 's/\$(DEVELOPMENT_LANGUAGE)/en/g' "$APP_BUNDLE/Contents/Info.plist"
sed -i '' 's/\$(PRODUCT_BUNDLE_PACKAGE_TYPE)/APPL/g' "$APP_BUNDLE/Contents/Info.plist"
sed -i '' 's/\$(MACOSX_DEPLOYMENT_TARGET)/14.0/g' "$APP_BUNDLE/Contents/Info.plist"

# 复制图标资源
ASSETS_SOURCE="$PROJECT_ROOT/Sources/SwiftScreenShot/Resources/Assets.xcassets"
if [ -d "$ASSETS_SOURCE" ]; then
    cp -r "$ASSETS_SOURCE" "$APP_BUNDLE/Contents/Resources/"

    # 使用 actool 编译 Assets（如果可用）
    if command -v actool &> /dev/null; then
        echo "编译 Assets.xcassets..."
        actool "$ASSETS_SOURCE" \
            --compile "$APP_BUNDLE/Contents/Resources" \
            --platform macosx \
            --minimum-deployment-target 14.0 \
            --app-icon AppIcon \
            --output-partial-info-plist /dev/null \
            2>/dev/null || echo "警告: actool 编译失败，使用原始 xcassets"
    fi
fi

echo "✓ 应用包创建完成: $APP_BUNDLE"
echo ""

echo "======================================"
echo "构建成功！"
echo "======================================"
echo ""
echo "可执行文件位置:"
echo "  Debug:   .build/debug/$APP_NAME"
echo "  Release: .build/release/$APP_NAME"
echo "  App包:   $APP_NAME.app"
echo ""
echo "运行应用:"
echo "  Debug:   .build/debug/$APP_NAME"
echo "  Release: .build/release/$APP_NAME"
echo "  App包:   open $APP_NAME.app"
echo ""
