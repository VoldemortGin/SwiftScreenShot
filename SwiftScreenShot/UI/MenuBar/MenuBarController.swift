//
//  MenuBarController.swift
//  SwiftScreenShot
//
//  Menu bar controller for status bar icon and menu
//

import AppKit

class MenuBarController {
    private var statusItem: NSStatusItem?
    private let menu = NSMenu()

    init() {
        setupStatusItem()
        setupMenu()
    }

    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(
            withLength: NSStatusItem.squareLength
        )

        if let button = statusItem?.button {
            // Set icon (using SF Symbol)
            button.image = NSImage(
                systemSymbolName: "camera.viewfinder",
                accessibilityDescription: "截图"
            )
        }

        statusItem?.menu = menu
    }

    private func setupMenu() {
        // Screenshot menu item
        let screenshotItem = NSMenuItem(
            title: "截图 (⌃⌘A)",
            action: #selector(takeScreenshot),
            keyEquivalent: ""
        )
        screenshotItem.target = self
        menu.addItem(screenshotItem)

        menu.addItem(NSMenuItem.separator())

        // Delayed Screenshot submenu
        let delayedScreenshotItem = NSMenuItem(
            title: "延时截图",
            action: nil,
            keyEquivalent: ""
        )
        let delayedSubmenu = NSMenu()

        // Fullscreen delayed screenshots
        delayedSubmenu.addItem(NSMenuItem(
            title: "3秒后全屏截图",
            action: #selector(delayedFullScreen3),
            keyEquivalent: ""
        )).target = self

        delayedSubmenu.addItem(NSMenuItem(
            title: "5秒后全屏截图",
            action: #selector(delayedFullScreen5),
            keyEquivalent: ""
        )).target = self

        delayedSubmenu.addItem(NSMenuItem(
            title: "10秒后全屏截图",
            action: #selector(delayedFullScreen10),
            keyEquivalent: ""
        )).target = self

        delayedSubmenu.addItem(NSMenuItem.separator())

        // Region delayed screenshots
        delayedSubmenu.addItem(NSMenuItem(
            title: "3秒后区域截图",
            action: #selector(delayedRegion3),
            keyEquivalent: ""
        )).target = self

        delayedSubmenu.addItem(NSMenuItem(
            title: "5秒后区域截图",
            action: #selector(delayedRegion5),
            keyEquivalent: ""
        )).target = self

        delayedSubmenu.addItem(NSMenuItem(
            title: "10秒后区域截图",
            action: #selector(delayedRegion10),
            keyEquivalent: ""
        )).target = self

        delayedScreenshotItem.submenu = delayedSubmenu
        menu.addItem(delayedScreenshotItem)

        menu.addItem(NSMenuItem.separator())

        // History menu item
        let historyItem = NSMenuItem(
            title: "截图历史 (⌘H)",
            action: #selector(openHistory),
            keyEquivalent: ""
        )
        historyItem.target = self
        menu.addItem(historyItem)

        menu.addItem(NSMenuItem.separator())

        // Settings menu item
        let settingsItem = NSMenuItem(
            title: "设置...",
            action: #selector(openSettings),
            keyEquivalent: ","
        )
        settingsItem.target = self
        menu.addItem(settingsItem)

        menu.addItem(NSMenuItem.separator())

        // Quit menu item
        let quitItem = NSMenuItem(
            title: "退出",
            action: #selector(quitApp),
            keyEquivalent: "q"
        )
        quitItem.target = self
        menu.addItem(quitItem)
    }

    @objc private func takeScreenshot() {
        NotificationCenter.default.post(name: .triggerScreenshot, object: nil)
    }

    // MARK: - Delayed Fullscreen Actions

    @objc private func delayedFullScreen3() {
        NotificationCenter.default.post(
            name: .triggerDelayedScreenshot,
            object: ["delay": 3, "mode": "fullScreen"]
        )
    }

    @objc private func delayedFullScreen5() {
        NotificationCenter.default.post(
            name: .triggerDelayedScreenshot,
            object: ["delay": 5, "mode": "fullScreen"]
        )
    }

    @objc private func delayedFullScreen10() {
        NotificationCenter.default.post(
            name: .triggerDelayedScreenshot,
            object: ["delay": 10, "mode": "fullScreen"]
        )
    }

    // MARK: - Delayed Region Actions

    @objc private func delayedRegion3() {
        NotificationCenter.default.post(
            name: .triggerDelayedScreenshot,
            object: ["delay": 3, "mode": "region"]
        )
    }

    @objc private func delayedRegion5() {
        NotificationCenter.default.post(
            name: .triggerDelayedScreenshot,
            object: ["delay": 5, "mode": "region"]
        )
    }

    @objc private func delayedRegion10() {
        NotificationCenter.default.post(
            name: .triggerDelayedScreenshot,
            object: ["delay": 10, "mode": "region"]
        )
    }

    @objc private func openHistory() {
        NotificationCenter.default.post(name: .openHistory, object: nil)
    }

    @objc private func openSettings() {
        NotificationCenter.default.post(name: .openSettings, object: nil)
    }

    @objc private func quitApp() {
        NSApplication.shared.terminate(nil)
    }
}
