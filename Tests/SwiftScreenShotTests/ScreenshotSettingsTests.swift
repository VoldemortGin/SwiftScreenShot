//
//  ScreenshotSettingsTests.swift
//  SwiftScreenShot
//
//  Unit tests for ScreenshotSettings class
//

import XCTest
import Carbon
@testable import SwiftScreenShot

final class ScreenshotSettingsTests: XCTestCase {

    var settings: ScreenshotSettings!

    override func setUp() {
        super.setUp()
        // Clean up UserDefaults before each test
        let defaults = UserDefaults.standard
        defaults.removeObject(forKey: "shouldSaveToFile")
        defaults.removeObject(forKey: "savePath")
        defaults.removeObject(forKey: "imageFormat")
        defaults.removeObject(forKey: "launchAtLogin")
        defaults.removeObject(forKey: "playSoundOnCapture")
        defaults.removeObject(forKey: "regionScreenshotHotKey")
        defaults.removeObject(forKey: "fullScreenshotHotKey")

        settings = ScreenshotSettings()
    }

    override func tearDown() {
        settings = nil
        super.tearDown()
    }

    func testDefaultShouldSaveToFile() {
        XCTAssertFalse(settings.shouldSaveToFile, "Default shouldSaveToFile should be false")
    }

    func testDefaultSavePath() {
        let desktopURL = FileManager.default.urls(
            for: .desktopDirectory,
            in: .userDomainMask
        ).first

        XCTAssertEqual(settings.savePath, desktopURL, "Default save path should be Desktop")
    }

    func testDefaultImageFormat() {
        if case .png = settings.imageFormat {
            // Test passes
        } else {
            XCTFail("Default image format should be PNG")
        }
    }

    func testShouldSaveToFilePersistence() {
        settings.shouldSaveToFile = true

        let savedValue = UserDefaults.standard.bool(forKey: "shouldSaveToFile")
        XCTAssertTrue(savedValue, "shouldSaveToFile should be persisted to UserDefaults")
    }

    func testSavePathPersistence() {
        let testPath = URL(fileURLWithPath: "/tmp/screenshots")
        settings.savePath = testPath

        let savedPath = UserDefaults.standard.string(forKey: "savePath")
        XCTAssertEqual(savedPath, testPath.path, "savePath should be persisted to UserDefaults")
    }

    func testImageFormatPersistence() {
        settings.imageFormat = .jpeg(quality: 0.8)

        let savedFormat = UserDefaults.standard.string(forKey: "imageFormat")
        XCTAssertEqual(savedFormat, "jpeg", "imageFormat should be persisted to UserDefaults")
    }

    func testLoadSavedSettings() {
        // Set values in UserDefaults
        UserDefaults.standard.set(true, forKey: "shouldSaveToFile")
        UserDefaults.standard.set("/tmp/test", forKey: "savePath")
        UserDefaults.standard.set("jpeg", forKey: "imageFormat")

        // Create new settings instance
        let loadedSettings = ScreenshotSettings()

        XCTAssertTrue(loadedSettings.shouldSaveToFile)
        XCTAssertEqual(loadedSettings.savePath?.path, "/tmp/test")
        if case .jpeg = loadedSettings.imageFormat {
            // Test passes
        } else {
            XCTFail("Loaded format should be JPEG")
        }
    }

    func testDefaultPlaySoundOnCapture() {
        XCTAssertTrue(settings.playSoundOnCapture, "Default playSoundOnCapture should be true")
    }

    func testPlaySoundOnCapturePersistence() {
        settings.playSoundOnCapture = false

        let savedValue = UserDefaults.standard.bool(forKey: "playSoundOnCapture")
        XCTAssertFalse(savedValue, "playSoundOnCapture should be persisted to UserDefaults")

        settings.playSoundOnCapture = true
        let updatedValue = UserDefaults.standard.bool(forKey: "playSoundOnCapture")
        XCTAssertTrue(updatedValue, "Updated playSoundOnCapture should be persisted")
    }

    func testLoadSavedSoundSetting() {
        // Set sound setting to false
        UserDefaults.standard.set(false, forKey: "playSoundOnCapture")

        // Create new settings instance
        let loadedSettings = ScreenshotSettings()

        XCTAssertFalse(loadedSettings.playSoundOnCapture, "Loaded sound setting should be false")
    }

    // MARK: - HotKey Configuration Tests

    func testDefaultRegionScreenshotHotKey() {
        XCTAssertEqual(
            settings.regionScreenshotHotKey,
            HotKeyConfig.defaultRegionScreenshot,
            "Default region screenshot hotkey should match default config"
        )
    }

    func testDefaultFullScreenshotHotKey() {
        XCTAssertEqual(
            settings.fullScreenshotHotKey,
            HotKeyConfig.defaultFullScreenshot,
            "Default full screenshot hotkey should match default config"
        )
    }

    func testRegionScreenshotHotKeyPersistence() {
        let customHotKey = HotKeyConfig(keyCode: 1, modifiers: UInt32(cmdKey | controlKey))
        settings.regionScreenshotHotKey = customHotKey

        // Verify it's saved to UserDefaults
        guard let data = UserDefaults.standard.data(forKey: "regionScreenshotHotKey") else {
            XCTFail("HotKey data should be saved to UserDefaults")
            return
        }

        let decoder = JSONDecoder()
        let savedHotKey = try? decoder.decode(HotKeyConfig.self, from: data)

        XCTAssertNotNil(savedHotKey, "Should be able to decode saved hotkey")
        XCTAssertEqual(savedHotKey, customHotKey, "Saved hotkey should match custom hotkey")
    }

    func testFullScreenshotHotKeyPersistence() {
        let customHotKey = HotKeyConfig(keyCode: 7, modifiers: UInt32(cmdKey | shiftKey))
        settings.fullScreenshotHotKey = customHotKey

        // Verify it's saved to UserDefaults
        guard let data = UserDefaults.standard.data(forKey: "fullScreenshotHotKey") else {
            XCTFail("HotKey data should be saved to UserDefaults")
            return
        }

        let decoder = JSONDecoder()
        let savedHotKey = try? decoder.decode(HotKeyConfig.self, from: data)

        XCTAssertNotNil(savedHotKey, "Should be able to decode saved hotkey")
        XCTAssertEqual(savedHotKey, customHotKey, "Saved hotkey should match custom hotkey")
    }

    func testLoadSavedHotKeys() {
        // Create custom hotkeys
        let customRegionHotKey = HotKeyConfig(keyCode: 2, modifiers: UInt32(cmdKey | optionKey))
        let customFullHotKey = HotKeyConfig(keyCode: 8, modifiers: UInt32(cmdKey | shiftKey | controlKey))

        // Save to UserDefaults
        let encoder = JSONEncoder()
        if let regionData = try? encoder.encode(customRegionHotKey) {
            UserDefaults.standard.set(regionData, forKey: "regionScreenshotHotKey")
        }
        if let fullData = try? encoder.encode(customFullHotKey) {
            UserDefaults.standard.set(fullData, forKey: "fullScreenshotHotKey")
        }

        // Create new settings instance
        let loadedSettings = ScreenshotSettings()

        XCTAssertEqual(loadedSettings.regionScreenshotHotKey, customRegionHotKey)
        XCTAssertEqual(loadedSettings.fullScreenshotHotKey, customFullHotKey)
    }

    func testResetHotKey_Region() {
        // Set custom hotkey
        let customHotKey = HotKeyConfig(keyCode: 1, modifiers: UInt32(cmdKey))
        settings.regionScreenshotHotKey = customHotKey

        // Reset to default
        settings.resetHotKey(for: .regionScreenshot)

        XCTAssertEqual(
            settings.regionScreenshotHotKey,
            HotKeyConfig.defaultRegionScreenshot,
            "Region hotkey should be reset to default"
        )
    }

    func testResetHotKey_Full() {
        // Set custom hotkey
        let customHotKey = HotKeyConfig(keyCode: 1, modifiers: UInt32(cmdKey))
        settings.fullScreenshotHotKey = customHotKey

        // Reset to default
        settings.resetHotKey(for: .fullScreenshot)

        XCTAssertEqual(
            settings.fullScreenshotHotKey,
            HotKeyConfig.defaultFullScreenshot,
            "Full screenshot hotkey should be reset to default"
        )
    }

    func testResetAllHotKeys() {
        // Set custom hotkeys
        settings.regionScreenshotHotKey = HotKeyConfig(keyCode: 1, modifiers: UInt32(cmdKey))
        settings.fullScreenshotHotKey = HotKeyConfig(keyCode: 2, modifiers: UInt32(shiftKey))

        // Reset all
        settings.resetAllHotKeys()

        XCTAssertEqual(settings.regionScreenshotHotKey, HotKeyConfig.defaultRegionScreenshot)
        XCTAssertEqual(settings.fullScreenshotHotKey, HotKeyConfig.defaultFullScreenshot)
    }

    func testHotKeyChangeNotification_Region() {
        let expectation = XCTestExpectation(description: "HotKey change notification")

        let observer = NotificationCenter.default.addObserver(
            forName: .hotKeysDidChange,
            object: nil,
            queue: .main
        ) { _ in
            expectation.fulfill()
        }

        settings.regionScreenshotHotKey = HotKeyConfig(keyCode: 1, modifiers: UInt32(cmdKey))

        wait(for: [expectation], timeout: 1.0)
        NotificationCenter.default.removeObserver(observer)
    }

    func testHotKeyChangeNotification_Full() {
        let expectation = XCTestExpectation(description: "HotKey change notification")

        let observer = NotificationCenter.default.addObserver(
            forName: .hotKeysDidChange,
            object: nil,
            queue: .main
        ) { _ in
            expectation.fulfill()
        }

        settings.fullScreenshotHotKey = HotKeyConfig(keyCode: 2, modifiers: UInt32(shiftKey))

        wait(for: [expectation], timeout: 1.0)
        NotificationCenter.default.removeObserver(observer)
    }
}
