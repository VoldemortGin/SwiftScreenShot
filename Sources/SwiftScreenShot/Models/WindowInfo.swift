//
//  WindowInfo.swift
//  SwiftScreenShot
//
//  Model for storing window information
//

import Foundation
import CoreGraphics

/// Represents information about a window on the screen
struct WindowInfo {
    /// Window ID (CGWindowID)
    let windowID: CGWindowID

    /// Window bounds in screen coordinates
    let bounds: CGRect

    /// Window name/title
    let name: String?

    /// Owner name (application name)
    let ownerName: String?

    /// Window layer
    let layer: Int

    /// Whether this window is on screen
    let isOnScreen: Bool

    /// Alpha value of the window
    let alpha: CGFloat

    /// Initialize from CGWindow dictionary
    init?(from windowDict: [CFString: Any]) {
        guard let windowID = windowDict[kCGWindowNumber] as? CGWindowID,
              let boundsDict = windowDict[kCGWindowBounds] as? [CFString: Any] else {
            return nil
        }

        self.windowID = windowID

        // Parse bounds
        if let x = boundsDict["X" as CFString] as? CGFloat,
           let y = boundsDict["Y" as CFString] as? CGFloat,
           let width = boundsDict["Width" as CFString] as? CGFloat,
           let height = boundsDict["Height" as CFString] as? CGFloat {
            self.bounds = CGRect(x: x, y: y, width: width, height: height)
        } else {
            return nil
        }

        self.name = windowDict[kCGWindowName] as? String
        self.ownerName = windowDict[kCGWindowOwnerName] as? String
        self.layer = windowDict[kCGWindowLayer] as? Int ?? 0
        self.isOnScreen = windowDict[kCGWindowIsOnscreen] as? Bool ?? false
        self.alpha = windowDict[kCGWindowAlpha] as? CGFloat ?? 1.0
    }

    /// Check if a point is inside this window's bounds
    func contains(point: CGPoint) -> Bool {
        return bounds.contains(point)
    }

    /// Check if this window is valid for screenshot
    /// (on screen, visible, has reasonable size)
    var isValidForScreenshot: Bool {
        return isOnScreen &&
               alpha > 0.1 &&
               bounds.width > 50 &&
               bounds.height > 50 &&
               layer >= 0
    }
}

extension WindowInfo: CustomStringConvertible {
    var description: String {
        let title = name ?? "Untitled"
        let owner = ownerName ?? "Unknown"
        return "\(owner): \(title) [\(Int(bounds.width))×\(Int(bounds.height))]"
    }
}
