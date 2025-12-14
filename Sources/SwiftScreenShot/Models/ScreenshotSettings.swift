//
//  ScreenshotSettings.swift
//  SwiftScreenShot
//
//  Settings management with UserDefaults persistence
//

import Foundation
import ServiceManagement

class ScreenshotSettings: ObservableObject {
    @Published var shouldSaveToFile: Bool {
        didSet { UserDefaults.standard.set(shouldSaveToFile, forKey: "shouldSaveToFile") }
    }

    @Published var savePath: URL? {
        didSet {
            if let path = savePath {
                UserDefaults.standard.set(path.path, forKey: "savePath")
            }
        }
    }

    @Published var imageFormat: ImageFormat {
        didSet { UserDefaults.standard.set(imageFormat.rawValue, forKey: "imageFormat") }
    }

    @Published var launchAtLogin: Bool {
        didSet {
            UserDefaults.standard.set(launchAtLogin, forKey: "launchAtLogin")
            configureLaunchAtLogin(launchAtLogin)
        }
    }

    @Published var playSoundOnCapture: Bool {
        didSet { UserDefaults.standard.set(playSoundOnCapture, forKey: "playSoundOnCapture") }
    }

    @Published var defaultDelayTime: Int {
        didSet { UserDefaults.standard.set(defaultDelayTime, forKey: "defaultDelayTime") }
    }

    @Published var autoEditAfterCapture: Bool {
        didSet { UserDefaults.standard.set(autoEditAfterCapture, forKey: "autoEditAfterCapture") }
    }

    // History settings
    @Published var historyMaxCount: Int {
        didSet { UserDefaults.standard.set(historyMaxCount, forKey: "historyMaxCount") }
    }

    @Published var autoSaveToHistory: Bool {
        didSet { UserDefaults.standard.set(autoSaveToHistory, forKey: "autoSaveToHistory") }
    }

    @Published var historyStoragePath: String {
        didSet { UserDefaults.standard.set(historyStoragePath, forKey: "historyStoragePath") }
    }

    // Error Recovery settings
    @Published var autoRetryEnabled: Bool {
        didSet { UserDefaults.standard.set(autoRetryEnabled, forKey: "autoRetryEnabled") }
    }

    @Published var maxRetryAttempts: Int {
        didSet {
            UserDefaults.standard.set(maxRetryAttempts, forKey: "maxRetryAttempts")
            updateRetryConfiguration()
        }
    }

    @Published var retryIntervalMultiplier: Double {
        didSet {
            UserDefaults.standard.set(retryIntervalMultiplier, forKey: "retryIntervalMultiplier")
            updateRetryConfiguration()
        }
    }

    init() {
        self.shouldSaveToFile = UserDefaults.standard.bool(forKey: "shouldSaveToFile")

        if let pathString = UserDefaults.standard.string(forKey: "savePath") {
            self.savePath = URL(fileURLWithPath: pathString)
        } else {
            // Default to Desktop
            self.savePath = FileManager.default.urls(
                for: .desktopDirectory,
                in: .userDomainMask
            ).first
        }

        let formatRaw = UserDefaults.standard.string(forKey: "imageFormat") ?? "png"
        self.imageFormat = ImageFormat(rawValue: formatRaw) ?? .png

        self.launchAtLogin = UserDefaults.standard.bool(forKey: "launchAtLogin")

        // Default to true for sound feedback
        if UserDefaults.standard.object(forKey: "playSoundOnCapture") == nil {
            self.playSoundOnCapture = true
            UserDefaults.standard.set(true, forKey: "playSoundOnCapture")
        } else {
            self.playSoundOnCapture = UserDefaults.standard.bool(forKey: "playSoundOnCapture")
        }

        // Default delay time (3 seconds)
        if UserDefaults.standard.object(forKey: "defaultDelayTime") == nil {
            self.defaultDelayTime = 3
            UserDefaults.standard.set(3, forKey: "defaultDelayTime")
        } else {
            self.defaultDelayTime = UserDefaults.standard.integer(forKey: "defaultDelayTime")
        }

        // Default to false for auto edit after capture
        if UserDefaults.standard.object(forKey: "autoEditAfterCapture") == nil {
            self.autoEditAfterCapture = false
            UserDefaults.standard.set(false, forKey: "autoEditAfterCapture")
        } else {
            self.autoEditAfterCapture = UserDefaults.standard.bool(forKey: "autoEditAfterCapture")
        }

        // History settings
        // Default history max count to 20
        if UserDefaults.standard.object(forKey: "historyMaxCount") == nil {
            self.historyMaxCount = 20
            UserDefaults.standard.set(20, forKey: "historyMaxCount")
        } else {
            self.historyMaxCount = UserDefaults.standard.integer(forKey: "historyMaxCount")
        }

        // Default to true for auto save to history
        if UserDefaults.standard.object(forKey: "autoSaveToHistory") == nil {
            self.autoSaveToHistory = true
            UserDefaults.standard.set(true, forKey: "autoSaveToHistory")
        } else {
            self.autoSaveToHistory = UserDefaults.standard.bool(forKey: "autoSaveToHistory")
        }

        // Default history storage path (empty means use default)
        self.historyStoragePath = UserDefaults.standard.string(forKey: "historyStoragePath") ?? ""

        // Error Recovery settings
        // Default to true for auto retry
        if UserDefaults.standard.object(forKey: "autoRetryEnabled") == nil {
            self.autoRetryEnabled = true
            UserDefaults.standard.set(true, forKey: "autoRetryEnabled")
        } else {
            self.autoRetryEnabled = UserDefaults.standard.bool(forKey: "autoRetryEnabled")
        }

        // Default to 3 retry attempts
        if UserDefaults.standard.object(forKey: "maxRetryAttempts") == nil {
            self.maxRetryAttempts = 3
            UserDefaults.standard.set(3, forKey: "maxRetryAttempts")
        } else {
            self.maxRetryAttempts = UserDefaults.standard.integer(forKey: "maxRetryAttempts")
        }

        // Default to 1.0 retry interval multiplier (0.5s, 1s, 2s)
        if UserDefaults.standard.object(forKey: "retryIntervalMultiplier") == nil {
            self.retryIntervalMultiplier = 1.0
            UserDefaults.standard.set(1.0, forKey: "retryIntervalMultiplier")
        } else {
            self.retryIntervalMultiplier = UserDefaults.standard.double(forKey: "retryIntervalMultiplier")
        }
    }

    private func updateRetryConfiguration() {
        let baseDelays = [0.5, 1.0, 2.0]
        let adjustedDelays = baseDelays.map { $0 * retryIntervalMultiplier }

        let config = RetryConfiguration(
            maxAttempts: maxRetryAttempts,
            delays: adjustedDelays,
            enabled: autoRetryEnabled
        )

        ErrorRecoveryManager.shared.updateRetryConfiguration(config)
    }

    private func configureLaunchAtLogin(_ enabled: Bool) {
        if #available(macOS 13.0, *) {
            let service = SMAppService.mainApp
            do {
                if enabled {
                    if service.status == .notRegistered {
                        try service.register()
                    }
                } else {
                    if service.status == .enabled {
                        try service.unregister()
                    }
                }
            } catch {
                print("Failed to configure launch at login: \(error)")
            }
        }
    }
}
