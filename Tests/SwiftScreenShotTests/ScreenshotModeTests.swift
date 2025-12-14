//
//  ScreenshotModeTests.swift
//  SwiftScreenShotTests
//
//  Tests for screenshot mode functionality
//

import XCTest
@testable import SwiftScreenShot

final class ScreenshotModeTests: XCTestCase {

    func testFullScreenCaptureModeRawValues() {
        XCTAssertEqual(FullScreenCaptureMode.mainDisplay.rawValue, "main")
        XCTAssertEqual(FullScreenCaptureMode.currentScreen.rawValue, "current")
        XCTAssertEqual(FullScreenCaptureMode.allDisplays.rawValue, "all")
    }

    func testFullScreenCaptureModeDisplayNames() {
        XCTAssertEqual(FullScreenCaptureMode.mainDisplay.displayName, "主显示器")
        XCTAssertEqual(FullScreenCaptureMode.currentScreen.displayName, "当前屏幕")
        XCTAssertEqual(FullScreenCaptureMode.allDisplays.displayName, "所有屏幕")
    }

    func testFullScreenCaptureModeInitFromRawValue() {
        XCTAssertEqual(FullScreenCaptureMode(rawValue: "main"), .mainDisplay)
        XCTAssertEqual(FullScreenCaptureMode(rawValue: "current"), .currentScreen)
        XCTAssertEqual(FullScreenCaptureMode(rawValue: "all"), .allDisplays)
        XCTAssertNil(FullScreenCaptureMode(rawValue: "invalid"))
    }

    func testScreenshotSettingsDefaultFullScreenMode() {
        let settings = ScreenshotSettings()
        // Default should be current screen
        XCTAssertEqual(settings.fullScreenCaptureMode, .currentScreen)
    }

    func testScreenshotSettingsFullScreenModePersistence() {
        let settings = ScreenshotSettings()

        // Test main display mode
        settings.fullScreenCaptureMode = .mainDisplay
        XCTAssertEqual(
            UserDefaults.standard.string(forKey: "fullScreenCaptureMode"),
            "main"
        )

        // Test all displays mode
        settings.fullScreenCaptureMode = .allDisplays
        XCTAssertEqual(
            UserDefaults.standard.string(forKey: "fullScreenCaptureMode"),
            "all"
        )

        // Cleanup
        UserDefaults.standard.removeObject(forKey: "fullScreenCaptureMode")
    }
}
