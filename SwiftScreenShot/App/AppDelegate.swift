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
    private var historyWindow: HistoryWindow?
    private var selectionWindow: SelectionWindow?
    private var editorWindow: EditorWindow?

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Request notification permission
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, error in
            if let error = error {
                print("Failed to request notification permission: \(error)")
            }
        }

        // Check screen recording permission
        if !PermissionManager.checkScreenRecordingPermission() {
            PermissionManager.requestScreenRecordingPermission()
            PermissionManager.showPermissionAlert()
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
        menuBarController = MenuBarController()
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
            selector: #selector(handleOpenSettings),
            name: .openSettings,
            object: nil
        )

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleOpenHistory),
            name: .openHistory,
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
            selector: #selector(handleOpenEditor(_:)),
            name: .openEditor,
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

        // Register Ctrl+Cmd+A for screenshot (keyCode 0 = 'A')
        hotKeyManager.register(key: 0, modifiers: UInt32(cmdKey | controlKey), id: 1) { [weak self] in
            self?.handleTriggerScreenshot()
        }

        // Register Cmd+H for history (keyCode 4 = 'H')
        hotKeyManager.register(key: 4, modifiers: UInt32(cmdKey), id: 2) { [weak self] in
            self?.handleOpenHistory()
        }
    }

    @objc private func handleTriggerScreenshot() {
        Task {
            await startScreenshotProcess()
        }
    }

    @objc private func handleOpenSettings() {
        if settingsWindowController == nil {
            settingsWindowController = SettingsWindowController(settings: settings)
        }
        settingsWindowController?.show()
    }

    @objc private func handleOpenHistory() {
        if historyWindow == nil {
            historyWindow = HistoryWindow()
        }
        historyWindow?.show()
    }

    @objc private func handleOpenEditor(_ notification: Notification) {
        guard let image = notification.object as? NSImage else { return }
        openEditor(with: image)
    }

    @objc private func handleDidCompleteSelection(_ notification: Notification) {
        guard let selectedRect = notification.object as? CGRect else { return }

        Task {
            await captureSelectedRegion(selectedRect)
        }
    }

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

    private func startScreenshotProcess() async {
        do {
            // Get the screen where the mouse cursor is
            guard let currentScreen = NSScreen.screens.first(where: { screen in
                NSMouseInRect(NSEvent.mouseLocation, screen.frame, false)
            }) ?? NSScreen.main else {
                print("No screen found")
                return
            }

            // Capture current screen for background preview
            let backgroundImage = try await screenshotEngine.captureCurrentScreen(for: currentScreen)

            // Show selection window
            await MainActor.run {
                selectionWindow = SelectionWindow(screen: currentScreen, backgroundImage: backgroundImage)
                selectionWindow?.makeKeyAndOrderFront(nil)
            }
        } catch {
            print("Failed to start screenshot process: \(error)")
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
                print("No display found")
                return
            }

            // Capture the selected region
            let screenshot = try await screenshotEngine.captureRegion(rect: rect, display: display)

            // Check if auto edit is enabled
            await MainActor.run {
                if settings.autoEditAfterCapture {
                    openEditor(with: screenshot)
                } else {
                    outputManager.processScreenshot(screenshot)
                }
            }
        } catch {
            print("Failed to capture screenshot: \(error)")
        }
    }

    private func executeDelayedScreenshot(mode: ScreenshotMode) {
        Task {
            switch mode {
            case .fullScreen:
                await captureFullScreen()
            case .region:
                await startScreenshotProcess()
            case .window:
                // Window capture not yet implemented, fallback to region
                await startScreenshotProcess()
            }
        }
    }

    private func captureFullScreen() async {
        do {
            let screenshot = try await screenshotEngine.captureMainDisplay()

            // Check if auto edit is enabled
            await MainActor.run {
                if settings.autoEditAfterCapture {
                    openEditor(with: screenshot)
                } else {
                    outputManager.processScreenshot(screenshot)
                }
            }
        } catch {
            print("Failed to capture fullscreen: \(error)")
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

    func applicationWillTerminate(_ notification: Notification) {
        hotKeyManager?.unregister()
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return false  // Keep running as menu bar app
    }
}
