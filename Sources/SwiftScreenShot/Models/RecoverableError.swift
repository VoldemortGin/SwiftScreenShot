//
//  RecoverableError.swift
//  SwiftScreenShot
//
//  Error types and recovery protocols
//

import Foundation

/// Error categories for recovery strategies
enum ErrorCategory {
    case permissionDenied
    case systemBusy
    case diskFull
    case networkError
    case unknown

    var isRecoverable: Bool {
        switch self {
        case .permissionDenied, .diskFull:
            return false // Requires user action
        case .systemBusy, .networkError:
            return true // Can auto-retry
        case .unknown:
            return true // Try to recover
        }
    }
}

/// Protocol for recoverable errors
protocol RecoverableError: Error {
    var category: ErrorCategory { get }
    var localizedDescription: String { get }
    var recoverySuggestion: String { get }
    var quickAction: ErrorQuickAction? { get }
}

/// Quick actions for error recovery
enum ErrorQuickAction {
    case openSystemPreferences
    case cleanupDiskSpace
    case retryNow
    case checkNetwork
    case viewErrorLog

    var title: String {
        switch self {
        case .openSystemPreferences:
            return "授予权限"
        case .cleanupDiskSpace:
            return "清理空间"
        case .retryNow:
            return "立即重试"
        case .checkNetwork:
            return "检查网络"
        case .viewErrorLog:
            return "查看日志"
        }
    }
}

/// Screenshot specific errors with recovery support
enum ScreenshotRecoverableError: RecoverableError {
    case permissionDenied
    case systemBusy(attempt: Int)
    case diskFull(availableSpace: Int64)
    case networkError(underlying: Error)
    case captureFailed(reason: String)
    case processingFailed(reason: String)
    case saveFailed(reason: String)

    var category: ErrorCategory {
        switch self {
        case .permissionDenied:
            return .permissionDenied
        case .systemBusy:
            return .systemBusy
        case .diskFull:
            return .diskFull
        case .networkError:
            return .networkError
        case .captureFailed, .processingFailed, .saveFailed:
            return .unknown
        }
    }

    var localizedDescription: String {
        switch self {
        case .permissionDenied:
            return "屏幕录制权限被拒绝"
        case .systemBusy(let attempt):
            return "系统繁忙（尝试 \(attempt) 次）"
        case .diskFull(let space):
            let mb = Double(space) / 1024 / 1024
            return "磁盘空间不足（剩余 \(String(format: "%.1f", mb)) MB）"
        case .networkError:
            return "网络连接失败"
        case .captureFailed(let reason):
            return "截图失败：\(reason)"
        case .processingFailed(let reason):
            return "图像处理失败：\(reason)"
        case .saveFailed(let reason):
            return "保存失败：\(reason)"
        }
    }

    var recoverySuggestion: String {
        switch self {
        case .permissionDenied:
            return "请在\"系统偏好设置 > 隐私与安全性 > 屏幕录制\"中允许 SwiftScreenShot 访问屏幕录制功能。"
        case .systemBusy:
            return "系统正在处理其他任务，请稍候片刻后自动重试。"
        case .diskFull:
            return "磁盘空间不足，请清理历史截图或选择其他保存位置。您可以：\n1. 清理历史记录\n2. 删除旧的截图文件\n3. 更改保存路径到其他磁盘"
        case .networkError:
            return "云同步失败，截图将在网络恢复后自动上传。请检查网络连接。"
        case .captureFailed:
            return "截图捕获失败，将自动重试。如果问题持续，请重启应用。"
        case .processingFailed:
            return "图像处理失败，请检查图像格式设置或尝试其他格式。"
        case .saveFailed:
            return "文件保存失败，请检查保存路径权限或磁盘空间。"
        }
    }

    var quickAction: ErrorQuickAction? {
        switch self {
        case .permissionDenied:
            return .openSystemPreferences
        case .systemBusy:
            return .retryNow
        case .diskFull:
            return .cleanupDiskSpace
        case .networkError:
            return .checkNetwork
        case .captureFailed, .processingFailed, .saveFailed:
            return .viewErrorLog
        }
    }
}

/// Error recovery result
enum RecoveryResult {
    case recovered
    case failed(RecoverableError)
    case userActionRequired(RecoverableError)
    case maxRetriesExceeded(RecoverableError)
}

/// Retry configuration
struct RetryConfiguration {
    let maxAttempts: Int
    let delays: [TimeInterval]
    let enabled: Bool

    static let `default` = RetryConfiguration(
        maxAttempts: 3,
        delays: [0.5, 1.0, 2.0],
        enabled: true
    )

    func delayForAttempt(_ attempt: Int) -> TimeInterval {
        guard attempt > 0 && attempt <= delays.count else {
            return delays.last ?? 2.0
        }
        return delays[attempt - 1]
    }
}
