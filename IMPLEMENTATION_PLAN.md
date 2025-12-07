# SwiftScreenShot - macOS 快速截图工具实现计划

## 项目概述
一个纯 Swift 实现的 macOS 截图工具，功能和交互类似微信 macOS 版截图工具。

## 用户需求
- **快捷键**: Control+Command+A（与微信相同）
- **应用形式**: 混合模式（菜单栏常驻 + 设置窗口）
- **核心功能**: 区域截图
- **截图处理**: 默认复制到剪贴板，可选保存到指定位置

## 技术栈选择

### 1. 应用架构
- **SwiftUI**: 用于设置界面和现代化 UI
- **AppKit**: 用于菜单栏应用和系统级功能
- **Combine**: 用于响应式数据流管理

### 2. 截图技术方案
**方案A: ScreenCaptureKit (推荐)**
- 优点: 现代化 API，性能好，权限管理清晰
- 缺点: 仅支持 macOS 12.3+
- 适用: 如果目标系统 >= macOS 12.3

**方案B: CGWindowListCreateImage**
- 优点: 兼容性好，支持旧系统
- 缺点: API 较老，需要手动处理屏幕坐标
- 适用: 需要支持 macOS 10.x

**推荐**: 使用 ScreenCaptureKit，设置最低系统要求为 macOS 12.3

### 3. 全局快捷键
**方案A: Carbon Event Manager (传统方式)**
- 使用 `RegisterEventHotKey` API
- 需要桥接 C API

**方案B: NSEvent 全局监听**
- 纯 Swift，但需要辅助功能权限
- 可以监听所有键盘事件

**推荐**: Carbon Event Manager，更可靠且权限要求低

## 核心模块设计

### 模块1: 应用入口 (App.swift)
```
SwiftScreenShotApp
├── MenuBarController - 菜单栏管理
├── HotKeyManager - 快捷键管理
└── SettingsWindow - 设置窗口
```

### 模块2: 快捷键管理 (HotKeyManager.swift)
- 注册全局快捷键 (Ctrl+Cmd+A)
- 监听快捷键事件
- 触发截图流程

### 模块3: 截图引擎 (ScreenshotEngine.swift)
- 获取屏幕内容
- 处理多显示器场景
- 生成截图图像

### 模块4: 选区界面 (SelectionOverlay.swift)
- 全屏透明窗口
- 鼠标拖拽选区
- 实时预览选区
- 显示尺寸信息
- 键盘控制（ESC取消，Enter确认）

### 模块5: 图像处理 (ImageProcessor.swift)
- 裁剪选区图像
- 图像格式转换
- 图像质量优化

### 模块6: 输出管理 (OutputManager.swift)
- 复制到剪贴板（默认）
- 保存到指定目录（可选）
- 文件命名规则（时间戳）

### 模块7: 设置管理 (SettingsManager.swift)
- 保存路径配置
- 是否同时保存文件
- 图像格式选择（PNG/JPG）
- 开机自启动
- UserDefaults 持久化

## 项目结构

```
SwiftScreenShot/
├── SwiftScreenShot/
│   ├── App/
│   │   ├── SwiftScreenShotApp.swift          # 应用入口
│   │   └── AppDelegate.swift                 # 应用委托
│   ├── Core/
│   │   ├── HotKeyManager.swift               # 快捷键管理
│   │   ├── ScreenshotEngine.swift            # 截图引擎
│   │   ├── ImageProcessor.swift              # 图像处理
│   │   └── OutputManager.swift               # 输出管理
│   ├── UI/
│   │   ├── MenuBar/
│   │   │   └── MenuBarController.swift       # 菜单栏控制器
│   │   ├── Selection/
│   │   │   ├── SelectionWindow.swift         # 选区窗口
│   │   │   ├── SelectionView.swift           # 选区视图
│   │   │   └── SelectionOverlayView.swift    # 覆盖层视图
│   │   └── Settings/
│   │       ├── SettingsView.swift            # 设置主视图
│   │       └── SettingsWindow.swift          # 设置窗口
│   ├── Models/
│   │   ├── ScreenshotSettings.swift          # 设置数据模型
│   │   └── SelectionRegion.swift             # 选区数据模型
│   ├── Utilities/
│   │   ├── PermissionManager.swift           # 权限管理
│   │   └── Extensions.swift                  # Swift 扩展
│   └── Resources/
│       ├── Assets.xcassets                   # 图像资源
│       └── Info.plist                        # 应用配置
├── SwiftScreenShot.xcodeproj
└── README.md
```

## 实现步骤

### 第一阶段：项目基础搭建
1. **创建 Xcode 项目**
   - 创建 macOS App 项目
   - 配置为菜单栏应用（LSUIElement = YES）
   - 设置最低系统版本为 macOS 12.3

2. **配置权限**
   - 屏幕录制权限（Screen Recording）
   - 添加权限说明文案

3. **创建基础目录结构**
   - 按上述结构创建文件夹
   - 创建空白文件占位

### 第二阶段：核心功能实现
4. **实现菜单栏应用**
   - 创建状态栏图标
   - 实现菜单项（截图、设置、退出）
   - 隐藏 Dock 图标

5. **实现全局快捷键**
   - 封装 Carbon Event Manager API
   - 注册 Ctrl+Cmd+A 快捷键
   - 实现快捷键回调

6. **实现截图引擎**
   - 使用 ScreenCaptureKit 获取屏幕内容
   - 处理多显示器场景
   - 生成高质量截图

7. **实现选区界面**
   - 创建全屏透明窗口
   - 实现鼠标拖拽选区
   - 绘制选区框和遮罩
   - 显示实时尺寸
   - 处理键盘事件（ESC/Enter）

### 第三阶段：输出功能
8. **实现剪贴板功能**
   - 将图像复制到 NSPasteboard
   - 支持多种图像格式

9. **实现文件保存**
   - 根据设置保存到指定目录
   - 文件命名：Screenshot_YYYYMMDD_HHMMSS.png
   - 支持 PNG/JPG 格式

### 第四阶段：设置界面
10. **实现设置窗口**
    - 使用 SwiftUI 创建设置界面
    - 保存路径选择（FileManager）
    - 图像格式选择
    - 开机自启动配置
    - 数据持久化（UserDefaults）

### 第五阶段：优化与测试
11. **性能优化**
    - 优化截图速度
    - 减少内存占用
    - 异步处理图像

12. **用户体验优化**
    - 添加音效反馈
    - 优化选区拖拽手感
    - 添加快捷键冲突检测

13. **测试**
    - 单显示器测试
    - 多显示器测试
    - 不同分辨率测试
    - 内存泄漏检测

## 技术难点与解决方案

### 难点1: 全屏透明窗口实现
**问题**: 需要在所有窗口之上显示透明选区界面

**解决方案**:
```swift
let window = NSWindow(
    contentRect: screenFrame,
    styleMask: [.borderless],
    backing: .buffered,
    defer: false
)
window.level = .screenSaver
window.backgroundColor = .clear
window.isOpaque = false
window.hasShadow = false
window.ignoresMouseEvents = false
window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
```

### 难点2: 多显示器坐标系统
**问题**: macOS 多显示器坐标系统复杂，原点在主显示器左下角

**解决方案**:
- 使用 `NSScreen.screens` 获取所有显示器
- 计算每个显示器的实际坐标
- 选区坐标转换到屏幕坐标系

### 难点3: 全局快捷键注册
**问题**: Swift 无法直接使用 Carbon API

**解决方案**:
- 创建 Bridging Header
- 封装 C API 为 Swift 友好的接口
- 使用 EventHotKey 处理回调

### 难点4: 屏幕录制权限
**问题**: macOS 12+ 需要用户授权屏幕录制

**解决方案**:
```swift
// 检查权限
CGRequestScreenCaptureAccess()

// 在 Info.plist 添加说明
NSScreenCaptureUsageDescription = "需要屏幕录制权限来实现截图功能"
```

### 难点5: 高 DPI 屏幕处理
**问题**: Retina 屏幕的实际像素是逻辑像素的 2 倍

**解决方案**:
- 使用 `backingScaleFactor` 获取缩放比例
- 正确处理点（point）和像素（pixel）的转换

## 依赖项
- 无第三方依赖
- 仅使用 Apple 原生框架：
  - AppKit
  - SwiftUI
  - ScreenCaptureKit
  - Carbon (通过桥接)

## 开发环境要求
- Xcode 14.0+
- macOS 12.3+ (开发机器)
- Swift 5.7+

## 最终交付物
1. 可运行的 .app 应用
2. 源代码（纯 Swift）
3. README 使用说明
4. 打包脚本（可选）

## 后续扩展功能（可选）
- [ ] 窗口截图（自动识别窗口边界）
- [ ] 全屏截图
- [ ] 延时截图
- [ ] 编辑工具（箭头、文字、马赛克）
- [ ] 滚动截图
- [ ] OCR 文字识别
- [ ] 钉图功能
- [ ] 历史记录
- [ ] 快捷分享到各种平台

## 预估工作量
- 第一阶段：2-3 小时
- 第二阶段：8-10 小时
- 第三阶段：3-4 小时
- 第四阶段：4-5 小时
- 第五阶段：4-5 小时

**总计**: 21-27 小时（纯开发时间）

## 风险评估
1. **权限问题**: 用户可能拒绝屏幕录制权限 - 提供清晰的引导说明
2. **快捷键冲突**: 与其他应用快捷键冲突 - 允许自定义快捷键
3. **多显示器兼容性**: 不同配置可能有问题 - 充分测试
4. **系统版本兼容**: ScreenCaptureKit 需要 macOS 12.3+ - 明确最低系统要求

## 总结
这是一个技术上可行的项目，纯 Swift 实现无障碍。核心挑战在于全局快捷键和选区界面的用户体验优化。建议采用迭代开发，先实现核心截图功能，再逐步完善设置和优化体验。
