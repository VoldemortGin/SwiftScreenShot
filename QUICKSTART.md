# 快速开始指南

## 一键构建和运行

```bash
make run
```

就这么简单！

## 详细步骤

### 1. 构建项目

```bash
# 调试模式构建
make build

# 或者发布模式构建（优化）
make release
```

### 2. 运行应用

```bash
# 构建并运行
make run
```

### 3. 授予权限

首次运行时，系统会提示授予**屏幕录制权限**：

1. 打开 **系统设置**
2. 进入 **隐私与安全性** > **屏幕录制**
3. 勾选 **SwiftScreenShot**
4. 重启应用

### 4. 使用截图

- 按 **Control+Command+A** 触发截图
- 鼠标拖拽选择区域
- 释放鼠标，截图自动复制到剪贴板
- 按 **ESC** 取消，按 **Enter** 确认当前选区

## Makefile 命令

```bash
make build      # 构建项目（调试模式）
make run        # 构建并运行
make release    # 发布模式构建（优化）
make clean      # 清理构建产物
make rebuild    # 清理并重新构建
make install    # 安装到 /usr/local/bin
make uninstall  # 卸载
make help       # 显示帮助
```

## 系统要求

- macOS 14.0 或更高版本
- Xcode 15.0 或更高版本（用于编译）
- 约 1GB 磁盘空间（用于编译缓存）

## 项目结构

```
.
├── Makefile              # 构建脚本
├── Package.swift         # Swift Package Manager 配置
├── Sources/              # 源代码
│   └── SwiftScreenShot/
│       ├── App/         # 应用入口
│       ├── Core/        # 核心功能
│       ├── UI/          # 用户界面
│       ├── Models/      # 数据模型
│       └── Utilities/   # 工具函数
└── .build/              # 构建产物（自动生成）
    ├── debug/           # 调试版本
    └── release/         # 发布版本
```

## 常见问题

### Q: 编译失败怎么办？

A: 尝试清理并重新构建：
```bash
make clean
make build
```

### Q: 如何查看详细的构建日志？

A: 直接使用 swift build：
```bash
swift build -v
```

### Q: 如何安装到系统？

A: 使用 install 命令：
```bash
make install
```

然后可以直接在终端运行：
```bash
SwiftScreenShot
```

### Q: 如何打包分发？

A: 构建发布版本：
```bash
make release
```

二进制文件位于：`.build/release/SwiftScreenShot`

### Q: 权限问题怎么解决？

A: 如果遇到权限问题：
1. 打开 **系统设置** > **隐私与安全性** > **屏幕录制**
2. 勾选 SwiftScreenShot
3. 重启应用

## 开发相关

### 修改代码后重新构建

```bash
make rebuild
```

### 查看构建产物

```bash
# 调试版本
.build/debug/SwiftScreenShot

# 发布版本（需要先 make release）
.build/release/SwiftScreenShot
```

### 清理所有构建产物

```bash
make clean
```

## 下一步

- 查看 [README.md](README.md) 了解完整功能
- 查看 [BUILD_GUIDE.md](BUILD_GUIDE.md) 了解 Xcode 构建方法
- 查看 [ARCHITECTURE_DECISIONS.md](ARCHITECTURE_DECISIONS.md) 了解技术架构

## 需要帮助？

如果遇到任何问题，请查看：
- [README.md](README.md) - 完整文档
- [PROJECT_SUMMARY.md](PROJECT_SUMMARY.md) - 项目总结
- GitHub Issues - 报告问题
