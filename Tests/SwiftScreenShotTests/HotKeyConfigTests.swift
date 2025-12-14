//
//  HotKeyConfigTests.swift
//  SwiftScreenShotTests
//
//  Tests for HotKeyConfig model
//

import XCTest
import Carbon
@testable import SwiftScreenShot

final class HotKeyConfigTests: XCTestCase {

    // MARK: - Initialization Tests

    func testDefaultRegionScreenshot() {
        let config = HotKeyConfig.defaultRegionScreenshot

        XCTAssertEqual(config.keyCode, 0) // 'A' key
        XCTAssertEqual(config.modifiers, UInt32(cmdKey | controlKey))
    }

    func testDefaultFullScreenshot() {
        let config = HotKeyConfig.defaultFullScreenshot

        XCTAssertEqual(config.keyCode, 20) // '3' key
        XCTAssertEqual(config.modifiers, UInt32(cmdKey | shiftKey))
    }

    // MARK: - Display String Tests

    func testDisplayString_RegionScreenshot() {
        let config = HotKeyConfig.defaultRegionScreenshot
        let displayString = config.displayString

        XCTAssertTrue(displayString.contains("⌃")) // Control
        XCTAssertTrue(displayString.contains("⌘")) // Command
        XCTAssertTrue(displayString.contains("A"))
    }

    func testDisplayString_FullScreenshot() {
        let config = HotKeyConfig.defaultFullScreenshot
        let displayString = config.displayString

        XCTAssertTrue(displayString.contains("⇧")) // Shift
        XCTAssertTrue(displayString.contains("⌘")) // Command
        XCTAssertTrue(displayString.contains("3"))
    }

    func testDisplayString_AllModifiers() {
        // Test all modifiers: Ctrl+Option+Shift+Cmd+A
        let config = HotKeyConfig(
            keyCode: 0,
            modifiers: UInt32(controlKey | optionKey | shiftKey | cmdKey)
        )
        let displayString = config.displayString

        XCTAssertTrue(displayString.contains("⌃")) // Control
        XCTAssertTrue(displayString.contains("⌥")) // Option
        XCTAssertTrue(displayString.contains("⇧")) // Shift
        XCTAssertTrue(displayString.contains("⌘")) // Command
        XCTAssertTrue(displayString.contains("A"))

        // Check order: Control, Option, Shift, Command
        let ctrlIndex = displayString.firstIndex(of: "⌃")!
        let optIndex = displayString.firstIndex(of: "⌥")!
        let shiftIndex = displayString.firstIndex(of: "⇧")!
        let cmdIndex = displayString.firstIndex(of: "⌘")!

        XCTAssertLessThan(ctrlIndex, optIndex)
        XCTAssertLessThan(optIndex, shiftIndex)
        XCTAssertLessThan(shiftIndex, cmdIndex)
    }

    // MARK: - Verbose Display String Tests

    func testVerboseDisplayString_RegionScreenshot() {
        let config = HotKeyConfig.defaultRegionScreenshot
        let verboseString = config.verboseDisplayString

        XCTAssertTrue(verboseString.contains("Control"))
        XCTAssertTrue(verboseString.contains("Command"))
        XCTAssertTrue(verboseString.contains("A"))
        XCTAssertTrue(verboseString.contains("+"))
    }

    func testVerboseDisplayString_FullScreenshot() {
        let config = HotKeyConfig.defaultFullScreenshot
        let verboseString = config.verboseDisplayString

        XCTAssertTrue(verboseString.contains("Shift"))
        XCTAssertTrue(verboseString.contains("Command"))
        XCTAssertTrue(verboseString.contains("3"))
    }

    // MARK: - Validation Tests

    func testIsValid_ValidConfig() {
        let config = HotKeyConfig.defaultRegionScreenshot
        XCTAssertTrue(config.isValid)
    }

    func testIsValid_NoModifiers() {
        let config = HotKeyConfig(keyCode: 0, modifiers: 0)
        XCTAssertFalse(config.isValid)
    }

    func testIsValid_InvalidKeyCode() {
        let config = HotKeyConfig(keyCode: 9999, modifiers: UInt32(cmdKey))
        XCTAssertFalse(config.isValid)
    }

    func testIsValid_SystemReserved() {
        // Cmd+Q is system reserved (quit)
        let config = HotKeyConfig(keyCode: 12, modifiers: UInt32(cmdKey))
        XCTAssertFalse(config.isValid)
    }

    // MARK: - System Reserved Tests

    func testIsSystemReserved_CmdTab() {
        let config = HotKeyConfig(keyCode: 48, modifiers: UInt32(cmdKey))
        XCTAssertTrue(config.isSystemReserved)
    }

    func testIsSystemReserved_CmdQ() {
        let config = HotKeyConfig(keyCode: 12, modifiers: UInt32(cmdKey))
        XCTAssertTrue(config.isSystemReserved)
    }

    func testIsSystemReserved_NotReserved() {
        let config = HotKeyConfig.defaultRegionScreenshot
        XCTAssertFalse(config.isSystemReserved)
    }

    // MARK: - Equality Tests

    func testEquality_SameConfig() {
        let config1 = HotKeyConfig(keyCode: 0, modifiers: UInt32(cmdKey | controlKey))
        let config2 = HotKeyConfig(keyCode: 0, modifiers: UInt32(cmdKey | controlKey))

        XCTAssertEqual(config1, config2)
    }

    func testEquality_DifferentKeyCode() {
        let config1 = HotKeyConfig(keyCode: 0, modifiers: UInt32(cmdKey))
        let config2 = HotKeyConfig(keyCode: 1, modifiers: UInt32(cmdKey))

        XCTAssertNotEqual(config1, config2)
    }

    func testEquality_DifferentModifiers() {
        let config1 = HotKeyConfig(keyCode: 0, modifiers: UInt32(cmdKey))
        let config2 = HotKeyConfig(keyCode: 0, modifiers: UInt32(shiftKey))

        XCTAssertNotEqual(config1, config2)
    }

    // MARK: - Codable Tests

    func testCodable_Encode() throws {
        let config = HotKeyConfig.defaultRegionScreenshot
        let encoder = JSONEncoder()

        let data = try encoder.encode(config)
        XCTAssertFalse(data.isEmpty)
    }

    func testCodable_Decode() throws {
        let original = HotKeyConfig.defaultRegionScreenshot
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        let data = try encoder.encode(original)
        let decoded = try decoder.decode(HotKeyConfig.self, from: data)

        XCTAssertEqual(original, decoded)
    }

    func testCodable_RoundTrip() throws {
        let original = HotKeyConfig(
            keyCode: 45,
            modifiers: UInt32(cmdKey | optionKey | shiftKey)
        )

        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        let data = try encoder.encode(original)
        let decoded = try decoder.decode(HotKeyConfig.self, from: data)

        XCTAssertEqual(original.keyCode, decoded.keyCode)
        XCTAssertEqual(original.modifiers, decoded.modifiers)
    }

    // MARK: - HotKeyType Tests

    func testHotKeyType_AllCases() {
        let allCases = HotKeyType.allCases
        XCTAssertEqual(allCases.count, 2)
        XCTAssertTrue(allCases.contains(.regionScreenshot))
        XCTAssertTrue(allCases.contains(.fullScreenshot))
    }

    func testHotKeyType_DisplayName() {
        XCTAssertEqual(HotKeyType.regionScreenshot.displayName, "区域截图")
        XCTAssertEqual(HotKeyType.fullScreenshot.displayName, "全屏截图")
    }

    func testHotKeyType_DefaultConfig() {
        XCTAssertEqual(
            HotKeyType.regionScreenshot.defaultConfig,
            HotKeyConfig.defaultRegionScreenshot
        )
        XCTAssertEqual(
            HotKeyType.fullScreenshot.defaultConfig,
            HotKeyConfig.defaultFullScreenshot
        )
    }

    // MARK: - Validation Error Tests

    func testValidationError_NoModifiers() {
        let error = HotKeyValidationError.noModifiers
        XCTAssertNotNil(error.errorDescription)
        XCTAssertTrue(error.errorDescription!.contains("修饰键"))
    }

    func testValidationError_InvalidKeyCode() {
        let error = HotKeyValidationError.invalidKeyCode
        XCTAssertNotNil(error.errorDescription)
        XCTAssertTrue(error.errorDescription!.contains("无效"))
    }

    func testValidationError_SystemReserved() {
        let error = HotKeyValidationError.systemReserved
        XCTAssertNotNil(error.errorDescription)
        XCTAssertTrue(error.errorDescription!.contains("系统保留"))
    }

    func testValidationError_ConflictWithOther() {
        let error = HotKeyValidationError.conflictWithOther(.regionScreenshot)
        XCTAssertNotNil(error.errorDescription)
        XCTAssertTrue(error.errorDescription!.contains("区域截图"))
    }
}
