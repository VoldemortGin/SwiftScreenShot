//
//  ScreenshotEngine.swift
//  SwiftScreenShot
//
//  Screenshot engine using ScreenCaptureKit with error recovery
//

import ScreenCaptureKit
import AppKit

enum ScreenshotError: Error {
    case noDisplay
    case permissionDenied
    case captureFailed
}

class ScreenshotEngine {
    private let errorRecoveryManager = ErrorRecoveryManager.shared
    private let errorLogger = ErrorLogger.shared

    /// Capture a specific region of the display with automatic retry
    func captureRegion(rect: CGRect, display: SCDisplay) async throws -> NSImage {
        let result = await errorRecoveryManager.executeWithRetry(
            operation: {
                try await self.performCapture(rect: rect, display: display)
            },
            onError: { error in
                self.errorLogger.logError(error, operationId: UUID().uuidString, attempt: 1)
            }
        )

        switch result {
        case .recovered:
            // Success - the operation already returned the image
            // We need to capture again since executeWithRetry doesn't return the value
            return try await performCapture(rect: rect, display: display)
        case .failed(let error), .userActionRequired(let error), .maxRetriesExceeded(let error):
            throw error
        }
    }

    /// Perform actual capture operation
    private func performCapture(rect: CGRect, display: SCDisplay) async throws -> NSImage {
        do {
            // Create screenshot configuration
            let filter = SCContentFilter(display: display, excludingWindows: [])

            let config = SCStreamConfiguration()
            config.width = Int(rect.width * CGFloat(display.width) / CGFloat(display.width))
            config.height = Int(rect.height * CGFloat(display.height) / CGFloat(display.height))
            config.sourceRect = rect
            config.scalesToFit = false
            config.showsCursor = false

            // Execute screenshot
            let image = try await SCScreenshotManager.captureImage(
                contentFilter: filter,
                configuration: config
            )

            // Convert to NSImage
            let nsImage = NSImage(cgImage: image, size: rect.size)
            return nsImage

        } catch {
            // Convert to RecoverableError
            throw convertToRecoverableError(error)
        }
    }

    /// Get all available displays
    func getDisplays() async throws -> [SCDisplay] {
        do {
            let content = try await SCShareableContent.excludingDesktopWindows(
                false,
                onScreenWindowsOnly: true
            )
            return content.displays
        } catch {
            throw convertToRecoverableError(error)
        }
    }

    /// Capture the main display fullscreen
    func captureMainDisplay() async throws -> NSImage {
        let displays = try await getDisplays()
        guard let mainDisplay = displays.first else {
            throw ScreenshotRecoverableError.captureFailed(reason: "No display available")
        }

        let rect = CGRect(
            x: 0,
            y: 0,
            width: CGFloat(mainDisplay.width),
            height: CGFloat(mainDisplay.height)
        )

        return try await captureRegion(rect: rect, display: mainDisplay)
    }

    /// Capture current screen for background preview
    func captureCurrentScreen(for screen: NSScreen) async throws -> NSImage {
        do {
            let displays = try await getDisplays()

            // Find the matching display for the screen
            guard let display = displays.first(where: { display in
                display.width == Int(screen.frame.width * screen.backingScaleFactor)
            }) else {
                throw ScreenshotRecoverableError.captureFailed(reason: "No matching display found")
            }

            let filter = SCContentFilter(display: display, excludingWindows: [])
            let config = SCStreamConfiguration()
            config.width = display.width
            config.height = display.height
            config.showsCursor = false

            let image = try await SCScreenshotManager.captureImage(
                contentFilter: filter,
                configuration: config
            )

            let nsImage = NSImage(cgImage: image, size: screen.frame.size)
            return nsImage

        } catch {
            throw convertToRecoverableError(error)
        }
    }

    /// Capture the current display where the cursor is located
    func captureCurrentDisplay() async throws -> NSImage {
        // Get the screen where the mouse cursor is
        guard let currentScreen = NSScreen.screens.first(where: { screen in
            NSMouseInRect(NSEvent.mouseLocation, screen.frame, false)
        }) ?? NSScreen.main else {
            throw ScreenshotRecoverableError.captureFailed(reason: "No screen found for cursor")
        }

        return try await captureCurrentScreen(for: currentScreen)
    }

    /// Capture all connected displays
    func captureAllDisplays() async throws -> NSImage {
        let displays = try await getDisplays()
        guard !displays.isEmpty else {
            throw ScreenshotRecoverableError.captureFailed(reason: "No displays available")
        }

        // Calculate total bounds for all displays
        let screens = NSScreen.screens
        var totalRect = CGRect.zero
        for screen in screens {
            totalRect = totalRect.union(screen.frame)
        }

        // Create a composite image
        let finalSize = NSSize(width: totalRect.width, height: totalRect.height)
        let compositeImage = NSImage(size: finalSize)

        compositeImage.lockFocus()
        defer { compositeImage.unlockFocus() }

        // Capture each display and composite them
        for (index, display) in displays.enumerated() {
            guard index < screens.count else { break }
            let screen = screens[index]

            let displayImage = try await captureCurrentScreen(for: screen)
            let destRect = NSRect(
                x: screen.frame.origin.x - totalRect.origin.x,
                y: screen.frame.origin.y - totalRect.origin.y,
                width: screen.frame.width,
                height: screen.frame.height
            )

            displayImage.draw(in: destRect)
        }

        return compositeImage
    }

    /// Capture a specific window
    func captureWindow(windowInfo: WindowInfo, includeShadow: Bool) async throws -> NSImage {
        do {
            let content = try await SCShareableContent.excludingDesktopWindows(
                false,
                onScreenWindowsOnly: true
            )

            // Find the window by ID
            guard let window = content.windows.first(where: { $0.windowID == windowInfo.windowID }) else {
                throw ScreenshotRecoverableError.captureFailed(reason: "Window not found")
            }

            let filter = SCContentFilter(desktopIndependentWindow: window)
            let config = SCStreamConfiguration()
            config.width = Int(window.frame.width) * 2  // Retina resolution
            config.height = Int(window.frame.height) * 2
            config.showsCursor = false

            let image = try await SCScreenshotManager.captureImage(
                contentFilter: filter,
                configuration: config
            )

            let nsImage = NSImage(
                cgImage: image,
                size: NSSize(width: window.frame.width, height: window.frame.height)
            )
            return nsImage

        } catch {
            throw convertToRecoverableError(error)
        }
    }

    // MARK: - Error Conversion

    private func convertToRecoverableError(_ error: Error) -> RecoverableError {
        // Check if already a RecoverableError
        if let recoverable = error as? RecoverableError {
            return recoverable
        }

        // Check for ScreenshotError
        if let screenshotError = error as? ScreenshotError {
            switch screenshotError {
            case .noDisplay:
                return ScreenshotRecoverableError.captureFailed(reason: "No display available")
            case .permissionDenied:
                return ScreenshotRecoverableError.permissionDenied
            case .captureFailed:
                return ScreenshotRecoverableError.captureFailed(reason: "Capture failed")
            }
        }

        // Check NSError for specific codes
        let nsError = error as NSError

        // Check for screen recording permission errors
        if nsError.domain == "com.apple.screencapturekit" {
            if nsError.code == -3801 { // Permission denied
                return ScreenshotRecoverableError.permissionDenied
            }
        }

        // System busy errors
        if nsError.code == NSFileReadTooLargeError || nsError.code == NSFileReadUnknownError {
            return ScreenshotRecoverableError.systemBusy(attempt: 1)
        }

        // Default to capture failed
        return ScreenshotRecoverableError.captureFailed(reason: error.localizedDescription)
    }
}
