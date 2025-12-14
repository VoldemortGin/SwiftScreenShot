# 日志系统实施总结

## 实施概述

为 SwiftScreenShot 应用实现了完整的结构化日志系统，替换了所有的 `print` 语句，并添加了日志级别控制、文件导出等功能。

## 实施内容

### 1. 核心组件

#### AppLogger.swift
**文件路径**: `Sources/SwiftScreenShot/Utilities/AppLogger.swift`

**主要功能**:
- 基于 `os.Logger` 的结构化日志系统
- 支持 5 个日志级别：Debug, Info, Warning, Error, Fault
- 12 个日志分类：screenshot, hotkey, settings, editor, history, window, permission, output, sound, annotation, delay, app
- 文件日志功能（可选）
- 日志导出和清理功能
- 自动日志级别过滤
- 异步文件写入（不影响性能）

**关键特性**:
```swift
// 使用示例
AppLogger.shared.info("Screenshot completed", category: .screenshot)
AppLogger.shared.error("Failed to save file", category: .output, error: error)
AppLogger.shared.debug("Processing windows: \(count)", category: .window)
```

### 2. 设置集成

#### ScreenshotSettings.swift
**修改内容**:
- 添加 `logLevel: LogLevel` 属性
- 添加 `fileLoggingEnabled: Bool` 属性
- 在初始化时设置默认值（Debug 模式：debug，Release 模式：info）
- 替换 print 语句为结构化日志

#### SettingsView.swift
**新增功能**:
- 日志设置界面（新增一个 Section）
- 日志级别选择器（Picker）
- 文件日志开关（Toggle）
- 日志导出按钮
- 详细的说明文字
- 日志文件路径显示
- 窗口高度调整（550x780 -> 550x900）

### 3. 日志迁移

替换了以下文件中的所有 `print` 语句：

#### AppDelegate.swift (10 处)
- ✅ 应用启动/终止日志
- ✅ 通知权限请求结果
- ✅ 屏幕录制权限状态
- ✅ 热键变更通知
- ✅ 截图流程（开始、完成、失败）
- ✅ 各种截图模式的日志
- ✅ 错误处理和权限检查

#### HotKeyManager.swift (3 处)
- ✅ 热键注册成功/失败
- ✅ 热键注销

#### OutputManager.swift (5 处)
- ✅ 截图输出处理流程
- ✅ 剪贴板操作
- ✅ 文件保存成功/失败
- ✅ 通知显示

#### SoundManager.swift (3 处)
- ✅ 音效播放
- ✅ 音效文件不可用警告
- ✅ 系统音效播放失败

#### ScreenshotHistory.swift (5 处)
- ✅ 历史记录保存失败
- ✅ 缩略图保存失败
- ✅ 图片保存错误
- ✅ 历史加载成功/失败
- ✅ 索引保存

#### WindowDetector.swift (3 处)
- ✅ 窗口列表获取
- ✅ 窗口查找（点击位置）
- ✅ 窗口数量统计

#### DelayedScreenshotManager.swift (3 处)
- ✅ 延时截图启动
- ✅ 延时截图取消
- ✅ 倒计时完成

### 4. 新增功能

#### 日志导出
```swift
private func exportLogs() {
    guard let logFile = AppLogger.shared.exportLogs() else {
        // 显示错误提示
        return
    }

    let panel = NSSavePanel()
    panel.nameFieldStringValue = logFile.lastPathComponent
    panel.allowedContentTypes = [.log, .plainText]

    // ... 保存逻辑
}
```

#### 自动日志清理
```swift
// 在应用启动时清理旧日志（保留最近 7 天）
AppLogger.shared.cleanOldLogs(keepLast: 7)
```

## 技术细节

### 日志级别映射

| 自定义级别 | OSLogType | 用途 |
|-----------|-----------|------|
| Debug | .debug | 详细调试信息（包含文件名、行号） |
| Info | .info | 一般信息 |
| Warning | .default | 警告信息 |
| Error | .error | 错误信息 |
| Fault | .fault | 严重错误 |

### 文件日志格式

```
[2025-12-14 10:30:45.123] [INFO] [screenshot] Screenshot completed successfully
[2025-12-14 10:30:45.456] [ERROR] [output] Failed to save file - Error: Permission denied
```

### 性能优化

1. **日志级别过滤**: 在日志记录前检查级别，避免不必要的字符串拼接
2. **异步文件写入**: 使用专用的 DispatchQueue 进行文件操作
3. **延迟初始化**: AppLogger 使用单例模式，按需初始化

### 调试模式增强

在 Debug 模式下，debug 级别的日志会包含额外的上下文信息：
```swift
#if DEBUG
if level == .debug {
    let fileName = (file as NSString).lastPathComponent
    finalMessage = "[\(fileName):\(line)] \(function) - \(message)"
}
#endif
```

## 文件清单

### 新增文件
1. `Sources/SwiftScreenShot/Utilities/AppLogger.swift` - 日志系统核心实现
2. `docs/LOGGING.md` - 日志系统使用文档
3. `docs/LOGGING_IMPLEMENTATION.md` - 实施总结（本文件）

### 修改文件
1. `Sources/SwiftScreenShot/Models/ScreenshotSettings.swift` - 添加日志设置
2. `Sources/SwiftScreenShot/UI/Settings/SettingsView.swift` - 添加日志设置界面
3. `Sources/SwiftScreenShot/App/AppDelegate.swift` - 替换 print 为日志
4. `Sources/SwiftScreenShot/Core/HotKeyManager.swift` - 替换 print 为日志
5. `Sources/SwiftScreenShot/Core/OutputManager.swift` - 替换 print 为日志
6. `Sources/SwiftScreenShot/Core/SoundManager.swift` - 替换 print 为日志
7. `Sources/SwiftScreenShot/Core/ScreenshotHistory.swift` - 替换 print 为日志
8. `Sources/SwiftScreenShot/Core/WindowDetector.swift` - 添加日志点
9. `Sources/SwiftScreenShot/Core/DelayedScreenshotManager.swift` - 添加日志点

## 统计数据

- **替换的 print 语句**: 32 处
- **新增日志点**: 40+ 处
- **日志分类**: 12 个
- **日志级别**: 5 个
- **代码行数**: ~350 行（AppLogger.swift）

## 使用场景示例

### 1. 截图流程日志
```
[INFO] [screenshot] Starting screenshot capture
[DEBUG] [screenshot] Capturing region: (100, 100, 500, 400)
[INFO] [screenshot] Region screenshot captured successfully
[DEBUG] [output] Processing screenshot output
[INFO] [output] Screenshot copied to clipboard
[INFO] [output] Screenshot saved to file: Screenshot_20251214_103045.png
```

### 2. 错误处理日志
```
[ERROR] [screenshot] Failed to start screenshot process - Error: Permission denied
[WARNING] [permission] Screen recording permission not granted
```

### 3. 热键管理日志
```
[DEBUG] [hotkey] Registered hotkey 1: key=6, modifiers=4352
[INFO] [hotkey] Hotkeys changed, re-registering
[DEBUG] [hotkey] Unregistered hotkey 1
```

## 测试验证

### 功能测试
- ✅ 日志级别切换正常工作
- ✅ 文件日志正确保存到指定目录
- ✅ 日志导出功能正常
- ✅ 自动清理功能正常
- ✅ 所有模块的日志正确分类

### 性能测试
- ✅ 日志系统对应用性能无明显影响
- ✅ 文件写入在后台队列进行，不阻塞主线程
- ✅ 日志级别过滤有效减少不必要的处理

### 构建测试
- ✅ Debug 构建成功
- ✅ Release 构建成功
- ⚠️ Swift 6 Sendable 警告（非阻塞性）

## 后续改进建议

1. **日志查看器**: 在应用内添加日志查看界面
2. **实时日志**: 支持实时查看应用日志
3. **日志分析**: 添加日志统计和分析功能
4. **远程上传**: 支持将日志上传到服务器（用于 bug 报告）
5. **日志压缩**: 对旧日志文件进行压缩以节省空间
6. **性能监控**: 集成性能指标日志（CPU、内存使用等）

## 维护指南

### 添加新的日志分类
```swift
// 在 LogCategory 枚举中添加
enum LogCategory: String, CaseIterable {
    // ... 现有分类
    case newCategory = "newCategory"
}
```

### 添加日志点
```swift
// 在关键操作处添加日志
AppLogger.shared.info("Operation completed", category: .newCategory)

// 错误处理时添加日志
AppLogger.shared.error("Operation failed", category: .newCategory, error: error)
```

### 调试时启用详细日志
```swift
// 在设置中将日志级别改为 Debug
// 或在代码中临时设置
AppLogger.shared.setMinimumLevel(.debug)
```

## 结论

成功实现了完整的结构化日志系统，提升了应用的可维护性和调试能力。系统设计合理，性能良好，易于使用和扩展。所有关键路径都已添加适当的日志点，为后续开发和问题排查提供了良好的基础。
