//
//  ScreenshotMode.swift
//  SwiftScreenShot
//
//  Screenshot mode definitions
//

import Foundation

/// Defines the different screenshot capture modes
enum ScreenshotMode {
    /// Region selection mode - user selects area on screen
    case region

    /// Full screen mode - captures entire screen without selection
    case fullScreen

    /// All screens mode - captures all connected displays
    case allScreens

    /// Window mode - captures a specific window
    case window
}

/// Defines which screen(s) to capture in fullscreen mode
enum FullScreenCaptureMode: String {
    /// Capture only the main display
    case mainDisplay = "main"

    /// Capture the screen where the cursor is located
    case currentScreen = "current"

    /// Capture all connected displays
    case allDisplays = "all"

    var displayName: String {
        switch self {
        case .mainDisplay:
            return "主显示器"
        case .currentScreen:
            return "当前屏幕"
        case .allDisplays:
            return "所有屏幕"
        }
    }
}
