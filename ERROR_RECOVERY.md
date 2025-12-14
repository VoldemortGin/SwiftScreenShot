# 错误恢复机制文档

## 概述

SwiftScreenShot 应用实现了一套完善的错误恢复机制，能够自动处理各种错误情况并提供用户友好的恢复选项。

## 核心组件

### 1. RecoverableError 协议

定义了可恢复错误的标准接口：

```swift
protocol RecoverableError: Error {
    var category: ErrorCategory { get }
    var localizedDescription: String { get }
    var recoverySuggestion: String { get }
    var quickAction: ErrorQuickAction? { get }
}
```

### 2. ErrorRecoveryManager

错误恢复管理器单例，负责：
- 自动重试逻辑
- 错误分类和处理
- 用户交互对话框
- 恢复策略执行

### 3. ErrorLogger

错误日志记录器，提供：
- 结构化日志记录
- 日志缓冲和批量写入
- 自动日志清理（7天）
- 错误报告生成

## 错误类型

### 1. 权限错误 (Permission Denied)

**特征：**
- 用户未授予屏幕录制权限
- 不可自动恢复

**恢复策略：**
- 显示权限引导对话框
- 提供"打开系统偏好设置"快捷按钮
- 直接跳转到隐私设置页面

**示例代码：**
```swift
throw ScreenshotRecoverableError.permissionDenied
```

### 2. 系统繁忙 (System Busy)

**特征：**
- 系统资源临时不足
- 可自动恢复

**恢复策略：**
- 自动重试，最多 3 次
- 指数退避延迟（0.5秒、1秒、2秒）
- 无需用户干预

**示例代码：**
```swift
throw ScreenshotRecoverableError.systemBusy(attempt: 1)
```

### 3. 磁盘空间不足 (Disk Full)

**特征：**
- 可用磁盘空间不足以保存截图
- 部分可自动恢复

**恢复策略：**
1. 自动清理历史记录（最多清理 30%）
2. 如清理失败，显示用户对话框：
   - "清理历史记录"按钮
   - "更改保存路径"按钮
   - 显示当前可用空间

**示例代码：**
```swift
throw ScreenshotRecoverableError.diskFull(availableSpace: availableSpace)
```

### 4. 网络错误 (Network Error)

**特征：**
- 云同步失败
- 可延迟重试

**恢复策略：**
- 队列化失败的操作
- 网络恢复后自动重试
- 不阻塞主要截图功能

**示例代码：**
```swift
throw ScreenshotRecoverableError.networkError(underlying: error)
```

### 5. 未知错误 (Unknown)

**特征：**
- 未分类的错误
- 尝试自动恢复

**恢复策略：**
- 执行默认重试逻辑
- 记录详细日志
- 提供"查看日志"选项

## 自动重试机制

### 配置参数

```swift
struct RetryConfiguration {
    let maxAttempts: Int        // 最大重试次数（1-5）
    let delays: [TimeInterval]  // 重试延迟数组
    let enabled: Bool           // 是否启用自动重试
}
```

### 默认配置

```swift
static let `default` = RetryConfiguration(
    maxAttempts: 3,
    delays: [0.5, 1.0, 2.0],
    enabled: true
)
```

### 指数退避策略

| 重试次数 | 延迟时间 | 累计时间 |
|---------|---------|---------|
| 第 1 次 | 0.5 秒  | 0.5 秒  |
| 第 2 次 | 1.0 秒  | 1.5 秒  |
| 第 3 次 | 2.0 秒  | 3.5 秒  |

### 自定义重试间隔

用户可以通过设置调整重试间隔倍数（0.5x - 2.0x）：

```swift
// 1.5x 倍数示例
delays = [0.75, 1.5, 3.0]
```

## 使用方法

### 1. 在异步操作中使用

```swift
let result = await errorRecoveryManager.executeWithRetry(
    operation: {
        try await performScreenshotCapture()
    },
    onError: { error in
        self.errorLogger.logError(error, operationId: operationId, attempt: 1)
    },
    onSuccess: { image in
        self.processImage(image)
    }
)

switch result {
case .recovered:
    // 成功恢复
    break
case .failed(let error):
    // 失败，显示错误
    showError(error)
case .userActionRequired(let error):
    // 需要用户操作
    showActionDialog(error)
case .maxRetriesExceeded(let error):
    // 超过最大重试次数
    showMaxRetriesError(error)
}
```

### 2. 手动处理特定错误

```swift
let result = await errorRecoveryManager.handleError(error)
```

### 3. 错误日志记录

```swift
// 记录错误
errorLogger.logError(error, operationId: operationId, attempt: 1)

// 记录重试
errorLogger.logRetryAttempt(operationId: operationId, attempt: 2)

// 记录成功恢复
errorLogger.logRecoverySuccess(operationId: operationId, attempt: 3)

// 记录警告
errorLogger.logWarning("Disk space low", details: ["available": "100MB"])
```

## 用户界面

### 错误对话框

所有错误对话框包含：
1. **错误标题** - 简洁的错误描述
2. **详细信息** - 错误的详细说明
3. **恢复建议** - 具体的解决步骤
4. **快捷操作** - 一键操作按钮（如"授予权限"、"清理空间"）
5. **重试选项** - 对可恢复错误提供重试按钮

### 设置界面

位置：设置 > 错误恢复

功能：
- 启用/禁用自动重试
- 调整最大重试次数（1-5次）
- 调整重试间隔倍数（0.5x-2.0x）
- 查看错误统计
- 管理错误日志

## 日志管理

### 日志格式

```
[2025-12-14 10:30:45.123] [ERROR] [PERMISSIONDENIED] 屏幕录制权限被拒绝 [Attempt: 1] [OperationID: xxx-xxx-xxx]
  Details: {"recovery_suggestion": "请在系统偏好设置中授予权限", "category": "permissionDenied"}
```

### 日志存储

- **位置**: `~/Library/Application Support/SwiftScreenShot/Logs/`
- **文件名**: `error_log_YYYY-MM-DD.txt`
- **保留期**: 7 天自动清理
- **缓冲**: 100 条日志批量写入

### 日志操作

```swift
// 查看日志文件
ErrorLogger.shared.showLogFile()

// 导出日志
let url = ErrorLogger.shared.exportLogs()

// 清除日志
ErrorLogger.shared.clearLogs()

// 生成错误报告
let report = ErrorLogger.shared.generateErrorReport()
```

## 集成示例

### ScreenshotEngine 集成

```swift
class ScreenshotEngine {
    private let errorRecoveryManager = ErrorRecoveryManager.shared

    func captureRegion(rect: CGRect, display: SCDisplay) async throws -> NSImage {
        let result = await errorRecoveryManager.executeWithRetry(
            operation: {
                try await self.performCapture(rect: rect, display: display)
            },
            onError: { error in
                self.errorLogger.logError(error, operationId: UUID().uuidString, attempt: 1)
            }
        )

        // 处理结果...
    }
}
```

### OutputManager 集成

```swift
class OutputManager {
    private let errorRecoveryManager = ErrorRecoveryManager.shared

    private func saveToFileWithRetry(_ image: NSImage) async {
        let result = await errorRecoveryManager.executeWithRetry(
            operation: {
                try await self.performSaveToFile(image)
            },
            onError: { error in
                self.errorLogger.logError(error, operationId: UUID().uuidString, attempt: 1)
            }
        )

        // 处理结果...
    }
}
```

## 性能考虑

### 1. 异步执行

所有重试操作都是异步执行，不会阻塞主线程：

```swift
Task {
    await errorRecoveryManager.executeWithRetry(...)
}
```

### 2. 并发限制

重试队列限制并发操作数为 3：

```swift
retryQueue.maxConcurrentOperationCount = 3
```

### 3. 日志缓冲

日志缓冲机制减少 I/O 操作：
- 缓冲区大小：100 条
- 批量写入
- 错误立即刷新

## 最佳实践

### 1. 错误分类

始终将错误转换为 `RecoverableError`：

```swift
private func convertToRecoverableError(_ error: Error) -> RecoverableError {
    if let recoverable = error as? RecoverableError {
        return recoverable
    }

    // 根据具体错误类型转换...
}
```

### 2. 提供恢复建议

为每个错误提供清晰的恢复建议：

```swift
var recoverySuggestion: String {
    return "请在"系统偏好设置 > 隐私与安全性 > 屏幕录制"中允许访问。"
}
```

### 3. 快捷操作

为常见错误提供一键操作：

```swift
var quickAction: ErrorQuickAction? {
    case .permissionDenied:
        return .openSystemPreferences
    case .diskFull:
        return .cleanupDiskSpace
}
```

### 4. 详细日志

记录足够的上下文信息以便调试：

```swift
errorLogger.logError(
    error,
    operationId: operationId,
    attempt: attempt
)
```

## 测试建议

### 1. 权限错误测试

- 撤销屏幕录制权限
- 触发截图操作
- 验证权限对话框显示
- 验证引导流程

### 2. 磁盘空间测试

- 创建大文件占满磁盘
- 尝试保存截图
- 验证清理机制
- 验证用户提示

### 3. 重试逻辑测试

- 模拟临时性错误
- 验证重试次数
- 验证延迟时间
- 验证最终结果

### 4. 日志测试

- 验证日志记录
- 验证日志格式
- 验证自动清理
- 验证导出功能

## 故障排除

### 问题：重试不生效

**检查项：**
1. 确认 `autoRetryEnabled` 设置为 `true`
2. 检查错误是否为可恢复类型
3. 查看日志确认重试记录

### 问题：日志文件过大

**解决方案：**
1. 检查日志清理是否正常运行
2. 手动清除旧日志
3. 调整保留天数

### 问题：权限对话框不显示

**检查项：**
1. 确认错误类型正确
2. 检查主线程调用
3. 验证对话框代码

## 未来改进

1. **智能重试间隔**：根据错误类型动态调整重试间隔
2. **错误统计分析**：提供错误趋势和统计报告
3. **远程日志上传**：支持将错误日志上传到服务器进行分析
4. **自定义恢复策略**：允许用户自定义特定错误的恢复策略
5. **错误预测**：基于历史数据预测可能的错误并提前处理

## 相关文件

- `/SwiftScreenShot/Models/RecoverableError.swift` - 错误定义
- `/SwiftScreenShot/Core/ErrorRecoveryManager.swift` - 恢复管理器
- `/SwiftScreenShot/Core/ErrorLogger.swift` - 日志记录器
- `/SwiftScreenShot/UI/Settings/ErrorRecoverySettingsView.swift` - 设置界面
- `/SwiftScreenShot/Core/ScreenshotEngine.swift` - 截图引擎集成
- `/SwiftScreenShot/Core/OutputManager.swift` - 输出管理器集成

## 许可证

MIT License - 详见 LICENSE 文件
