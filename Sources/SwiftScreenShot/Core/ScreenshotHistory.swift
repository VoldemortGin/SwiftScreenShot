//
//  ScreenshotHistory.swift
//  SwiftScreenShot
//
//  Screenshot history manager
//

import Foundation
import AppKit
import Combine

class ScreenshotHistory: ObservableObject {
    static let shared = ScreenshotHistory()

    @Published private(set) var items: [ScreenshotHistoryItem] = []

    private let historyDirectory: URL
    private let imagesDirectory: URL
    private let thumbnailsDirectory: URL
    private let indexFileURL: URL

    private let thumbnailSize = CGSize(width: 200, height: 200)

    // Settings
    var maxHistoryCount: Int {
        return UserDefaults.standard.integer(forKey: "historyMaxCount") == 0 ? 20 : UserDefaults.standard.integer(forKey: "historyMaxCount")
    }

    var autoSaveToHistory: Bool {
        if UserDefaults.standard.object(forKey: "autoSaveToHistory") == nil {
            return true  // Default to true
        }
        return UserDefaults.standard.bool(forKey: "autoSaveToHistory")
    }

    private init() {
        // Setup directories
        let appSupport = FileManager.default.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        ).first!

        let customPath = UserDefaults.standard.string(forKey: "historyStoragePath")
        if let customPath = customPath, !customPath.isEmpty {
            historyDirectory = URL(fileURLWithPath: customPath)
        } else {
            historyDirectory = appSupport
                .appendingPathComponent("SwiftScreenShot")
                .appendingPathComponent("History")
        }

        imagesDirectory = historyDirectory.appendingPathComponent("Images")
        thumbnailsDirectory = historyDirectory.appendingPathComponent("Thumbnails")
        indexFileURL = historyDirectory.appendingPathComponent("index.json")

        createDirectoriesIfNeeded()
        loadHistory()
    }

    private func createDirectoriesIfNeeded() {
        let directories = [historyDirectory, imagesDirectory, thumbnailsDirectory]
        for directory in directories {
            if !FileManager.default.fileExists(atPath: directory.path) {
                try? FileManager.default.createDirectory(
                    at: directory,
                    withIntermediateDirectories: true
                )
            }
        }
    }

    // MARK: - Add Screenshot

    func addScreenshot(_ image: NSImage, format: ImageFormat) {
        guard autoSaveToHistory else { return }

        let timestamp = Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd_HHmmss_SSS"
        let timeString = formatter.string(from: timestamp)

        let imageFileName = "screenshot_\(timeString).\(format.fileExtension)"
        let thumbnailFileName = "thumb_\(timeString).png"

        // Save full image
        let imagePath = imagesDirectory.appendingPathComponent(imageFileName)
        guard saveImage(image, to: imagePath, format: format) else {
            AppLogger.shared.error("Failed to save screenshot to history", category: .history)
            return
        }

        // Generate and save thumbnail
        let thumbnail = generateThumbnail(from: image)
        let thumbnailPath = thumbnailsDirectory.appendingPathComponent(thumbnailFileName)
        guard saveImage(thumbnail, to: thumbnailPath, format: .png) else {
            AppLogger.shared.warning("Failed to save thumbnail for history item", category: .history)
            return
        }

        // Get file size
        let fileSize = getFileSize(at: imagePath)

        // Create history item
        var item = ScreenshotHistoryItem(
            timestamp: timestamp,
            imageFileName: imageFileName,
            thumbnailFileName: thumbnailFileName,
            imageFormat: format.rawValue,
            fileSize: fileSize
        )
        item.image = image
        item.thumbnail = thumbnail

        // Add to history
        items.insert(item, at: 0)

        // Remove old items (keeping pinned items)
        cleanupOldItems()

        // Save index
        saveIndex()
    }

    // MARK: - Image Operations

    private func saveImage(_ image: NSImage, to url: URL, format: ImageFormat) -> Bool {
        guard let tiffData = image.tiffRepresentation,
              let bitmapImage = NSBitmapImageRep(data: tiffData) else {
            return false
        }

        let imageData: Data?
        switch format {
        case .png:
            imageData = bitmapImage.representation(using: .png, properties: [:])
        case .jpeg(let quality):
            imageData = bitmapImage.representation(using: .jpeg, properties: [.compressionFactor: quality])
        }

        guard let data = imageData else { return false }

        do {
            try data.write(to: url)
            return true
        } catch {
            AppLogger.shared.error("Error saving image to \(url.lastPathComponent)", category: .history, error: error)
            return false
        }
    }

    private func generateThumbnail(from image: NSImage) -> NSImage {
        let sourceSize = image.size
        let aspectRatio = sourceSize.width / sourceSize.height

        var targetSize = thumbnailSize
        if aspectRatio > 1 {
            // Landscape
            targetSize.height = thumbnailSize.width / aspectRatio
        } else {
            // Portrait
            targetSize.width = thumbnailSize.height * aspectRatio
        }

        let thumbnail = NSImage(size: targetSize)
        thumbnail.lockFocus()
        image.draw(
            in: NSRect(origin: .zero, size: targetSize),
            from: NSRect(origin: .zero, size: sourceSize),
            operation: .copy,
            fraction: 1.0
        )
        thumbnail.unlockFocus()

        return thumbnail
    }

    private func getFileSize(at url: URL) -> Int64 {
        do {
            let attributes = try FileManager.default.attributesOfItem(atPath: url.path)
            return attributes[.size] as? Int64 ?? 0
        } catch {
            return 0
        }
    }

    // MARK: - Load/Save Index

    private func loadHistory() {
        guard FileManager.default.fileExists(atPath: indexFileURL.path) else {
            return
        }

        do {
            let data = try Data(contentsOf: indexFileURL)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            items = try decoder.decode([ScreenshotHistoryItem].self, from: data)

            // Load thumbnails
            loadThumbnails()
            AppLogger.shared.info("Loaded \(items.count) items from history", category: .history)
        } catch {
            AppLogger.shared.error("Failed to load history", category: .history, error: error)
        }
    }

    private func saveIndex() {
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            encoder.outputFormatting = .prettyPrinted
            let data = try encoder.encode(items)
            try data.write(to: indexFileURL)
            AppLogger.shared.debug("Saved history index with \(items.count) items", category: .history)
        } catch {
            AppLogger.shared.error("Failed to save history index", category: .history, error: error)
        }
    }

    private func loadThumbnails() {
        for i in 0..<items.count {
            let thumbnailPath = thumbnailsDirectory.appendingPathComponent(items[i].thumbnailFileName)
            if let thumbnail = NSImage(contentsOf: thumbnailPath) {
                items[i].thumbnail = thumbnail
            }
        }
    }

    // MARK: - Item Management

    func loadFullImage(for item: ScreenshotHistoryItem) -> NSImage? {
        let imagePath = imagesDirectory.appendingPathComponent(item.imageFileName)
        return NSImage(contentsOf: imagePath)
    }

    func togglePin(for item: ScreenshotHistoryItem) {
        if let index = items.firstIndex(where: { $0.id == item.id }) {
            items[index].isPinned.toggle()
            saveIndex()
        }
    }

    func deleteItem(_ item: ScreenshotHistoryItem) {
        guard let index = items.firstIndex(where: { $0.id == item.id }) else {
            return
        }

        // Delete files
        let imagePath = imagesDirectory.appendingPathComponent(item.imageFileName)
        let thumbnailPath = thumbnailsDirectory.appendingPathComponent(item.thumbnailFileName)

        try? FileManager.default.removeItem(at: imagePath)
        try? FileManager.default.removeItem(at: thumbnailPath)

        // Remove from array
        items.remove(at: index)
        saveIndex()
    }

    func clearHistory(keepPinned: Bool = true) {
        let itemsToDelete = keepPinned ? items.filter { !$0.isPinned } : items

        for item in itemsToDelete {
            let imagePath = imagesDirectory.appendingPathComponent(item.imageFileName)
            let thumbnailPath = thumbnailsDirectory.appendingPathComponent(item.thumbnailFileName)

            try? FileManager.default.removeItem(at: imagePath)
            try? FileManager.default.removeItem(at: thumbnailPath)
        }

        if keepPinned {
            items = items.filter { $0.isPinned }
        } else {
            items.removeAll()
        }

        saveIndex()
    }

    /// Remove oldest screenshots from history (for disk cleanup)
    func removeOldest(count: Int) {
        let unpinnedItems = items.filter { !$0.isPinned }
        let removeCount = min(count, unpinnedItems.count)

        guard removeCount > 0 else { return }

        // Sort by timestamp and take oldest
        let sortedUnpinned = unpinnedItems.sorted { $0.timestamp < $1.timestamp }
        let itemsToDelete = Array(sortedUnpinned.prefix(removeCount))

        for item in itemsToDelete {
            deleteItem(item)
        }
    }

    /// Convenience property for screenshot count
    var screenshots: [ScreenshotHistoryItem] {
        return items
    }

    private func cleanupOldItems() {
        // Separate pinned and unpinned items
        let pinnedItems = items.filter { $0.isPinned }
        var unpinnedItems = items.filter { !$0.isPinned }

        // If unpinned items exceed max count, remove oldest
        if unpinnedItems.count > maxHistoryCount {
            let itemsToDelete = unpinnedItems.dropFirst(maxHistoryCount)

            for item in itemsToDelete {
                let imagePath = imagesDirectory.appendingPathComponent(item.imageFileName)
                let thumbnailPath = thumbnailsDirectory.appendingPathComponent(item.thumbnailFileName)

                try? FileManager.default.removeItem(at: imagePath)
                try? FileManager.default.removeItem(at: thumbnailPath)
            }

            unpinnedItems = Array(unpinnedItems.prefix(maxHistoryCount))
        }

        // Combine back: unpinned first, then pinned
        items = unpinnedItems + pinnedItems
    }

    // MARK: - Search and Filter

    func filterItems(searchText: String, dateFilter: DateFilter? = nil) -> [ScreenshotHistoryItem] {
        var filtered = items

        // Date filter
        if let dateFilter = dateFilter {
            let calendar = Calendar.current
            let now = Date()

            filtered = filtered.filter { item in
                switch dateFilter {
                case .today:
                    return calendar.isDateInToday(item.timestamp)
                case .yesterday:
                    return calendar.isDateInYesterday(item.timestamp)
                case .lastWeek:
                    let weekAgo = calendar.date(byAdding: .day, value: -7, to: now)!
                    return item.timestamp >= weekAgo
                case .lastMonth:
                    let monthAgo = calendar.date(byAdding: .month, value: -1, to: now)!
                    return item.timestamp >= monthAgo
                }
            }
        }

        // Text search (by format)
        if !searchText.isEmpty {
            filtered = filtered.filter { item in
                item.imageFormat.lowercased().contains(searchText.lowercased())
            }
        }

        return filtered
    }

    enum DateFilter {
        case today
        case yesterday
        case lastWeek
        case lastMonth
    }
}
