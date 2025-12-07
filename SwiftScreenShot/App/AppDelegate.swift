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

    // UI components
    private var settingsWindowController: SettingsWindowController?
    private var selectionWindow: SelectionWindow?

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
            selector: #selector(handleDidCompleteSelection(_:)),
            name: .didCompleteSelection,
            object: nil
        )
    }

    private func setupGlobalHotKey() {
        hotKeyManager = HotKeyManager()
        // Register Ctrl+Cmd+A (keyCode 0 = 'A', cmdKey + controlKey)
        hotKeyManager.register(key: 0, modifiers: UInt32(cmdKey | controlKey))
        hotKeyManager.onHotKeyPressed = { [weak self] in
            self?.handleTriggerScreenshot()
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

    @objc private func handleDidCompleteSelection(_ notification: Notification) {
        guard let selectedRect = notification.object as? CGRect else { return }

        Task {
            await captureSelectedRegion(selectedRect)
        }
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

            // Process output (clipboard + optional file save)
            await MainActor.run {
                outputManager.processScreenshot(screenshot)
            }
        } catch {
            print("Failed to capture screenshot: \(error)")
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        hotKeyManager?.unregister()
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return false  // Keep running as menu bar app
    }
}
