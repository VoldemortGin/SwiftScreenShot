# SwiftScreenShot

一个纯 Swift 实现的 macOS 截图工具，功能和交互类似微信 macOS 版截图工具。

## 功能特性

- ⌨️ **全局快捷键**: Control+Command+A 快速触发截图
- 🖱️ **区域选择**: 鼠标拖拽选择截图区域
- 📋 **剪贴板**: 自动复制截图到剪贴板
- 💾 **文件保存**: 可选保存到指定目录
- 🎨 **多格式支持**: PNG 和 JPEG 格式
- 📐 **实时尺寸**: 显示选区实时尺寸
- 🚀 **开机启动**: 支持开机自动启动
- 🎯 **菜单栏应用**: 轻量级菜单栏常驻

## 系统要求

- **运行**: macOS 14.0 或更高版本
- **编译**: Xcode 15.0 或更高版本 + Swift 5.9+

## 快速开始

### 方法一：使用 Makefile（推荐）

```bash
# 克隆或下载项目
cd SwiftScreenShot

# 构建并运行
make run
```

就这么简单！详细说明请查看 [QUICKSTART.md](QUICKSTART.md)

### 方法二：使用 Swift Package Manager

```bash
swift build         # 构建
swift run           # 运行
```

### 方法三：使用 Xcode

### 使用 Xcode 创建项目

由于项目文件已经创建完成，你需要在 Xcode 中创建一个新的 macOS App 项目，然后按照以下步骤配置：

1. **创建新项目**
   - 打开 Xcode
   - File > New > Project
   - 选择 macOS > App
   - Product Name: `SwiftScreenShot`
   - Interface: `SwiftUI`
   - Language: `Swift`

2. **导入源文件**
   - 删除 Xcode 自动生成的 ContentView.swift
   - 将 `SwiftScreenShot` 目录下的所有文件夹（App/, Core/, UI/, Models/, Utilities/, Resources/）拖入 Xcode 项目

3. **配置项目设置**

   在 Xcode 项目设置中：

   **General 选项卡**:
   - Deployment Target: macOS 12.3

   **Signing & Capabilities 选项卡**:
   - 添加 Team（需要 Apple Developer 账号）
   - 勾选 "Automatically manage signing"

   **Build Settings 选项卡**:
   - 搜索 "Bridging Header"
   - 设置 Objective-C Bridging Header 为: `SwiftScreenShot/Resources/SwiftScreenShot-Bridging-Header.h`

   **Info 选项卡**:
   - Application is agent (UIElement): YES
   - 或者在 Info.plist 中添加 `LSUIElement` = `YES`

4. **添加 Framework**

   在 Xcode 项目设置的 "Frameworks, Libraries, and Embedded Content" 中添加：
   - `ScreenCaptureKit.framework`
   - `Carbon.framework`
   - `UserNotifications.framework`

5. **运行项目**
   - 按 Cmd+R 运行
   - 首次运行会提示授予屏幕录制权限
   - 授权后重启应用即可使用

## 使用说明

### 快捷键

- **截图**: Control+Command+A
- **取消**: ESC
- **确认**: Enter（当选择区域后）

### 菜单栏

点击菜单栏图标可以访问：
- 截图 - 手动触发截图
- 设置 - 打开设置窗口
- 退出 - 退出应用

### 设置

在设置窗口中，你可以配置：
- 是否同时保存文件到磁盘
- 保存路径选择
- 图像格式（PNG/JPEG）
- 开机自动启动

## 项目结构

```
SwiftScreenShot/
├── App/
│   ├── SwiftScreenShotApp.swift       # 应用入口
│   └── AppDelegate.swift              # 应用委托
├── Core/
│   ├── HotKeyManager.swift            # 快捷键管理
│   ├── ScreenshotEngine.swift         # 截图引擎
│   ├── ImageProcessor.swift           # 图像处理
│   └── OutputManager.swift            # 输出管理
├── UI/
│   ├── MenuBar/
│   │   └── MenuBarController.swift    # 菜单栏控制器
│   ├── Selection/
│   │   ├── SelectionWindow.swift      # 选区窗口
│   │   └── SelectionView.swift        # 选区视图
│   └── Settings/
│       ├── SettingsView.swift         # 设置视图
│       └── SettingsWindow.swift       # 设置窗口
├── Models/
│   ├── ImageFormat.swift              # 图像格式
│   ├── ScreenshotSettings.swift       # 设置模型
│   └── SelectionRegion.swift          # 选区模型
├── Utilities/
│   ├── PermissionManager.swift        # 权限管理
│   └── Extensions.swift               # 扩展工具
└── Resources/
    ├── Info.plist                     # 应用配置
    └── SwiftScreenShot-Bridging-Header.h  # 桥接头文件
```

## 技术栈

- **SwiftUI**: 设置界面
- **AppKit**: 菜单栏和选区界面
- **ScreenCaptureKit**: 截图引擎
- **Carbon Event Manager**: 全局快捷键
- **UserDefaults**: 设置持久化

## 架构设计

项目采用分层模块化架构：

- **App 层**: 应用生命周期管理
- **Core 层**: 核心业务逻辑
- **UI 层**: 用户界面组件
- **Models 层**: 数据模型
- **Utilities 层**: 工具函数

详细的架构决策请参考 `ARCHITECTURE_DECISIONS.md`

## 常见问题

### 1. 权限问题

如果截图功能无法使用，请检查：
- 系统设置 > 隐私与安全性 > 屏幕录制
- 确保 SwiftScreenShot 已被授权
- 授权后需要重启应用

### 2. 快捷键冲突

如果快捷键不生效，可能与其他应用冲突：
- 检查其他应用是否占用了 Control+Command+A
- 可以通过菜单栏手动触发截图

### 3. 多显示器支持

应用会自动检测鼠标所在的显示器并在该显示器上显示选区界面。

## 开发计划

- [ ] 自定义快捷键
- [ ] 窗口截图
- [ ] 全屏截图
- [ ] 延时截图
- [ ] 编辑工具（箭头、文字、马赛克）
- [ ] 历史记录
- [ ] OCR 文字识别

## 许可证

MIT License

## 贡献

欢迎提交 Issue 和 Pull Request！

## 致谢

本项目参考了微信 macOS 版截图工具的交互设计。
# SwiftScreenShot
