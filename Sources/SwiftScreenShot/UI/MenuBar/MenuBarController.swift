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
    private var settings: ScreenshotSettings?

    // Menu item references for dynamic updates
    private var regionScreenshotMenuItem: NSMenuItem?
    private var fullScreenshotMenuItem: NSMenuItem?
    private var windowScreenshotMenuItem: NSMenuItem?

    init(settings: ScreenshotSettings? = nil) {
        self.settings = settings
        setupStatusItem()
        setupMenu()
        setupNotificationObservers()
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
        // Region screenshot menu item
        regionScreenshotMenuItem = NSMenuItem(
            title: getRegionScreenshotTitle(),
            action: #selector(takeRegionScreenshot),
            keyEquivalent: ""
        )
        regionScreenshotMenuItem?.target = self
        if let item = regionScreenshotMenuItem {
            menu.addItem(item)
        }

        // Full screen screenshot menu item
        fullScreenshotMenuItem = NSMenuItem(
            title: getFullScreenshotTitle(),
            action: #selector(takeFullScreenshot),
            keyEquivalent: ""
        )
        fullScreenshotMenuItem?.target = self
        if let item = fullScreenshotMenuItem {
            menu.addItem(item)
        }

        // Window screenshot menu item
        windowScreenshotMenuItem = NSMenuItem(
            title: getWindowScreenshotTitle(),
            action: #selector(takeWindowScreenshot),
            keyEquivalent: ""
        )
        windowScreenshotMenuItem?.target = self
        if let item = windowScreenshotMenuItem {
            menu.addItem(item)
        }

        menu.addItem(NSMenuItem.separator())

        // Delayed Screenshot submenu
        let delayedScreenshotItem = NSMenuItem(
            title: "延时截图",
            action: nil,
            keyEquivalent: ""
        )
        let delayedSubmenu = NSMenu()

        // Fullscreen delayed screenshots
        let delayed3Full = NSMenuItem(
            title: "3秒后全屏截图",
            action: #selector(delayedFullScreen3),
            keyEquivalent: ""
        )
        delayed3Full.target = self
        delayedSubmenu.addItem(delayed3Full)

        let delayed5Full = NSMenuItem(
            title: "5秒后全屏截图",
            action: #selector(delayedFullScreen5),
            keyEquivalent: ""
        )
        delayed5Full.target = self
        delayedSubmenu.addItem(delayed5Full)

        let delayed10Full = NSMenuItem(
            title: "10秒后全屏截图",
            action: #selector(delayedFullScreen10),
            keyEquivalent: ""
        )
        delayed10Full.target = self
        delayedSubmenu.addItem(delayed10Full)

        delayedSubmenu.addItem(NSMenuItem.separator())

        // Region delayed screenshots
        let delayed3Region = NSMenuItem(
            title: "3秒后区域截图",
            action: #selector(delayedRegion3),
            keyEquivalent: ""
        )
        delayed3Region.target = self
        delayedSubmenu.addItem(delayed3Region)

        let delayed5Region = NSMenuItem(
            title: "5秒后区域截图",
            action: #selector(delayedRegion5),
            keyEquivalent: ""
        )
        delayed5Region.target = self
        delayedSubmenu.addItem(delayed5Region)

        let delayed10Region = NSMenuItem(
            title: "10秒后区域截图",
            action: #selector(delayedRegion10),
            keyEquivalent: ""
        )
        delayed10Region.target = self
        delayedSubmenu.addItem(delayed10Region)

        delayedScreenshotItem.submenu = delayedSubmenu
        menu.addItem(delayedScreenshotItem)

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

    @objc private func takeRegionScreenshot() {
        NotificationCenter.default.post(name: .triggerScreenshot, object: nil)
    }

    @objc private func takeFullScreenshot() {
        NotificationCenter.default.post(name: .triggerFullScreenshot, object: nil)
    }

    @objc private func takeWindowScreenshot() {
        NotificationCenter.default.post(name: .triggerWindowScreenshot, object: nil)
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

    @objc private func openSettings() {
        NotificationCenter.default.post(name: .openSettings, object: nil)
    }

    @objc private func quitApp() {
        NSApplication.shared.terminate(nil)
    }

    // MARK: - Notification Observers

    private func setupNotificationObservers() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleHotKeysDidChange),
            name: .hotKeysDidChange,
            object: nil
        )
    }

    @objc private func handleHotKeysDidChange() {
        updateMenuItemTitles()
    }

    // MARK: - Menu Title Helpers

    private func getRegionScreenshotTitle() -> String {
        if let hotKey = settings?.regionScreenshotHotKey {
            return "区域截图 (\(hotKey.displayString))"
        }
        return "区域截图 (⌃⌘A)"
    }

    private func getFullScreenshotTitle() -> String {
        if let hotKey = settings?.fullScreenshotHotKey {
            return "全屏截图 (\(hotKey.displayString))"
        }
        return "全屏截图 (⇧⌘3)"
    }

    private func getWindowScreenshotTitle() -> String {
        if let hotKey = settings?.windowScreenshotHotKey {
            return "窗口截图 (\(hotKey.displayString))"
        }
        return "窗口截图 (⌃⌘W)"
    }

    private func updateMenuItemTitles() {
        regionScreenshotMenuItem?.title = getRegionScreenshotTitle()
        fullScreenshotMenuItem?.title = getFullScreenshotTitle()
        windowScreenshotMenuItem?.title = getWindowScreenshotTitle()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}
