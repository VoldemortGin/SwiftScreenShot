//
//  AppDelegate.swift
//  SwiftScreenShot
//
//  Application delegate for coordinating all components
//

import Cocoa
import Carbon
import ScreenCaptureKit
import UserNotifications

class AppDelegate: NSObject, NSApplicationDelegate {

    // Core components
    private var menuBarController: MenuBarController!
    private var hotKeyManager: HotKeyManager!
    private var screenshotEngine: ScreenshotEngine!
    private var outputManager: OutputManager!
    private var imageProcessor: ImageProcessor!
    private var settings: ScreenshotSettings!
    private var delayedScreenshotManager: DelayedScreenshotManager!

    // UI components
    private var settingsWindowController: SettingsWindowController?
    private var selectionWindow: SelectionWindow?
    private var editorWindow: EditorWindow?

    // Hotkey tracking
    private var regionScreenshotHotKeyID: UInt32?
    private var fullScreenshotHotKeyID: UInt32?
    private var windowScreenshotHotKeyID: UInt32?

    func applicationDidFinishLaunching(_ notification: Notification) {
        AppLogger.shared.info("Application started", category: .app)

        // Clean old logs on startup (keep last 7 days)
        AppLogger.shared.cleanOldLogs(keepLast: 7)

        // Request notification permission
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, error in
            if let error = error {
                AppLogger.shared.error("Failed to request notification permission", category: .app, error: error)
            } else if granted {
                AppLogger.shared.info("Notification permission granted", category: .app)
            } else {
                AppLogger.shared.warning("Notification permission denied", category: .app)
            }
        }

        // Check screen recording permission
        if !PermissionManager.checkScreenRecordingPermission() {
            AppLogger.shared.warning("Screen recording permission not granted", category: .permission)
            PermissionManager.requestScreenRecordingPermission()
            PermissionManager.showPermissionAlert()
        } else {
            AppLogger.shared.info("Screen recording permission granted", category: .permission)
        }

        // Initialize components
        initializeComponents()

        // Setup observers
        setupNotificationObservers()

        // Register global hotkey
        setupGlobalHotKey()
    }

    private func initializeComponents() {
        settings = ScreenshotSettings()
        screenshotEngine = ScreenshotEngine()
        imageProcessor = ImageProcessor()
        outputManager = OutputManager(settings: settings)
        menuBarController = MenuBarController(settings: settings)
        delayedScreenshotManager = DelayedScreenshotManager()

        // Setup delayed screenshot callback
        delayedScreenshotManager.onCountdownComplete = { [weak self] mode in
            self?.executeDelayedScreenshot(mode: mode)
        }
    }

    private func setupNotificationObservers() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleTriggerScreenshot),
            name: .triggerScreenshot,
            object: nil
        )

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleTriggerFullScreenshot),
            name: .triggerFullScreenshot,
            object: nil
        )

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleTriggerWindowScreenshot),
            name: .triggerWindowScreenshot,
            object: nil
        )

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleOpenSettings),
            name: .openSettings,
            object: nil
        )

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleDidCompleteSelection(_:)),
            name: .didCompleteSelection,
            object: nil
        )

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleDidCompleteWindowSelection(_:)),
            name: .didCompleteWindowSelection,
            object: nil
        )

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleHotKeysDidChange),
            name: .hotKeysDidChange,
            object: nil
        )

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleTriggerDelayedScreenshot(_:)),
            name: .triggerDelayedScreenshot,
            object: nil
        )

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleCancelDelayedScreenshot),
            name: .cancelDelayedScreenshot,
            object: nil
        )
    }

    private func setupGlobalHotKey() {
        hotKeyManager = HotKeyManager()

        // Set up failure handler for hotkey registration
        hotKeyManager.setRegistrationFailureHandler { [weak self] config, status in
            DispatchQueue.main.async {
                self?.showHotKeyRegistrationError(config: config, status: status)
            }
        }

        // Register hotkeys from settings
        registerHotKeys()
    }

    private func registerHotKeys() {
        // Unregister existing hotkeys
        if let regionID = regionScreenshotHotKeyID {
            hotKeyManager.unregister(id: regionID)
        }
        if let fullID = fullScreenshotHotKeyID {
            hotKeyManager.unregister(id: fullID)
        }
        if let windowID = windowScreenshotHotKeyID {
            hotKeyManager.unregister(id: windowID)
        }

        // Register region screenshot hotkey
        regionScreenshotHotKeyID = hotKeyManager.register(
            config: settings.regionScreenshotHotKey
        ) { [weak self] in
            self?.handleTriggerScreenshot()
        }

        // Register full screenshot hotkey
        fullScreenshotHotKeyID = hotKeyManager.register(
            config: settings.fullScreenshotHotKey
        ) { [weak self] in
            self?.handleTriggerFullScreenshot()
        }

        // Register window screenshot hotkey
        windowScreenshotHotKeyID = hotKeyManager.register(
            config: settings.windowScreenshotHotKey
        ) { [weak self] in
            self?.handleTriggerWindowScreenshot()
        }
    }

    @objc private func handleHotKeysDidChange() {
        AppLogger.shared.info("Hotkeys changed, re-registering", category: .hotkey)
        registerHotKeys()
    }

    private func showHotKeyRegistrationError(config: HotKeyConfig, status: OSStatus) {
        let alert = NSAlert()
        alert.messageText = "快捷键注册失败"
        alert.informativeText = """
        无法注册快捷键 \(config.displayString)。

        可能的原因：
        • 快捷键已被其他应用占用
        • 快捷键与系统功能冲突

        错误代码: \(status)

        请在设置中更换其他快捷键。
        """
        alert.alertStyle = .warning
        alert.addButton(withTitle: "打开设置")
        alert.addButton(withTitle: "取消")

        let response = alert.runModal()
        if response == .alertFirstButtonReturn {
            handleOpenSettings()
        }
    }

    @objc private func handleTriggerScreenshot() {
        Task {
            await startScreenshotProcess(mode: .region)
        }
    }

    @objc private func handleTriggerFullScreenshot() {
        Task {
            await captureFullScreen()
        }
    }

    @objc private func handleTriggerWindowScreenshot() {
        Task {
            await startScreenshotProcess(mode: .window)
        }
    }

    @objc private func handleOpenSettings() {
        if settingsWindowController == nil {
            settingsWindowController = SettingsWindowController(settings: settings)
        }
        settingsWindowController?.show()
    }

    @objc private func handleDidCompleteSelection(_ notification: Notification) {
        guard let selectedRect = notification.object as? CGRect else { return }

        Task {
            await captureSelectedRegion(selectedRect)
        }
    }

    @objc private func handleDidCompleteWindowSelection(_ notification: Notification) {
        guard let windowInfo = notification.object as? WindowInfo else { return }

        Task {
            await captureSelectedWindow(windowInfo)
        }
    }

    private func startScreenshotProcess(mode: ScreenshotMode) async {
        do {
            // Get the screen where the mouse cursor is
            guard let currentScreen = NSScreen.screens.first(where: { screen in
                NSMouseInRect(NSEvent.mouseLocation, screen.frame, false)
            }) ?? NSScreen.main else {
                AppLogger.shared.error("No screen found for screenshot", category: .screenshot)
                return
            }

            // Capture current screen for background preview
            let backgroundImage = try await screenshotEngine.captureCurrentScreen(for: currentScreen)

            // Show selection window
            await MainActor.run {
                selectionWindow = SelectionWindow(
                    screen: currentScreen,
                    backgroundImage: backgroundImage,
                    mode: mode
                )
                selectionWindow?.makeKeyAndOrderFront(nil)
            }
        } catch {
            AppLogger.shared.error("Failed to start screenshot process", category: .screenshot, error: error)
            if !PermissionManager.checkScreenRecordingPermission() {
                await MainActor.run {
                    PermissionManager.showPermissionAlert()
                }
            }
        }
    }

    private func captureSelectedRegion(_ rect: CGRect) async {
        do {
            // Get the appropriate display
            let displays = try await screenshotEngine.getDisplays()
            guard let display = displays.first else {
                AppLogger.shared.error("No display found for region capture", category: .screenshot)
                return
            }

            AppLogger.shared.debug("Capturing region: \(rect)", category: .screenshot)
            // Capture the selected region
            let screenshot = try await screenshotEngine.captureRegion(rect: rect, display: display)
            AppLogger.shared.info("Region screenshot captured successfully", category: .screenshot)

            // Check if auto edit is enabled
            await MainActor.run {
                if settings.autoEditAfterCapture {
                    AppLogger.shared.debug("Opening editor for region screenshot", category: .editor)
                    openEditor(with: screenshot)
                } else {
                    outputManager.processScreenshot(screenshot)
                }
            }
        } catch {
            AppLogger.shared.error("Failed to capture region screenshot", category: .screenshot, error: error)
        }
    }

    private func captureFullScreen() async {
        do {
            let screenshot: NSImage

            AppLogger.shared.debug("Capturing fullscreen with mode: \(settings.fullScreenCaptureMode)", category: .screenshot)
            // Capture based on user settings
            switch settings.fullScreenCaptureMode {
            case .mainDisplay:
                screenshot = try await screenshotEngine.captureMainDisplay()
            case .currentScreen:
                screenshot = try await screenshotEngine.captureCurrentDisplay()
            case .allDisplays:
                screenshot = try await screenshotEngine.captureAllDisplays()
            }
            AppLogger.shared.info("Fullscreen screenshot captured successfully", category: .screenshot)

            // Check if auto edit is enabled
            await MainActor.run {
                if settings.autoEditAfterCapture {
                    AppLogger.shared.debug("Opening editor for fullscreen screenshot", category: .editor)
                    openEditor(with: screenshot)
                } else {
                    outputManager.processScreenshot(screenshot)
                }
            }
        } catch {
            AppLogger.shared.error("Failed to capture fullscreen screenshot", category: .screenshot, error: error)
            if !PermissionManager.checkScreenRecordingPermission() {
                await MainActor.run {
                    PermissionManager.showPermissionAlert()
                }
            }
        }
    }

    private func captureSelectedWindow(_ windowInfo: WindowInfo) async {
        do {
            let windowName = windowInfo.name ?? "Untitled"
            AppLogger.shared.debug("Capturing window: \(windowName) (ID: \(windowInfo.windowID))", category: .screenshot)
            // Capture the window with settings
            let screenshot = try await screenshotEngine.captureWindow(
                windowInfo: windowInfo,
                includeShadow: settings.includeWindowShadow
            )
            AppLogger.shared.info("Window screenshot captured successfully: \(windowName)", category: .screenshot)

            // Check if auto edit is enabled
            await MainActor.run {
                if settings.autoEditAfterCapture {
                    AppLogger.shared.debug("Opening editor for window screenshot", category: .editor)
                    openEditor(with: screenshot)
                } else {
                    outputManager.processScreenshot(screenshot)
                }
            }
        } catch {
            AppLogger.shared.error("Failed to capture window screenshot", category: .screenshot, error: error)
            if !PermissionManager.checkScreenRecordingPermission() {
                await MainActor.run {
                    PermissionManager.showPermissionAlert()
                }
            }
        }
    }

    private func openEditor(with image: NSImage) {
        editorWindow = EditorWindow(image: image)

        editorWindow?.onComplete = { [weak self] editedImage in
            guard let self = self else { return }
            self.outputManager.processScreenshot(editedImage)
            self.editorWindow = nil
        }

        editorWindow?.onCancel = { [weak self] in
            self?.editorWindow = nil
        }
    }

    // MARK: - Delayed Screenshot Handlers

    @objc private func handleTriggerDelayedScreenshot(_ notification: Notification) {
        guard let info = notification.object as? [String: Any],
              let delay = info["delay"] as? Int,
              let modeString = info["mode"] as? String else {
            return
        }

        let mode: ScreenshotMode
        switch modeString {
        case "fullScreen":
            mode = .fullScreen
        case "region":
            mode = .region
        case "window":
            mode = .window
        default:
            mode = .region
        }

        delayedScreenshotManager.startDelayedScreenshot(delaySeconds: delay, mode: mode)
    }

    @objc private func handleCancelDelayedScreenshot() {
        delayedScreenshotManager.cancelDelayedScreenshot()
    }

    private func executeDelayedScreenshot(mode: ScreenshotMode) {
        Task {
            switch mode {
            case .fullScreen:
                await captureFullScreen()
            case .region:
                await startScreenshotProcess(mode: .region)
            case .window:
                await startScreenshotProcess(mode: .window)
            case .allScreens:
                // For delayed screenshot, allScreens is treated as fullScreen
                await captureFullScreen()
            }
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        AppLogger.shared.info("Application terminating", category: .app)
        hotKeyManager?.unregisterAll()
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return false  // Keep running as menu bar app
    }
}
