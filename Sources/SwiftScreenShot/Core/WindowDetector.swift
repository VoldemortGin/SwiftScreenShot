//
//  WindowDetector.swift
//  SwiftScreenShot
//
//  Detects and manages window information for window-based screenshots
//

import Foundation
import CoreGraphics
import ScreenCaptureKit

/// Detects and tracks windows on the screen
class WindowDetector {

    /// Get all windows on the screen
    /// - Parameter excludeDesktop: Whether to exclude desktop windows
    /// - Returns: Array of WindowInfo objects
    func getAllWindows(excludeDesktop: Bool = true) -> [WindowInfo] {
        let options: CGWindowListOption = excludeDesktop ?
            [.optionOnScreenOnly, .excludeDesktopElements] :
            [.optionOnScreenOnly]

        guard let windowList = CGWindowListCopyWindowInfo(options, kCGNullWindowID) as? [[CFString: Any]] else {
            AppLogger.shared.error("Failed to get window list from system", category: .window)
            return []
        }

        let windows = windowList.compactMap { WindowInfo(from: $0) }
            .filter { $0.isValidForScreenshot }
            .sorted { $0.layer > $1.layer }  // Higher layers first (topmost windows)

        AppLogger.shared.debug("Found \(windows.count) valid windows", category: .window)
        return windows
    }

    /// Find the window at a specific point
    /// - Parameter point: Point in screen coordinates
    /// - Returns: WindowInfo if a window is found at that point
    func windowAtPoint(_ point: CGPoint) -> WindowInfo? {
        let windows = getAllWindows()

        // Find the topmost window that contains the point
        let window = windows.first { window in
            window.contains(point: point)
        }

        if let window = window {
            let windowName = window.name ?? "Untitled"
            AppLogger.shared.debug("Window found at point (\(point.x), \(point.y)): \(windowName)", category: .window)
        } else {
            AppLogger.shared.debug("No window found at point (\(point.x), \(point.y))", category: .window)
        }

        return window
    }

    /// Get windows that intersect with a given rectangle
    /// - Parameter rect: Rectangle in screen coordinates
    /// - Returns: Array of WindowInfo objects that intersect with the rectangle
    func windowsIntersecting(_ rect: CGRect) -> [WindowInfo] {
        let windows = getAllWindows()

        return windows.filter { window in
            window.bounds.intersects(rect)
        }
    }

    /// Get window bounds with shadow padding
    /// - Parameters:
    ///   - windowID: The window ID
    ///   - includeShadow: Whether to include shadow area
    /// - Returns: Bounds with shadow if requested
    func getWindowBounds(windowID: CGWindowID, includeShadow: Bool) -> CGRect? {
        let options: CGWindowListOption = [.optionIncludingWindow]

        guard let windowList = CGWindowListCopyWindowInfo(options, windowID) as? [[CFString: Any]],
              let windowDict = windowList.first,
              let windowInfo = WindowInfo(from: windowDict) else {
            return nil
        }

        var bounds = windowInfo.bounds

        // Add shadow padding (approximate macOS window shadow)
        if includeShadow {
            let shadowPadding: CGFloat = 20.0
            bounds = bounds.insetBy(dx: -shadowPadding, dy: -shadowPadding)
        }

        return bounds
    }

    /// Get shareable windows using ScreenCaptureKit
    /// - Returns: Array of SCWindow objects
    func getShareableWindows() async throws -> [SCWindow] {
        let content = try await SCShareableContent.excludingDesktopWindows(
            false,
            onScreenWindowsOnly: true
        )
        return content.windows
    }

    /// Find SCWindow by window ID
    /// - Parameters:
    ///   - windowID: The CGWindowID to search for
    ///   - windows: Array of SCWindow objects to search in
    /// - Returns: Matching SCWindow if found
    func findSCWindow(byID windowID: CGWindowID, in windows: [SCWindow]) -> SCWindow? {
        return windows.first { $0.windowID == windowID }
    }

    /// Get the application name for a window
    /// - Parameter windowID: The window ID
    /// - Returns: Application name if available
    func getApplicationName(for windowID: CGWindowID) -> String? {
        let options: CGWindowListOption = [.optionIncludingWindow]

        guard let windowList = CGWindowListCopyWindowInfo(options, windowID) as? [[CFString: Any]],
              let windowDict = windowList.first else {
            return nil
        }

        return windowDict[kCGWindowOwnerName] as? String
    }
}
