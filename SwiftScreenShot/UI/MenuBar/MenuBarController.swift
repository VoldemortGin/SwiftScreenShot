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

    @objc private func openSettings() {
        NotificationCenter.default.post(name: .openSettings, object: nil)
    }

    @objc private func quitApp() {
        NSApplication.shared.terminate(nil)
    }
}
