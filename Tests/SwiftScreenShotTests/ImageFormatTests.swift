//
//  ImageFormatTests.swift
//  SwiftScreenShot
//
//  Unit tests for ImageFormat enum
//

import XCTest
@testable import SwiftScreenShot

final class ImageFormatTests: XCTestCase {

    func testPNGFileExtension() {
        let format = ImageFormat.png
        XCTAssertEqual(format.fileExtension, "png")
    }

    func testJPEGFileExtension() {
        let format = ImageFormat.jpeg(quality: 0.8)
        XCTAssertEqual(format.fileExtension, "jpg")
    }

    func testPNGRawValue() {
        let format = ImageFormat.png
        XCTAssertEqual(format.rawValue, "png")
    }

    func testJPEGRawValue() {
        let format = ImageFormat.jpeg(quality: 0.5)
        XCTAssertEqual(format.rawValue, "jpeg")
    }

    func testInitFromPNGRawValue() {
        let format = ImageFormat(rawValue: "png")
        XCTAssertNotNil(format)
        if case .png = format! {
            // Test passes
        } else {
            XCTFail("Expected PNG format")
        }
    }

    func testInitFromJPEGRawValue() {
        let format = ImageFormat(rawValue: "jpeg")
        XCTAssertNotNil(format)
        if case .jpeg(let quality) = format! {
            XCTAssertEqual(quality, 0.9, "Default JPEG quality should be 0.9")
        } else {
            XCTFail("Expected JPEG format")
        }
    }

    func testInitFromInvalidRawValue() {
        let format = ImageFormat(rawValue: "invalid")
        XCTAssertNil(format, "Invalid raw value should return nil")
    }
}
