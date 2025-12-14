//
//  ScreenshotHistoryTests.swift
//  SwiftScreenShotTests
//
//  Tests for screenshot history functionality
//

import XCTest
@testable import SwiftScreenShot

final class ScreenshotHistoryTests: XCTestCase {

    func testHistoryItemCreation() {
        let item = ScreenshotHistoryItem(
            imageFileName: "test.png",
            thumbnailFileName: "thumb_test.png",
            imageFormat: "png",
            fileSize: 1024
        )

        XCTAssertNotNil(item.id)
        XCTAssertEqual(item.imageFileName, "test.png")
        XCTAssertEqual(item.thumbnailFileName, "thumb_test.png")
        XCTAssertFalse(item.isPinned)
        XCTAssertEqual(item.imageFormat, "png")
        XCTAssertEqual(item.fileSize, 1024)
    }

    func testFormattedFileSize() {
        let item = ScreenshotHistoryItem(
            imageFileName: "test.png",
            thumbnailFileName: "thumb_test.png",
            imageFormat: "png",
            fileSize: 2048
        )

        let formattedSize = item.formattedFileSize
        XCTAssertTrue(formattedSize.contains("2"))
        XCTAssertTrue(formattedSize.contains("KB") || formattedSize.contains("kB"))
    }

    func testFormattedDate() {
        let date = Date()
        let item = ScreenshotHistoryItem(
            timestamp: date,
            imageFileName: "test.png",
            thumbnailFileName: "thumb_test.png",
            imageFormat: "png",
            fileSize: 1024
        )

        let formattedDate = item.formattedDate
        XCTAssertFalse(formattedDate.isEmpty)
    }

    func testHistoryItemCodable() throws {
        let originalItem = ScreenshotHistoryItem(
            imageFileName: "test.png",
            thumbnailFileName: "thumb_test.png",
            isPinned: true,
            imageFormat: "png",
            fileSize: 1024
        )

        // Encode
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(originalItem)

        // Decode
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let decodedItem = try decoder.decode(ScreenshotHistoryItem.self, from: data)

        // Verify
        XCTAssertEqual(originalItem.id, decodedItem.id)
        XCTAssertEqual(originalItem.imageFileName, decodedItem.imageFileName)
        XCTAssertEqual(originalItem.thumbnailFileName, decodedItem.thumbnailFileName)
        XCTAssertEqual(originalItem.isPinned, decodedItem.isPinned)
        XCTAssertEqual(originalItem.imageFormat, decodedItem.imageFormat)
        XCTAssertEqual(originalItem.fileSize, decodedItem.fileSize)
    }
}
