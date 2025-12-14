# SwiftScreenShot 日志系统文档

## 概述

SwiftScreenShot 使用结构化日志系统，基于 Apple 的 `os.Logger` 框架实现。该系统提供了分级日志记录、分类管理、文件导出等功能，便于开发调试和问题排查。

## 功能特性

### 1. 日志级别 (Log Levels)

系统支持 5 个日志级别，从低到高：

| 级别 | 用途 | 示例场景 |
|------|------|---------|
| **Debug** | 详细的调试信息 | 函数调用、变量值、详细流程 |
| **Info** | 一般性信息 | 截图成功、热键注册、文件保存 |
| **Warning** | 警告信息 | 权限问题、配置异常 |
| **Error** | 错误信息 | 截图失败、文件保存失败 |
| **Fault** | 严重错误 | 系统故障、崩溃前状态 |

### 2. 日志分类 (Log Categories)

为不同模块定义了专门的日志分类：

| 分类 | 模块 | 说明 |
|------|------|------|
| `screenshot` | 截图相关 | 截图捕获、处理流程 |
| `hotkey` | 热键管理 | 热键注册、触发、冲突 |
| `settings` | 设置管理 | 配置变更、持久化 |
| `editor` | 编辑器 | 图片编辑、标注功能 |
| `history` | 历史记录 | 历史保存、加载、清理 |
| `window` | 窗口检测 | 窗口枚举、选择 |
| `permission` | 权限管理 | 权限检查、请求 |
| `output` | 输出管理 | 文件保存、剪贴板 |
| `sound` | 音效管理 | 音效播放 |
| `annotation` | 标注管理 | 标注添加、编辑 |
| `delay` | 延时截图 | 倒计时、延时执行 |
| `app` | 应用生命周期 | 启动、终止、通知 |

### 3. 文件日志

- 日志文件保存路径：`~/Library/Application Support/SwiftScreenShot/Logs/`
- 文件命名格式：`SwiftScreenShot_YYYY-MM-DD.log`
- 自动清理：启动时保留最近 7 天的日志
- 日志格式：
  ```
  [2025-12-14 10:30:45.123] [INFO] [screenshot] Screenshot captured successfully
  [2025-12-14 10:30:45.456] [ERROR] [output] Failed to save file - Error: Permission denied
  ```

## 使用方法

### 基本用法

```swift
// Debug 级别 - 详细调试信息（包含文件名、行号）
AppLogger.shared.debug("Variable value: \(value)", category: .screenshot)

// Info 级别 - 一般信息
AppLogger.shared.info("Screenshot saved successfully", category: .output)

// Warning 级别 - 警告
AppLogger.shared.warning("Permission not granted", category: .permission)

// Error 级别 - 错误（可以附带 Error 对象）
AppLogger.shared.error("Failed to save file", category: .output, error: error)

// Fault 级别 - 严重错误
AppLogger.shared.fault("System crash detected", category: .app)
```

### 配置日志级别

在设置界面或代码中配置：

```swift
// 设置最小日志级别
AppLogger.shared.setMinimumLevel(.debug)  // 显示所有日志
AppLogger.shared.setMinimumLevel(.info)   // 只显示 info 及以上
AppLogger.shared.setMinimumLevel(.error)  // 只显示错误

// 启用/禁用文件日志
AppLogger.shared.setFileLogging(enabled: true)
```

### 日志导出

```swift
// 导出当前日志文件
if let logFile = AppLogger.shared.exportLogs() {
    print("Log file: \(logFile.path)")
}

// 获取所有日志文件
let allLogs = AppLogger.shared.getAllLogFiles()

// 清理旧日志（保留最近 N 个文件）
AppLogger.shared.cleanOldLogs(keepLast: 7)
```

## 开发指南

### 何时记录日志

#### ✅ 应该记录的场景

1. **关键操作的开始和结束**
   ```swift
   AppLogger.shared.info("Starting screenshot capture", category: .screenshot)
   // ... 执行截图 ...
   AppLogger.shared.info("Screenshot completed: \(filename)", category: .screenshot)
   ```

2. **错误和异常**
   ```swift
   do {
       try saveFile()
   } catch {
       AppLogger.shared.error("Failed to save file", category: .output, error: error)
   }
   ```

3. **配置变更**
   ```swift
   AppLogger.shared.info("Hotkey changed to \(config.displayString)", category: .hotkey)
   ```

4. **权限状态**
   ```swift
   if granted {
       AppLogger.shared.info("Screen recording permission granted", category: .permission)
   } else {
       AppLogger.shared.warning("Screen recording permission denied", category: .permission)
   }
   ```

5. **调试信息**（仅在 Debug 级别）
   ```swift
   AppLogger.shared.debug("Processing \(count) windows", category: .window)
   ```

#### ❌ 不应该记录的场景

1. 高频率的轮询或循环
2. 敏感信息（密码、token 等）
3. 过于琐碎的细节（除非是 debug 级别）

### 最佳实践

1. **使用合适的级别**
   - 正常流程用 `info`
   - 可能的问题用 `warning`
   - 实际错误用 `error`
   - 调试细节用 `debug`

2. **提供上下文信息**
   ```swift
   // ✅ 好的日志
   AppLogger.shared.error("Failed to save screenshot to \(path)", category: .output, error: error)

   // ❌ 不好的日志
   AppLogger.shared.error("Save failed", category: .output)
   ```

3. **使用正确的分类**
   - 根据功能模块选择对应的 category
   - 有助于日志过滤和分析

4. **错误处理时附带 Error 对象**
   ```swift
   AppLogger.shared.error("Operation failed", category: .app, error: error)
   ```

## 调试技巧

### 1. 在 Console.app 中查看日志

1. 打开 macOS 的 Console.app
2. 选择设备（本机）
3. 在搜索框输入：`subsystem:com.swiftscreenshot.app`
4. 可以按 category 过滤：`category:screenshot`

### 2. 使用 log 命令行工具

```bash
# 查看实时日志
log stream --predicate 'subsystem == "com.swiftscreenshot.app"'

# 查看特定分类的日志
log stream --predicate 'subsystem == "com.swiftscreenshot.app" AND category == "screenshot"'

# 查看特定时间段的日志
log show --predicate 'subsystem == "com.swiftscreenshot.app"' --last 1h
```

### 3. 导出日志文件

在设置界面点击"导出日志"按钮，或直接访问：
```
~/Library/Application Support/SwiftScreenShot/Logs/
```

## 配置说明

### 用户设置

在应用的设置界面中，用户可以配置：

1. **日志级别**：选择 Debug/Info/Warning/Error/Fault
2. **文件日志**：启用/禁用日志文件保存

### 开发模式

在 Debug 构建中，默认日志级别为 `Debug`，包含更多调试信息。
在 Release 构建中，默认日志级别为 `Info`，减少日志输出。

## 性能考虑

1. **异步文件写入**：文件日志在后台队列中写入，不影响主线程
2. **日志级别过滤**：低于最小级别的日志不会被处理
3. **自动清理**：启动时自动清理旧日志，避免占用过多空间

## 故障排查

### 问题：看不到日志输出

1. 检查日志级别设置是否过高
2. 确认是否启用了文件日志（如果需要）
3. 在 Console.app 中检查是否有输出

### 问题：日志文件过大

1. 降低日志级别（从 Debug 改为 Info）
2. 检查是否有异常的高频日志
3. 手动清理旧日志文件

### 问题：日志导出失败

1. 确认已启用文件日志
2. 检查应用支持目录的权限
3. 查看是否有磁盘空间

## 未来改进

- [ ] 添加日志查看器 UI
- [ ] 支持日志级别的动态调整（无需重启）
- [ ] 添加日志统计和分析功能
- [ ] 支持远程日志上传（用于 bug 报告）
- [ ] 添加日志搜索和过滤功能

## 相关文件

- `Sources/SwiftScreenShot/Utilities/AppLogger.swift` - 日志系统核心实现
- `Sources/SwiftScreenShot/Models/ScreenshotSettings.swift` - 日志设置管理
- `Sources/SwiftScreenShot/UI/Settings/SettingsView.swift` - 日志设置 UI
