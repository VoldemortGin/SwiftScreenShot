#!/bin/bash

# Git Hooks 安装脚本
# 将项目中的 hooks 复制到 .git/hooks/ 目录

HOOKS_DIR="hooks"
GIT_HOOKS_DIR=".git/hooks"

echo "🔧 正在安装 Git Hooks..."

# 检查 hooks 目录是否存在
if [ ! -d "$HOOKS_DIR" ]; then
    echo "❌ 错误: $HOOKS_DIR 目录不存在"
    exit 1
fi

# 检查 .git 目录是否存在
if [ ! -d ".git" ]; then
    echo "❌ 错误: 这不是一个 Git 仓库"
    exit 1
fi

# 复制所有 hooks
for hook in "$HOOKS_DIR"/*; do
    hook_name=$(basename "$hook")
    target="$GIT_HOOKS_DIR/$hook_name"

    echo "  → 安装 $hook_name"
    cp "$hook" "$target"
    chmod +x "$target"
done

echo "✅ Git Hooks 安装完成！"
echo ""
echo "📋 已安装的 hooks:"
ls -1 "$HOOKS_DIR"
echo ""
echo "💡 现在当你 push 到 main 分支时，会自动运行测试。"
