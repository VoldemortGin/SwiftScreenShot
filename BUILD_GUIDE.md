# SwiftScreenShot 构建指南

本指南将帮助你在 Xcode 中设置和构建 SwiftScreenShot 项目。

## 前置要求

- macOS 12.3 或更高版本
- Xcode 14.0 或更高版本
- Apple Developer 账号（用于代码签名）

## 步骤 1: 创建 Xcode 项目

1. 打开 Xcode
2. 选择 **File > New > Project**
3. 在模板选择器中：
   - 选择 **macOS** 标签
   - 选择 **App**
   - 点击 **Next**

4. 配置项目：
   - **Product Name**: `SwiftScreenShot`
   - **Team**: 选择你的开发团队
   - **Organization Identifier**: 例如 `com.yourname`
   - **Bundle Identifier**: 会自动生成为 `com.yourname.SwiftScreenShot`
   - **Interface**: `SwiftUI`
   - **Language**: `Swift`
   - 不勾选 "Use Core Data"
   - 不勾选 "Include Tests"
   - 点击 **Next**

5. 选择保存位置：
   - 选择当前项目所在的父目录 `/Users/linhan/startup/`
   - 点击 **Create**

## 步骤 2: 替换源文件

1. 在 Xcode 项目导航器中，删除自动生成的文件：
   - `ContentView.swift`
   - `SwiftScreenShotApp.swift`（我们会用自己的替换）

2. 在 Finder 中，将 `SwiftScreenShot` 目录下的所有文件夹拖入 Xcode 项目：
   - `App/`
   - `Core/`
   - `UI/`
   - `Models/`
   - `Utilities/`
   - `Resources/`

3. 在拖入对话框中：
   - 勾选 "Copy items if needed"
   - 选择 "Create groups"
   - 在 "Add to targets" 中勾选 `SwiftScreenShot`
   - 点击 **Finish**

## 步骤 3: 配置项目设置

### 3.1 General 设置

1. 在项目导航器中选择项目根节点
2. 选择 **TARGETS** 下的 `SwiftScreenShot`
3. 在 **General** 选项卡中：
   - **Deployment Info > Minimum Deployments**: 选择 `macOS 12.3`
   - **App Category**: 选择 `Productivity`

### 3.2 Signing & Capabilities 设置

1. 在 **Signing & Capabilities** 选项卡中：
   - 勾选 **Automatically manage signing**
   - 选择你的 **Team**

2. 点击 **+ Capability** 添加以下能力：
   - **App Sandbox** (可选，用于发布到 App Store)

### 3.3 Build Settings 设置

1. 在 **Build Settings** 选项卡中：
   - 搜索 "Bridging Header"
   - 双击 **Objective-C Bridging Header**
   - 输入: `SwiftScreenShot/Resources/SwiftScreenShot-Bridging-Header.h`

2. 搜索 "Swift Language Version"
   - 确保设置为 **Swift 5**

### 3.4 Info.plist 设置

1. 选择 `Resources/Info.plist`
2. 确保包含以下键值对：
   - **Application is agent (UIElement)**: `YES`
   - **Privacy - Screen Recording Usage Description**: `SwiftScreenShot 需要屏幕录制权限来实现截图功能。`

或者在 Info 选项卡中：
   - 添加 `LSUIElement` = `YES` (Boolean 类型)
   - 添加 `NSScreenCaptureUsageDescription` = `SwiftScreenShot 需要屏幕录制权限来实现截图功能。`

### 3.5 Frameworks 设置

1. 在 **General** 选项卡中，找到 **Frameworks, Libraries, and Embedded Content**
2. 点击 **+** 按钮，添加以下系统框架：
   - `ScreenCaptureKit.framework`
   - `Carbon.framework` (可能需要在 "Add Other" > "Add Files" 中手动添加)
   - `UserNotifications.framework`

注意：Carbon.framework 在新版 Xcode 中可能需要：
   - 点击 **+** > **Add Other** > **Add Files**
   - 导航到 `/System/Library/Frameworks/Carbon.framework`
   - 选择并添加

## 步骤 4: 构建和运行

1. 选择运行目标为 **My Mac**
2. 按 **Cmd+B** 构建项目
3. 如果有编译错误，检查：
   - Bridging Header 路径是否正确
   - 所有框架是否正确添加
   - Swift 版本是否正确

4. 按 **Cmd+R** 运行项目
5. 首次运行时：
   - 应用会出现在菜单栏（右上角相机图标）
   - 系统会提示授予屏幕录制权限
   - 在"系统设置 > 隐私与安全性 > 屏幕录制"中勾选 SwiftScreenShot
   - 重启应用

## 步骤 5: 测试功能

1. 按 **Control+Command+A** 触发截图
2. 屏幕应该显示半透明遮罩
3. 鼠标拖拽选择区域
4. 释放鼠标完成截图
5. 检查剪贴板是否有截图

## 常见问题解决

### 问题 1: 编译错误 "Use of undeclared type 'EventHotKeyRef'"

**解决方案**:
- 检查 Bridging Header 路径是否正确设置
- 确保 Carbon.framework 已正确添加

### 问题 2: 运行时闪退

**解决方案**:
- 检查是否授予了屏幕录制权限
- 在控制台查看崩溃日志
- 确保 Info.plist 中的 `LSUIElement` 设置为 `YES`

### 问题 3: 快捷键不生效

**解决方案**:
- 检查是否有其他应用占用了相同的快捷键
- 通过菜单栏图标手动触发截图测试其他功能

### 问题 4: "The app is damaged and can't be opened"

**解决方案**:
- 这是代码签名问题
- 确保在 Signing & Capabilities 中正确配置了团队
- 如果是自签名，可能需要在系统设置中允许该应用

## 调试技巧

1. **查看控制台日志**:
   - 在 Xcode 中按 **Cmd+Shift+Y** 打开控制台
   - 查看应用的 print 输出

2. **断点调试**:
   - 在关键函数设置断点
   - 例如：`handleTriggerScreenshot()`, `captureRegion()`

3. **权限检查**:
   - 在 `applicationDidFinishLaunching` 中添加日志
   - 确认权限状态

## 发布准备

如果要发布应用：

1. **创建 Release 构建**:
   - Product > Scheme > Edit Scheme
   - 设置 Run 配置为 Release

2. **归档应用**:
   - Product > Archive
   - 在 Organizer 中导出应用

3. **公证 (Notarization)**:
   - 如果要分发给其他用户，需要通过 Apple 公证
   - 使用 `xcrun notarytool` 或 Xcode Organizer

## 下一步

- 测试所有功能
- 根据需求自定义设置
- 添加自定义图标（替换 SF Symbol）
- 实现扩展功能（参考 README.md 中的开发计划）

## 需要帮助？

如果遇到问题：
1. 查看 `README.md` 的常见问题部分
2. 检查 `ARCHITECTURE_DECISIONS.md` 了解技术细节
3. 查看控制台日志获取错误信息
