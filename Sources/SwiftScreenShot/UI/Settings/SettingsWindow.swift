//
//  SettingsWindow.swift
//  SwiftScreenShot
//
//  Settings window controller
//

import SwiftUI
import AppKit

class SettingsWindowController: NSWindowController {
    convenience init(settings: ScreenshotSettings) {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 500, height: 400),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )

        window.title = "SwiftScreenShot 设置"
        window.center()
        window.contentView = NSHostingView(rootView: SettingsView(settings: settings))

        self.init(window: window)
    }

    func show() {
        window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}
