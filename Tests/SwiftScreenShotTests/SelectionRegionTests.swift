//
//  SelectionRegionTests.swift
//  SwiftScreenShot
//
//  Unit tests for SelectionRegion struct
//

import XCTest
import CoreGraphics
@testable import SwiftScreenShot

final class SelectionRegionTests: XCTestCase {

    func testValidRegion() {
        let rect = CGRect(x: 0, y: 0, width: 100, height: 100)
        let screenFrame = CGRect(x: 0, y: 0, width: 1920, height: 1080)
        let region = SelectionRegion(rect: rect, screenFrame: screenFrame)

        XCTAssertTrue(region.isValid, "Region with width and height > 5 should be valid")
    }

    func testInvalidRegionTooSmallWidth() {
        let rect = CGRect(x: 0, y: 0, width: 4, height: 100)
        let screenFrame = CGRect(x: 0, y: 0, width: 1920, height: 1080)
        let region = SelectionRegion(rect: rect, screenFrame: screenFrame)

        XCTAssertFalse(region.isValid, "Region with width <= 5 should be invalid")
    }

    func testInvalidRegionTooSmallHeight() {
        let rect = CGRect(x: 0, y: 0, width: 100, height: 3)
        let screenFrame = CGRect(x: 0, y: 0, width: 1920, height: 1080)
        let region = SelectionRegion(rect: rect, screenFrame: screenFrame)

        XCTAssertFalse(region.isValid, "Region with height <= 5 should be invalid")
    }

    func testBorderlineValidRegion() {
        let rect = CGRect(x: 0, y: 0, width: 6, height: 6)
        let screenFrame = CGRect(x: 0, y: 0, width: 1920, height: 1080)
        let region = SelectionRegion(rect: rect, screenFrame: screenFrame)

        XCTAssertTrue(region.isValid, "Region with width and height = 6 should be valid")
    }

    func testToScreenCoordinatesSimple() {
        let rect = CGRect(x: 100, y: 200, width: 300, height: 400)
        let screenFrame = CGRect(x: 0, y: 0, width: 1920, height: 1080)
        let region = SelectionRegion(rect: rect, screenFrame: screenFrame)

        let screenCoords = region.toScreenCoordinates()

        // Y coordinate should be flipped
        // flippedY = 1080 - 200 - 400 = 480
        XCTAssertEqual(screenCoords.origin.x, 100)
        XCTAssertEqual(screenCoords.origin.y, 480)
        XCTAssertEqual(screenCoords.width, 300)
        XCTAssertEqual(screenCoords.height, 400)
    }

    func testToScreenCoordinatesWithScreenOffset() {
        let rect = CGRect(x: 50, y: 100, width: 200, height: 150)
        let screenFrame = CGRect(x: 1920, y: 0, width: 1080, height: 720)
        let region = SelectionRegion(rect: rect, screenFrame: screenFrame)

        let screenCoords = region.toScreenCoordinates()

        // flippedY = 720 - 100 - 150 = 470
        // x = 1920 + 50 = 1970
        // y = 0 + 470 = 470
        XCTAssertEqual(screenCoords.origin.x, 1970)
        XCTAssertEqual(screenCoords.origin.y, 470)
        XCTAssertEqual(screenCoords.width, 200)
        XCTAssertEqual(screenCoords.height, 150)
    }
}
