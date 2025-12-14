# 日志记录位置参考

本文档提供了 SwiftScreenShot 应用中各个模块的关键日志记录位置，便于快速定位和调试。

## 按功能分类

### 1. 应用生命周期 (category: .app)

#### AppDelegate.swift
```swift
// 应用启动
func applicationDidFinishLaunching()
    ├─ INFO: "Application started"
    ├─ INFO: "Notification permission granted/denied"
    └─ INFO: "Screen recording permission granted"
    
// 应用终止
func applicationWillTerminate()
    └─ INFO: "Application terminating"
```

### 2. 截图功能 (category: .screenshot)

#### AppDelegate.swift
```swift
// 区域截图
func captureSelectedRegion()
    ├─ DEBUG: "Capturing region: (x, y, width, height)"
    ├─ INFO: "Region screenshot captured successfully"
    └─ ERROR: "Failed to capture region screenshot"

// 全屏截图
func captureFullScreen()
    ├─ DEBUG: "Capturing fullscreen with mode: {mode}"
    ├─ INFO: "Fullscreen screenshot captured successfully"
    └─ ERROR: "Failed to capture fullscreen screenshot"

// 窗口截图
func captureSelectedWindow()
    ├─ DEBUG: "Capturing window: {name} (ID: {id})"
    ├─ INFO: "Window screenshot captured successfully: {name}"
    └─ ERROR: "Failed to capture window screenshot"

// 截图流程启动
func startScreenshotProcess()
    ├─ ERROR: "No screen found for screenshot"
    └─ ERROR: "Failed to start screenshot process"
```

### 3. 热键管理 (category: .hotkey)

#### HotKeyManager.swift
```swift
// 热键注册
func register()
    ├─ DEBUG: "Registered hotkey {id}: key={key}, modifiers={modifiers}"
    └─ ERROR: "Failed to register hotkey: status={status}"

// 热键注销
func unregister()
    └─ DEBUG: "Unregistered hotkey {id}"
```

#### AppDelegate.swift
```swift
// 热键变更
@objc func handleHotKeysDidChange()
    └─ INFO: "Hotkeys changed, re-registering"
```

### 4. 输出管理 (category: .output)

#### OutputManager.swift
```swift
// 截图处理
func processScreenshot()
    ├─ DEBUG: "Processing screenshot output"
    └─ INFO: "Screenshot copied to clipboard"

// 文件保存
func saveToFile()
    ├─ INFO: "Screenshot saved to file: {filename}"
    ├─ ERROR: "Failed to save screenshot to file"
    └─ ERROR: "Failed to convert image to {format} format"

// 通知显示
func showNotification()
    ├─ DEBUG: "Notification displayed for saved screenshot"
    └─ ERROR: "Failed to show notification"
```

### 5. 历史记录 (category: .history)

#### ScreenshotHistory.swift
```swift
// 添加截图
func addScreenshot()
    ├─ ERROR: "Failed to save screenshot to history"
    └─ WARNING: "Failed to save thumbnail for history item"

// 保存图片
func saveImage()
    └─ ERROR: "Error saving image to {filename}"

// 加载历史
func loadHistory()
    ├─ INFO: "Loaded {count} items from history"
    └─ ERROR: "Failed to load history"

// 保存索引
func saveIndex()
    ├─ DEBUG: "Saved history index with {count} items"
    └─ ERROR: "Failed to save history index"
```

### 6. 窗口检测 (category: .window)

#### WindowDetector.swift
```swift
// 获取所有窗口
func getAllWindows()
    ├─ DEBUG: "Found {count} valid windows"
    └─ ERROR: "Failed to get window list from system"

// 查找窗口
func windowAtPoint()
    ├─ DEBUG: "Window found at point ({x}, {y}): {name}"
    └─ DEBUG: "No window found at point ({x}, {y})"
```

### 7. 音效管理 (category: .sound)

#### SoundManager.swift
```swift
// 播放音效
func playCapture()
    ├─ DEBUG: "Playing capture sound"
    └─ WARNING: "Capture sound not available"

// 系统音效
func playSystemShutterSound()
    └─ ERROR: "Failed to play system shutter sound"

// 条件播放
func playCaptureIfEnabled()
    └─ DEBUG: "Capture sound disabled in settings"
```

### 8. 延时截图 (category: .delay)

#### DelayedScreenshotManager.swift
```swift
// 启动延时
func startDelayedScreenshot()
    └─ INFO: "Starting delayed screenshot: {delay}s delay, mode: {mode}"

// 取消延时
func cancelDelayedScreenshot()
    └─ INFO: "Delayed screenshot cancelled"

// 完成倒计时
func completeCountdown()
    └─ INFO: "Delayed screenshot countdown completed, executing screenshot"
```

### 9. 设置管理 (category: .settings)

#### ScreenshotSettings.swift
```swift
// 启动项配置
func configureLaunchAtLogin()
    └─ ERROR: "Failed to configure launch at login"

// 日志级别变更
AppLogger.setMinimumLevel()
    └─ INFO: "Log level changed to {level}"

// 文件日志开关
AppLogger.setFileLogging()
    └─ INFO: "File logging enabled/disabled"
```

#### SettingsView.swift
```swift
// 日志导出
func exportLogs()
    ├─ INFO: "Logs exported to {path}"
    └─ ERROR: "Failed to export logs"
```

### 10. 编辑器 (category: .editor)

#### AppDelegate.swift
```swift
// 打开编辑器
func captureSelectedRegion/captureFullScreen/captureSelectedWindow()
    └─ DEBUG: "Opening editor for {type} screenshot"
```

### 11. 权限管理 (category: .permission)

#### AppDelegate.swift
```swift
// 屏幕录制权限
func applicationDidFinishLaunching()
    ├─ INFO: "Screen recording permission granted"
    └─ WARNING: "Screen recording permission not granted"

// 通知权限
func applicationDidFinishLaunching()
    ├─ INFO: "Notification permission granted"
    ├─ WARNING: "Notification permission denied"
    └─ ERROR: "Failed to request notification permission"
```

## 按日志级别分类

### Debug 级别
- 热键注册详情（包含键码和修饰键）
- 截图区域坐标
- 窗口查找结果
- 历史索引保存
- 窗口数量统计
- 音效状态
- 编辑器打开
- 输出处理流程

### Info 级别
- 应用启动/终止
- 截图成功
- 文件保存成功
- 剪贴板复制
- 热键变更
- 权限授予
- 历史加载
- 延时截图启动/完成

### Warning 级别
- 权限被拒绝
- 缩略图保存失败
- 音效不可用

### Error 级别
- 截图失败
- 文件保存失败
- 热键注册失败
- 系统错误（窗口列表、屏幕查找等）
- 历史记录错误
- 日志导出失败

### Fault 级别
- 当前未使用（预留给严重系统错误）

## 常用调试场景

### 场景 1: 截图失败
查看日志：
```bash
log stream --predicate 'subsystem == "com.swiftscreenshot.app" AND category == "screenshot"' --level debug
```

关键日志点：
1. AppDelegate.captureSelectedRegion/captureFullScreen/captureSelectedWindow
2. ScreenshotEngine（虽未添加日志，但会抛出异常）
3. PermissionManager（权限检查）

### 场景 2: 热键冲突
查看日志：
```bash
log stream --predicate 'subsystem == "com.swiftscreenshot.app" AND category == "hotkey"'
```

关键日志点：
1. HotKeyManager.register (ERROR: Failed to register)
2. AppDelegate.handleHotKeysDidChange (INFO: re-registering)

### 场景 3: 文件保存问题
查看日志：
```bash
log stream --predicate 'subsystem == "com.swiftscreenshot.app" AND category == "output"'
```

关键日志点：
1. OutputManager.saveToFile (ERROR: Failed to save)
2. OutputManager.processScreenshot (INFO: copied to clipboard)

### 场景 4: 窗口检测问题
查看日志：
```bash
log stream --predicate 'subsystem == "com.swiftscreenshot.app" AND category == "window"' --level debug
```

关键日志点：
1. WindowDetector.getAllWindows (DEBUG: window count)
2. WindowDetector.windowAtPoint (DEBUG: found/not found)

## 日志文件位置

所有文件日志保存在：
```
~/Library/Application Support/SwiftScreenShot/Logs/
```

文件格式：
```
SwiftScreenShot_2025-12-14.log
```

## 快速定位代码

```bash
# 查找所有日志调用
grep -r "AppLogger.shared" Sources/SwiftScreenShot --include="*.swift"

# 按级别查找
grep -r "AppLogger.shared.error" Sources/SwiftScreenShot --include="*.swift"

# 按分类查找
grep -r "category: .screenshot" Sources/SwiftScreenShot --include="*.swift"
```

## 性能监控

关键性能相关日志：
- Screenshot capture timing (通过 debug 日志的时间戳计算)
- File save operations (info 级别)
- Window enumeration (debug 级别 - window count)

## 建议的日志级别

| 环境 | 推荐级别 | 说明 |
|------|---------|------|
| Development | Debug | 查看所有详细信息 |
| Testing | Info | 正常流程和错误 |
| Production | Warning | 只看警告和错误 |
| Bug Investigation | Debug | 临时启用详细日志 |
