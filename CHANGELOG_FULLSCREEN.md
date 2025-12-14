# Changelog - 全屏截图功能

## [Unreleased] - 2025-12-14

### 新增 (Added)

#### 核心功能
- **全屏截图模式**: 支持无需区域选择的一键截图
- **多显示器支持**:
  - 主显示器模式：仅捕获主屏幕
  - 当前屏幕模式：捕获鼠标所在屏幕（默认）
  - 所有屏幕模式：捕获并拼接所有显示器
- **屏幕拼接算法**: 自动计算多显示器的相对位置并正确拼接
- **独立快捷键**: `⇧⌘3` 触发全屏截图

#### 用户界面
- 菜单栏新增"全屏截图 (⇧⌘3)"选项
- 设置界面新增"全屏截图设置"部分：
  - 分段控件选择捕获模式
  - 详细的模式说明文字
- 快捷键说明区域更新，列出所有快捷键

#### 数据模型
- 新增 `ScreenshotMode` 枚举：
  - `region`: 区域选择模式
  - `fullScreen`: 全屏截图模式
  - `allScreens`: 所有屏幕模式
- 新增 `FullScreenCaptureMode` 枚举：
  - `mainDisplay`: 主显示器
  - `currentScreen`: 当前屏幕
  - `allDisplays`: 所有显示器
  - 每个模式包含本地化显示名称

### 修改 (Changed)

#### 架构重构
- **HotKeyManager 重构**:
  - 从单热键管理升级为多热键管理
  - 引入 `HotKey` 结构体封装热键信息
  - 支持每个热键独立的回调函数
  - 添加 `register(key:modifiers:action:)` 方法返回热键 ID
  - 添加 `unregister(id:)` 和 `unregisterAll()` 方法

#### 功能增强
- **ScreenshotEngine 扩展**:
  - 重构 `captureMainDisplay()` 使用新的 `captureFullDisplay()` 方法
  - 新增 `captureFullDisplay(display:)` - 捕获指定显示器
  - 新增 `captureCurrentDisplay()` - 捕获鼠标所在屏幕
  - 新增 `captureAllDisplays()` - 捕获并拼接所有显示器

- **AppDelegate 更新**:
  - 注册两个全局热键（区域截图和全屏截图）
  - 新增 `handleTriggerFullScreenshot()` 处理全屏截图请求
  - 新增 `captureFullScreen()` 实现全屏截图逻辑
  - 根据用户设置选择相应的捕获模式
  - 更新 `applicationWillTerminate()` 调用 `unregisterAll()`

- **ScreenshotSettings 扩展**:
  - 新增 `fullScreenCaptureMode` 属性
  - 自动持久化到 UserDefaults
  - 默认值设为 `.currentScreen`

- **MenuBarController 更新**:
  - 菜单项"截图"重命名为"区域截图 (⌃⌘A)"
  - 新增"全屏截图 (⇧⌘3)"菜单项
  - 更新相应的 action 方法

- **SettingsView 增强**:
  - 窗口尺寸从 500x400 调整为 550x500
  - 快捷键说明更新，区分区域截图和全屏截图
  - 新增全屏截图设置部分

- **Extensions 更新**:
  - 新增 `.triggerFullScreenshot` 通知名称

### 测试 (Tests)
- 新增 `ScreenshotModeTests.swift`:
  - 测试 `FullScreenCaptureMode` 的原始值
  - 测试显示名称的本地化
  - 测试从原始值初始化
  - 测试设置的默认值
  - 测试设置的持久化功能

### 文档 (Documentation)
- 新增 `FULLSCREEN_FEATURE.md` - 详细的功能说明文档
- 新增 `FULLSCREEN_QUICKSTART.md` - 快速入门指南
- 新增 `CHANGELOG_FULLSCREEN.md` - 本变更日志

## 技术细节

### 文件统计
- **新增文件**: 5 个
  - 1 个核心模型文件
  - 1 个测试文件
  - 3 个文档文件

- **修改文件**: 7 个核心 Swift 文件
  - AppDelegate.swift
  - HotKeyManager.swift
  - ScreenshotEngine.swift
  - ScreenshotSettings.swift
  - MenuBarController.swift
  - SettingsView.swift
  - Extensions.swift

### 代码质量
- ✅ 所有测试通过 (34/34)
- ✅ 构建成功，无错误
- ⚠️  1 个 Sendable 警告（不影响功能）
- ✅ 代码风格统一
- ✅ 完整的注释和文档

### 兼容性
- 最低系统版本：macOS 14.0
- 架构支持：Apple Silicon & Intel
- Swift 版本：5.9+

## 破坏性变更 (Breaking Changes)
无。此次更新完全向后兼容，不影响现有功能。

## 迁移指南 (Migration Guide)
无需迁移。现有用户可直接使用新功能，原有的区域截图功能保持不变。

## 已知问题 (Known Issues)
- 多显示器拼接时，显示器索引可能与物理位置不完全对应
- 部分情况下 NSScreen 和 SCDisplay 的映射可能不准确

## 未来计划 (Future Plans)
1. 支持自定义全屏截图快捷键
2. 添加延迟截图功能（倒计时）
3. 支持窗口截图模式
4. 优化多显示器的屏幕匹配逻辑
5. 添加截图预览和编辑功能

## 鸣谢 (Acknowledgments)
感谢所有测试和提供反馈的用户。

---

**完整功能列表**:
- ✅ 区域截图（原有）
- ✅ 全屏截图（新增）
- ✅ 主显示器捕获（新增）
- ✅ 当前屏幕捕获（新增）
- ✅ 多屏幕拼接（新增）
- ✅ 双热键支持（新增）
- ✅ 设置持久化（新增）
- ✅ 剪贴板复制（原有）
- ✅ 文件保存（原有）
- ✅ 音效反馈（原有）
- ✅ 自定义保存路径（原有）
- ✅ 图片格式选择（原有）
