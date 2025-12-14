//
//  ErrorRecoveryManager.swift
//  SwiftScreenShot
//
//  Manages error recovery and retry logic
//

import Foundation
import AppKit

/// Error recovery manager singleton
class ErrorRecoveryManager {
    static let shared = ErrorRecoveryManager()

    private let settings: ScreenshotSettings
    private let errorLogger: ErrorLogger
    private let retryQueue: OperationQueue
    private var activeRetries: [String: RetryContext] = [:]
    private let lock = NSLock()

    // Retry settings (can be configured from Settings)
    @Published var retryConfiguration: RetryConfiguration

    private init() {
        self.settings = ScreenshotSettings()
        self.errorLogger = ErrorLogger.shared
        self.retryQueue = OperationQueue()
        self.retryQueue.maxConcurrentOperationCount = 3
        self.retryQueue.qualityOfService = .userInitiated

        // Load retry configuration from UserDefaults
        self.retryConfiguration = RetryConfiguration(
            maxAttempts: UserDefaults.standard.integer(forKey: "retryMaxAttempts") > 0
                ? UserDefaults.standard.integer(forKey: "retryMaxAttempts") : 3,
            delays: [0.5, 1.0, 2.0],
            enabled: UserDefaults.standard.object(forKey: "retryEnabled") as? Bool ?? true
        )
    }

    /// Update retry configuration
    func updateRetryConfiguration(_ config: RetryConfiguration) {
        self.retryConfiguration = config
        UserDefaults.standard.set(config.maxAttempts, forKey: "retryMaxAttempts")
        UserDefaults.standard.set(config.enabled, forKey: "retryEnabled")
    }

    /// Execute operation with automatic retry on failure
    func executeWithRetry<T>(
        operation: @escaping () async throws -> T,
        onError: ((RecoverableError) -> Void)? = nil,
        onSuccess: ((T) -> Void)? = nil
    ) async -> RecoveryResult {
        let operationId = UUID().uuidString
        let context = RetryContext(
            id: operationId,
            maxAttempts: retryConfiguration.maxAttempts,
            enabled: retryConfiguration.enabled
        )

        lock.lock()
        activeRetries[operationId] = context
        lock.unlock()

        defer {
            lock.lock()
            activeRetries.removeValue(forKey: operationId)
            lock.unlock()
        }

        var lastError: RecoverableError?

        for attempt in 1...context.maxAttempts {
            do {
                // Log retry attempt
                if attempt > 1 {
                    errorLogger.logRetryAttempt(operationId: operationId, attempt: attempt)
                }

                // Execute operation
                let result = try await operation()

                // Success - log and return
                if attempt > 1 {
                    errorLogger.logRecoverySuccess(operationId: operationId, attempt: attempt)
                }

                onSuccess?(result)
                return .recovered

            } catch {
                // Convert to RecoverableError
                let recoverableError = convertToRecoverableError(error, attempt: attempt)
                lastError = recoverableError

                // Log error
                errorLogger.logError(recoverableError, operationId: operationId, attempt: attempt)

                // Notify error handler
                onError?(recoverableError)

                // Check if error is recoverable
                if !recoverableError.category.isRecoverable {
                    return .userActionRequired(recoverableError)
                }

                // Check if we should retry
                if !context.enabled || attempt >= context.maxAttempts {
                    break
                }

                // Apply exponential backoff delay
                let delay = retryConfiguration.delayForAttempt(attempt)
                try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
            }
        }

        // Max retries exceeded
        if let error = lastError {
            errorLogger.logMaxRetriesExceeded(operationId: operationId)
            return .maxRetriesExceeded(error)
        }

        return .failed(ScreenshotRecoverableError.captureFailed(reason: "Unknown error"))
    }

    /// Handle specific error with appropriate recovery strategy
    func handleError(_ error: RecoverableError) async -> RecoveryResult {
        errorLogger.logError(error, operationId: UUID().uuidString, attempt: 1)

        switch error.category {
        case .permissionDenied:
            return handlePermissionError(error)

        case .systemBusy:
            return await handleSystemBusyError(error)

        case .diskFull:
            return await handleDiskFullError(error)

        case .networkError:
            return await handleNetworkError(error)

        case .unknown:
            return .failed(error)
        }
    }

    // MARK: - Specific Error Handlers

    private func handlePermissionError(_ error: RecoverableError) -> RecoveryResult {
        // Show permission dialog
        DispatchQueue.main.async {
            self.showPermissionDialog(error: error)
        }
        return .userActionRequired(error)
    }

    private func handleSystemBusyError(_ error: RecoverableError) async -> RecoveryResult {
        // Wait and check system status
        try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
        return .failed(error)
    }

    private func handleDiskFullError(_ error: RecoverableError) async -> RecoveryResult {
        // Attempt automatic cleanup
        let cleaned = await attemptDiskCleanup()
        if cleaned {
            errorLogger.logInfo("Disk cleanup successful")
            return .recovered
        }

        // Show cleanup dialog
        DispatchQueue.main.async {
            self.showDiskCleanupDialog(error: error)
        }
        return .userActionRequired(error)
    }

    private func handleNetworkError(_ error: RecoverableError) async -> RecoveryResult {
        // Queue for delayed retry (cloud sync scenario)
        errorLogger.logInfo("Network error - queuing for delayed retry")
        return .failed(error)
    }

    // MARK: - Helper Methods

    private func convertToRecoverableError(_ error: Error, attempt: Int) -> RecoverableError {
        if let recoverable = error as? RecoverableError {
            return recoverable
        }

        // Convert standard errors
        let nsError = error as NSError

        switch nsError.code {
        case -1001, -1009, -1005: // Network errors
            return ScreenshotRecoverableError.networkError(underlying: error)
        case NSFileWriteOutOfSpaceError:
            let space = getAvailableDiskSpace()
            return ScreenshotRecoverableError.diskFull(availableSpace: space)
        case NSFileWriteNoPermissionError:
            return ScreenshotRecoverableError.permissionDenied
        default:
            return ScreenshotRecoverableError.captureFailed(reason: error.localizedDescription)
        }
    }

    private func getAvailableDiskSpace() -> Int64 {
        do {
            let attributes = try FileManager.default.attributesOfFileSystem(forPath: NSHomeDirectory())
            if let freeSize = attributes[.systemFreeSize] as? Int64 {
                return freeSize
            }
        } catch {
            errorLogger.logError(ScreenshotRecoverableError.captureFailed(reason: "Failed to get disk space"), operationId: UUID().uuidString, attempt: 1)
        }
        return 0
    }

    private func attemptDiskCleanup() async -> Bool {
        // Try to clean old screenshots from history
        let historyManager = ScreenshotHistory.shared
        let initialCount = historyManager.screenshots.count

        // Remove oldest 30% if history is full
        if initialCount > 10 {
            let removeCount = max(1, initialCount * 3 / 10)
            historyManager.removeOldest(count: removeCount)

            errorLogger.logInfo("Cleaned \(removeCount) screenshots from history")
            return true
        }

        return false
    }

    // MARK: - UI Dialogs

    private func showPermissionDialog(error: RecoverableError) {
        let alert = NSAlert()
        alert.messageText = error.localizedDescription
        alert.informativeText = error.recoverySuggestion
        alert.alertStyle = .warning
        alert.addButton(withTitle: "打开系统偏好设置")
        alert.addButton(withTitle: "取消")

        let response = alert.runModal()
        if response == .alertFirstButtonReturn {
            openSystemPreferences()
        }
    }

    private func showDiskCleanupDialog(error: RecoverableError) {
        let alert = NSAlert()
        alert.messageText = error.localizedDescription
        alert.informativeText = error.recoverySuggestion
        alert.alertStyle = .warning
        alert.addButton(withTitle: "清理历史记录")
        alert.addButton(withTitle: "更改保存路径")
        alert.addButton(withTitle: "取消")

        let response = alert.runModal()
        if response == .alertFirstButtonReturn {
            Task {
                await attemptDiskCleanup()
            }
        } else if response == .alertSecondButtonReturn {
            openSavePathPicker()
        }
    }

    func showErrorDialog(error: RecoverableError, allowRetry: Bool = true) {
        let alert = NSAlert()
        alert.messageText = error.localizedDescription
        alert.informativeText = error.recoverySuggestion
        alert.alertStyle = .critical

        if let quickAction = error.quickAction {
            alert.addButton(withTitle: quickAction.title)
        }

        if allowRetry && error.category.isRecoverable {
            alert.addButton(withTitle: "重试")
        }

        alert.addButton(withTitle: "取消")

        let response = alert.runModal()
        if response == .alertFirstButtonReturn {
            if let quickAction = error.quickAction {
                performQuickAction(quickAction)
            }
        }
    }

    private func performQuickAction(_ action: ErrorQuickAction) {
        switch action {
        case .openSystemPreferences:
            openSystemPreferences()
        case .cleanupDiskSpace:
            Task {
                await attemptDiskCleanup()
            }
        case .retryNow:
            // Handled by caller
            break
        case .checkNetwork:
            // Open Network preferences
            NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.network")!)
        case .viewErrorLog:
            errorLogger.showLogFile()
        }
    }

    private func openSystemPreferences() {
        let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture")!
        NSWorkspace.shared.open(url)
    }

    private func openSavePathPicker() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.prompt = "选择保存路径"

        if panel.runModal() == .OK, let url = panel.url {
            settings.savePath = url
        }
    }

    /// Get current retry statistics
    func getRetryStatistics() -> [String: Any] {
        lock.lock()
        defer { lock.unlock() }

        return [
            "activeRetries": activeRetries.count,
            "retryEnabled": retryConfiguration.enabled,
            "maxAttempts": retryConfiguration.maxAttempts
        ]
    }
}

// MARK: - Retry Context

private class RetryContext {
    let id: String
    let maxAttempts: Int
    let enabled: Bool
    var currentAttempt: Int = 0

    init(id: String, maxAttempts: Int, enabled: Bool) {
        self.id = id
        self.maxAttempts = maxAttempts
        self.enabled = enabled
    }
}
