//
//  OutputManager.swift
//  SwiftScreenShot
//
//  Output manager for clipboard and file saving with error recovery
//

import AppKit
import UserNotifications

class OutputManager {
    private let settings: ScreenshotSettings
    private let imageProcessor = ImageProcessor()
    private let soundManager = SoundManager.shared
    private let errorRecoveryManager = ErrorRecoveryManager.shared
    private let errorLogger = ErrorLogger.shared

    init(settings: ScreenshotSettings) {
        self.settings = settings
    }

    /// Process screenshot output with error handling
    func processScreenshot(_ image: NSImage) async {
        // 1. Play capture sound if enabled
        soundManager.playCaptureIfEnabled(enabled: settings.playSoundOnCapture)

        // 2. Always copy to clipboard
        await copyToClipboardWithRetry(image)

        // 3. Save to file if enabled in settings
        if settings.shouldSaveToFile {
            await saveToFileWithRetry(image)
        }

        // 4. Add to history if enabled
        if settings.autoSaveToHistory {
            await addToHistoryWithRetry(image)
        }
    }

    /// Copy to clipboard with error handling
    private func copyToClipboardWithRetry(_ image: NSImage) async {
        let result = await errorRecoveryManager.executeWithRetry(
            operation: {
                self.copyToClipboard(image)
                return true
            },
            onError: { error in
                self.errorLogger.logError(error, operationId: UUID().uuidString, attempt: 1)
            }
        )

        if case .failed(let error) = result {
            await MainActor.run {
                errorRecoveryManager.showErrorDialog(error: error, allowRetry: false)
            }
        }
    }

    /// Save to file with retry and disk space checking
    private func saveToFileWithRetry(_ image: NSImage) async {
        let result = await errorRecoveryManager.executeWithRetry(
            operation: {
                try await self.performSaveToFile(image)
            },
            onError: { error in
                self.errorLogger.logError(error, operationId: UUID().uuidString, attempt: 1)
            }
        )

        switch result {
        case .recovered:
            break // Success
        case .failed(let error), .maxRetriesExceeded(let error):
            await MainActor.run {
                errorRecoveryManager.showErrorDialog(error: error, allowRetry: true)
            }
        case .userActionRequired(let error):
            await MainActor.run {
                errorRecoveryManager.showErrorDialog(error: error, allowRetry: false)
            }
        }
    }

    /// Add to history with error handling
    private func addToHistoryWithRetry(_ image: NSImage) async {
        let result = await errorRecoveryManager.executeWithRetry(
            operation: {
                ScreenshotHistory.shared.addScreenshot(image, format: self.settings.imageFormat)
                return true
            },
            onError: { error in
                self.errorLogger.logError(error, operationId: UUID().uuidString, attempt: 1)
            }
        )

        if case .failed(let error) = result {
            errorLogger.logWarning("Failed to add to history: \(error.localizedDescription)")
        }
    }

    /// Copy image to clipboard
    private func copyToClipboard(_ image: NSImage) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.writeObjects([image])
    }

    /// Perform save to file with disk space checking
    private func performSaveToFile(_ image: NSImage) async throws {
        guard let savePath = settings.savePath else {
            throw ScreenshotRecoverableError.saveFailed(reason: "Save path not configured")
        }

        // Check available disk space
        let availableSpace = try getAvailableDiskSpace(at: savePath)
        let estimatedSize: Int64 = 5 * 1024 * 1024 // Estimate 5MB per screenshot

        if availableSpace < estimatedSize {
            throw ScreenshotRecoverableError.diskFull(availableSpace: availableSpace)
        }

        // Generate filename with timestamp
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd_HHmmss"
        let timestamp = formatter.string(from: Date())
        let fileName = "Screenshot_\(timestamp).\(settings.imageFormat.fileExtension)"

        let fileURL = savePath.appendingPathComponent(fileName)

        // Convert image format and save
        guard let imageData = imageProcessor.imageData(from: image, format: settings.imageFormat) else {
            throw ScreenshotRecoverableError.processingFailed(reason: "Failed to convert image to \(settings.imageFormat.rawValue)")
        }

        do {
            try imageData.write(to: fileURL)
            await showNotification(fileName: fileName, path: fileURL)
        } catch {
            // Check for specific file errors
            let nsError = error as NSError
            if nsError.code == NSFileWriteOutOfSpaceError {
                throw ScreenshotRecoverableError.diskFull(availableSpace: availableSpace)
            } else if nsError.code == NSFileWriteNoPermissionError {
                throw ScreenshotRecoverableError.saveFailed(reason: "No permission to write to save location")
            } else {
                throw ScreenshotRecoverableError.saveFailed(reason: error.localizedDescription)
            }
        }
    }

    /// Get available disk space at path
    private func getAvailableDiskSpace(at url: URL) throws -> Int64 {
        let attributes = try FileManager.default.attributesOfFileSystem(forPath: url.path)
        if let freeSize = attributes[.systemFreeSize] as? Int64 {
            return freeSize
        }
        return 0
    }

    /// Show save success notification
    private func showNotification(fileName: String, path: URL) async {
        let content = UNMutableNotificationContent()
        content.title = "截图已保存"
        content.body = fileName
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )

        do {
            try await UNUserNotificationCenter.current().add(request)
        } catch {
            errorLogger.logWarning("Failed to show notification: \(error.localizedDescription)")
        }
    }
}
