//
//  ScreenshotHistoryItem.swift
//  SwiftScreenShot
//
//  Screenshot history item model
//

import Foundation
import AppKit

struct ScreenshotHistoryItem: Identifiable, Codable {
    let id: UUID
    let timestamp: Date
    let imageFileName: String  // Stored image file name
    let thumbnailFileName: String  // Stored thumbnail file name
    var isPinned: Bool
    let imageFormat: String
    let fileSize: Int64  // In bytes

    // Transient properties (not stored in JSON)
    var image: NSImage? = nil
    var thumbnail: NSImage? = nil

    enum CodingKeys: String, CodingKey {
        case id, timestamp, imageFileName, thumbnailFileName
        case isPinned, imageFormat, fileSize
    }

    init(id: UUID = UUID(),
         timestamp: Date = Date(),
         imageFileName: String,
         thumbnailFileName: String,
         isPinned: Bool = false,
         imageFormat: String,
         fileSize: Int64) {
        self.id = id
        self.timestamp = timestamp
        self.imageFileName = imageFileName
        self.thumbnailFileName = thumbnailFileName
        self.isPinned = isPinned
        self.imageFormat = imageFormat
        self.fileSize = fileSize
    }

    // Formatted date string
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        formatter.locale = Locale(identifier: "zh_CN")
        return formatter.string(from: timestamp)
    }

    // Formatted file size
    var formattedFileSize: String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: fileSize)
    }
}
