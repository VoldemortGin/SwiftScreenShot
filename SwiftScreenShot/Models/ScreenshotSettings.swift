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
