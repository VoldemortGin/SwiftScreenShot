//
//  SoundManagerTests.swift
//  SwiftScreenShotTests
//
//  Tests for SoundManager functionality
//

import XCTest
@testable import SwiftScreenShot

final class SoundManagerTests: XCTestCase {
    var soundManager: SoundManager!

    override func setUp() {
        super.setUp()
        soundManager = SoundManager.shared
    }

    override func tearDown() {
        soundManager = nil
        super.tearDown()
    }

    func testSoundManagerSingleton() {
        let instance1 = SoundManager.shared
        let instance2 = SoundManager.shared

        XCTAssertTrue(instance1 === instance2, "SoundManager should be a singleton")
    }

    func testPlayCaptureDoesNotCrash() {
        // This test verifies that calling playCapture doesn't crash
        // We can't easily test if sound actually plays in unit tests
        XCTAssertNoThrow(soundManager.playCapture())
    }

    func testPlayCaptureIfEnabledWhenEnabled() {
        XCTAssertNoThrow(soundManager.playCaptureIfEnabled(enabled: true))
    }

    func testPlayCaptureIfEnabledWhenDisabled() {
        // When disabled, no sound should play (but shouldn't crash)
        XCTAssertNoThrow(soundManager.playCaptureIfEnabled(enabled: false))
    }

    func testPlaySystemShutterSound() {
        XCTAssertNoThrow(soundManager.playSystemShutterSound())
    }

    func testMultipleRapidCalls() {
        // Test that multiple rapid calls don't cause issues
        for _ in 0..<5 {
            soundManager.playCapture()
        }
        // If we get here without crashing, test passes
        XCTAssertTrue(true)
    }
}
