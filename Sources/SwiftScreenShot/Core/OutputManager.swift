//
//  OutputManager.swift
//  SwiftScreenShot
//
//  Output manager for clipboard and file saving
//

import AppKit
import UserNotifications

class OutputManager {
    private let settings: ScreenshotSettings
    private let imageProcessor = ImageProcessor()

    init(settings: ScreenshotSettings) {
        self.settings = settings
    }

    /// Process screenshot output
    func processScreenshot(_ image: NSImage) {
        // 1. Always copy to clipboard
        copyToClipboard(image)

        // 2. Save to file if enabled in settings
        if settings.shouldSaveToFile {
            saveToFile(image)
        }
    }

    /// Copy image to clipboard
    private func copyToClipboard(_ image: NSImage) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.writeObjects([image])
    }

    /// Save image to file
    private func saveToFile(_ image: NSImage) {
        guard let savePath = settings.savePath else { return }

        // Generate filename with timestamp
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd_HHmmss"
        let timestamp = formatter.string(from: Date())
        let fileName = "Screenshot_\(timestamp).\(settings.imageFormat.fileExtension)"

        let fileURL = savePath.appendingPathComponent(fileName)

        // Convert image format and save
        if let imageData = imageProcessor.imageData(from: image, format: settings.imageFormat) {
            do {
                try imageData.write(to: fileURL)
                showNotification(fileName: fileName, path: fileURL)
            } catch {
                print("Failed to save screenshot: \(error)")
            }
        }
    }

    /// Show save success notification
    private func showNotification(fileName: String, path: URL) {
        let content = UNMutableNotificationContent()
        content.title = "截图已保存"
        content.body = fileName
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Failed to show notification: \(error)")
            }
        }
    }
}
