//
//  PermissionManager.swift
//  SwiftScreenShot
//
//  Permission management for screen recording
//

import ScreenCaptureKit
import AppKit

class PermissionManager {

    /// Check screen recording permission status
    static func checkScreenRecordingPermission() -> Bool {
        if #available(macOS 10.15, *) {
            return CGPreflightScreenCaptureAccess()
        }
        return true
    }

    /// Request screen recording permission
    static func requestScreenRecordingPermission() {
        CGRequestScreenCaptureAccess()
    }

    /// Show permission alert dialog
    static func showPermissionAlert() {
        let alert = NSAlert()
        alert.messageText = "需要屏幕录制权限"
        alert.informativeText = """
        SwiftScreenShot 需要屏幕录制权限来实现截图功能。

        请在"系统设置 > 隐私与安全性 > 屏幕录制"中，
        勾选 SwiftScreenShot 并重启应用。
        """
        alert.alertStyle = .warning
        alert.addButton(withTitle: "打开系统设置")
        alert.addButton(withTitle: "稍后")

        let response = alert.runModal()

        if response == .alertFirstButtonReturn {
            openSystemPreferences()
        }
    }

    /// Open system preferences to screen recording settings
    private static func openSystemPreferences() {
        let url: URL

        if #available(macOS 13.0, *) {
            url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture")!
        } else {
            url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture")!
        }

        NSWorkspace.shared.open(url)
    }
}
