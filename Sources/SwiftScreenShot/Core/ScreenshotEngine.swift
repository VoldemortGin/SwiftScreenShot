//
//  ScreenshotEngine.swift
//  SwiftScreenShot
//
//  Screenshot engine using ScreenCaptureKit
//

import ScreenCaptureKit
import AppKit

enum ScreenshotError: Error {
    case noDisplay
    case permissionDenied
    case captureFailed
}

class ScreenshotEngine {

    /// Capture a specific region of the display
    func captureRegion(rect: CGRect, display: SCDisplay) async throws -> NSImage {
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
    }

    /// Get all available displays
    func getDisplays() async throws -> [SCDisplay] {
        let content = try await SCShareableContent.excludingDesktopWindows(
            false,
            onScreenWindowsOnly: true
        )
        return content.displays
    }

    /// Capture the main display fullscreen
    func captureMainDisplay() async throws -> NSImage {
        let displays = try await getDisplays()
        guard let mainDisplay = displays.first else {
            throw ScreenshotError.noDisplay
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
        let displays = try await getDisplays()

        // Find the matching display for the screen
        guard let display = displays.first(where: { display in
            display.width == Int(screen.frame.width * screen.backingScaleFactor)
        }) else {
            throw ScreenshotError.noDisplay
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
    }
}
