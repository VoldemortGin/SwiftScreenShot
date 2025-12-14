# 错误恢复机制 - 快速指南

## 功能概述

SwiftScreenShot 错误恢复机制提供：

✅ **自动重试** - 截图失败自动重试最多 3 次
✅ **智能延迟** - 指数退避策略（0.5秒、1秒、2秒）
✅ **错误分类** - 5 种错误类型，针对性恢复策略
✅ **用户引导** - 友好的错误提示和解决建议
✅ **日志记录** - 完整的错误日志和统计分析
✅ **可配置** - 灵活的设置选项

## 快速开始

### 1. 在代码中使用

```swift
// 方法一：使用 executeWithRetry（推荐）
let result = await ErrorRecoveryManager.shared.executeWithRetry(
    operation: {
        try await performScreenshotCapture()
    }
)

// 方法二：手动处理错误
do {
    try await performOperation()
} catch let error as RecoverableError {
    await ErrorRecoveryManager.shared.handleError(error)
}
```

### 2. 配置重试设置

通过设置界面：
- 打开设置
- 选择"错误恢复"标签
- 调整重试次数（1-5次）
- 调整重试间隔（0.5x-2.0x）

### 3. 查看错误日志

```swift
// 显示日志文件
ErrorLogger.shared.showLogFile()

// 导出日志
let url = ErrorLogger.shared.exportLogs()

// 清除日志
ErrorLogger.shared.clearLogs()
```

## 错误类型速查

| 错误类型 | 图标 | 可重试 | 恢复方式 |
|---------|------|-------|---------|
| 权限错误 | 🔒 | ❌ | 打开系统偏好设置 |
| 系统繁忙 | ⚠️ | ✅ | 自动重试 |
| 磁盘已满 | 💾 | ⚠️ | 清理历史/更改路径 |
| 网络错误 | 📡 | ✅ | 队列延迟重试 |
| 未知错误 | ❓ | ✅ | 尝试重试 |

## 设置选项

### 自动重试
- **启用/禁用**：控制是否自动重试
- **默认**：启用

### 最大重试次数
- **范围**：1-5 次
- **默认**：3 次
- **推荐**：3 次（平衡性能和成功率）

### 重试间隔倍数
- **范围**：0.5x - 2.0x
- **默认**：1.0x
- **基础间隔**：0.5秒、1秒、2秒

**示例配置：**
- 1.0x → 0.5s, 1.0s, 2.0s（默认）
- 0.5x → 0.25s, 0.5s, 1.0s（快速重试）
- 2.0x → 1.0s, 2.0s, 4.0s（保守重试）

## 常见场景

### 场景 1：权限被拒绝

**错误提示：**
```
屏幕录制权限被拒绝

请在"系统偏好设置 > 隐私与安全性 > 屏幕录制"中
允许 SwiftScreenShot 访问屏幕录制功能。

[授予权限] [取消]
```

**操作：**
1. 点击"授予权限"
2. 系统自动打开隐私设置
3. 勾选 SwiftScreenShot
4. 重启应用

### 场景 2：磁盘空间不足

**错误提示：**
```
磁盘空间不足（剩余 50.2 MB）

磁盘空间不足，请清理历史截图或选择其他保存位置。
您可以：
1. 清理历史记录
2. 删除旧的截图文件
3. 更改保存路径到其他磁盘

[清理历史记录] [更改保存路径] [取消]
```

**操作：**
1. 点击"清理历史记录" - 自动清理最旧的 30%
2. 点击"更改保存路径" - 选择新的保存位置

### 场景 3：系统繁忙

**自动处理：**
- 第 1 次重试：等待 0.5 秒
- 第 2 次重试：等待 1 秒
- 第 3 次重试：等待 2 秒
- 如果仍失败，提示用户

## 日志管理

### 日志位置
```
~/Library/Application Support/SwiftScreenShot/Logs/
```

### 日志文件格式
```
error_log_2025-12-14.txt
```

### 日志内容示例
```
[2025-12-14 10:30:45.123] [ERROR] [PERMISSIONDENIED] 屏幕录制权限被拒绝
  Details: {"recovery_suggestion": "...", "category": "permissionDenied"}

[2025-12-14 10:30:46.500] [INFO] Retry attempt 2

[2025-12-14 10:30:48.000] [INFO] Recovery successful after 3 attempts
```

### 日志清理策略
- **自动清理**：保留 7 天
- **手动清理**：设置 > 错误恢复 > 清除日志

## API 参考

### ErrorRecoveryManager

```swift
// 执行带重试的操作
func executeWithRetry<T>(
    operation: @escaping () async throws -> T,
    onError: ((RecoverableError) -> Void)? = nil,
    onSuccess: ((T) -> Void)? = nil
) async -> RecoveryResult

// 处理特定错误
func handleError(_ error: RecoverableError) async -> RecoveryResult

// 更新重试配置
func updateRetryConfiguration(_ config: RetryConfiguration)

// 获取重试统计
func getRetryStatistics() -> [String: Any]
```

### ErrorLogger

```swift
// 记录错误
func logError(_ error: RecoverableError, operationId: String, attempt: Int)

// 记录重试
func logRetryAttempt(operationId: String, attempt: Int)

// 记录成功
func logRecoverySuccess(operationId: String, attempt: Int)

// 记录信息
func logInfo(_ message: String)

// 记录警告
func logWarning(_ message: String, details: [String: String])

// 显示日志文件
func showLogFile()

// 导出日志
func exportLogs() -> URL?

// 清除日志
func clearLogs()

// 生成错误报告
func generateErrorReport() -> String
```

### RecoverableError

```swift
protocol RecoverableError: Error {
    var category: ErrorCategory { get }
    var localizedDescription: String { get }
    var recoverySuggestion: String { get }
    var quickAction: ErrorQuickAction? { get }
}
```

## 性能指标

### 重试开销

| 重试次数 | 最小延迟 | 最大延迟 |
|---------|---------|---------|
| 1 次    | 0 ms    | 0 ms    |
| 2 次    | 500 ms  | 500 ms  |
| 3 次    | 1500 ms | 1500 ms |
| 全部    | 3500 ms | 3500 ms |

### 日志性能

- **缓冲写入**：100 条批量写入
- **异步操作**：不阻塞主线程
- **磁盘占用**：约 1KB / 条日志

## 最佳实践

### ✅ 推荐做法

1. **使用 executeWithRetry**
   ```swift
   await errorRecoveryManager.executeWithRetry {
       try await criticalOperation()
   }
   ```

2. **提供详细的错误信息**
   ```swift
   throw ScreenshotRecoverableError.captureFailed(
       reason: "Display not found: \(displayId)"
   )
   ```

3. **记录关键操作**
   ```swift
   errorLogger.logInfo("Starting screenshot capture")
   ```

### ❌ 避免做法

1. **不要忽略错误结果**
   ```swift
   // 错误
   await errorRecoveryManager.executeWithRetry { ... }

   // 正确
   let result = await errorRecoveryManager.executeWithRetry { ... }
   switch result { ... }
   ```

2. **不要过度重试**
   ```swift
   // 错误：设置过多重试次数
   config.maxAttempts = 10

   // 正确：使用推荐值
   config.maxAttempts = 3
   ```

3. **不要在重试中使用同步操作**
   ```swift
   // 错误
   Thread.sleep(forTimeInterval: 1.0)

   // 正确
   try await Task.sleep(nanoseconds: 1_000_000_000)
   ```

## 故障排除

### Q: 重试功能不工作？

**A:** 检查以下项：
1. 设置中是否启用了自动重试
2. 错误是否为可恢复类型（查看日志）
3. 是否达到最大重试次数

### Q: 日志文件在哪里？

**A:** 路径：
```
~/Library/Application Support/SwiftScreenShot/Logs/
```

或者在设置中点击"查看日志"

### Q: 如何自定义重试策略？

**A:** 通过 ScreenshotSettings：
```swift
settings.maxRetryAttempts = 5
settings.retryIntervalMultiplier = 1.5
```

## 更多信息

- **完整文档**：[ERROR_RECOVERY.md](ERROR_RECOVERY.md)
- **测试用例**：[Tests/ErrorRecoveryTests.swift](Tests/ErrorRecoveryTests.swift)
- **示例代码**：查看 ScreenshotEngine.swift 和 OutputManager.swift

## 联系支持

如有问题或建议，请：
- 查看日志获取详细错误信息
- 导出日志用于问题诊断
- 提交 Issue 并附上错误报告

---

**最后更新**：2025-12-14
**版本**：1.0.0
