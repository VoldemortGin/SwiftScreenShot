#!/bin/bash

# 预览应用图标的脚本
# 使用 macOS Quick Look 快速查看生成的图标

set -e

# 获取脚本所在目录
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

ICON_DIR="$PROJECT_ROOT/Sources/SwiftScreenShot/Resources/Assets.xcassets/AppIcon.appiconset"

echo "======================================"
echo "SwiftScreenShot 图标预览"
echo "======================================"
echo ""

# 检查图标是否存在
if [ ! -d "$ICON_DIR" ]; then
    echo "错误: 图标目录不存在: $ICON_DIR"
    echo "请先运行 generate_icons.swift 生成图标"
    exit 1
fi

# 检查是否有图标文件
if [ ! -f "$ICON_DIR/icon_512x512.png" ]; then
    echo "错误: 图标文件不存在"
    echo "请先运行 generate_icons.swift 生成图标"
    exit 1
fi

echo "图标位置: $ICON_DIR"
echo ""

# 显示所有图标文件信息
echo "可用的图标尺寸:"
echo "----------------------------------------"
for icon in "$ICON_DIR"/*.png; do
    if [ -f "$icon" ]; then
        filename=$(basename "$icon")
        size=$(file "$icon" | grep -o '[0-9]* x [0-9]*' || echo "unknown")
        filesize=$(ls -lh "$icon" | awk '{print $5}')
        echo "  $filename"
        echo "    尺寸: $size"
        echo "    大小: $filesize"
        echo ""
    fi
done

echo "----------------------------------------"
echo ""

# 选择要预览的图标尺寸
echo "请选择要预览的图标尺寸:"
echo "  1) 16x16"
echo "  2) 32x32"
echo "  3) 64x64"
echo "  4) 128x128"
echo "  5) 256x256"
echo "  6) 512x512"
echo "  7) 1024x1024"
echo "  8) 所有尺寸"
echo "  9) 最大尺寸 (1024x1024)"
echo ""
read -p "请输入选项 (1-9，默认 9): " choice

case $choice in
    1)
        qlmanage -p "$ICON_DIR/icon_16x16.png" > /dev/null 2>&1
        ;;
    2)
        qlmanage -p "$ICON_DIR/icon_32x32.png" > /dev/null 2>&1
        ;;
    3)
        qlmanage -p "$ICON_DIR/icon_32x32@2x.png" > /dev/null 2>&1
        ;;
    4)
        qlmanage -p "$ICON_DIR/icon_128x128.png" > /dev/null 2>&1
        ;;
    5)
        qlmanage -p "$ICON_DIR/icon_256x256.png" > /dev/null 2>&1
        ;;
    6)
        qlmanage -p "$ICON_DIR/icon_512x512.png" > /dev/null 2>&1
        ;;
    7|9|"")
        qlmanage -p "$ICON_DIR/icon_512x512@2x.png" > /dev/null 2>&1
        ;;
    8)
        qlmanage -p "$ICON_DIR"/*.png > /dev/null 2>&1
        ;;
    *)
        echo "无效选项，显示最大尺寸"
        qlmanage -p "$ICON_DIR/icon_512x512@2x.png" > /dev/null 2>&1
        ;;
esac

echo ""
echo "预览完成！"
