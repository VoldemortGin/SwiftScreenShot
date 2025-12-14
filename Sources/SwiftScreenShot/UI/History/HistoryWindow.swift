//
//  HistoryWindow.swift
//  SwiftScreenShot
//
//  History window for screenshot management
//

import AppKit
import SwiftUI

class HistoryWindow: NSWindow {
    init() {
        super.init(
            contentRect: NSRect(x: 0, y: 0, width: 900, height: 650),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )

        self.title = "截图历史"
        self.center()
        self.isReleasedWhenClosed = false
        self.contentView = NSHostingView(rootView: HistoryView())

        // Set minimum window size
        self.minSize = NSSize(width: 600, height: 400)
    }

    func show() {
        self.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}
