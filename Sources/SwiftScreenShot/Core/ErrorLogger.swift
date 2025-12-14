//
//  ErrorLogger.swift
//  SwiftScreenShot
//
//  Error logging and reporting
//

import Foundation
import AppKit

/// Error logger for tracking and reporting errors
class ErrorLogger {
    static let shared = ErrorLogger()

    private let logQueue: DispatchQueue
    private let logFileURL: URL
    private let dateFormatter: DateFormatter
    private var logBuffer: [ErrorLogEntry] = []
    private let maxBufferSize = 100
    private let lock = NSLock()

    private init() {
        self.logQueue = DispatchQueue(label: "com.swiftscreenshot.errorlogger", qos: .utility)
        self.dateFormatter = DateFormatter()
        self.dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"

        // Setup log file
        let logsDirectory = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("SwiftScreenShot")
            .appendingPathComponent("Logs")

        try? FileManager.default.createDirectory(at: logsDirectory, withIntermediateDirectories: true)

        let logFileName = "error_log_\(DateFormatter.yyyyMMdd.string(from: Date())).txt"
        self.logFileURL = logsDirectory.appendingPathComponent(logFileName)

        // Create log file if doesn't exist
        if !FileManager.default.fileExists(atPath: logFileURL.path) {
            FileManager.default.createFile(atPath: logFileURL.path, contents: nil)
        }

        // Clean old log files
        cleanOldLogFiles(in: logsDirectory)
    }

    // MARK: - Logging Methods

    func logError(_ error: RecoverableError, operationId: String, attempt: Int) {
        let entry = ErrorLogEntry(
            timestamp: Date(),
            level: .error,
            category: error.category,
            message: error.localizedDescription,
            operationId: operationId,
            attempt: attempt,
            details: [
                "recovery_suggestion": error.recoverySuggestion,
                "category": "\(error.category)"
            ]
        )

        writeLog(entry)
    }

    func logRetryAttempt(operationId: String, attempt: Int) {
        let entry = ErrorLogEntry(
            timestamp: Date(),
            level: .info,
            category: .unknown,
            message: "Retry attempt \(attempt)",
            operationId: operationId,
            attempt: attempt,
            details: [:]
        )

        writeLog(entry)
    }

    func logRecoverySuccess(operationId: String, attempt: Int) {
        let entry = ErrorLogEntry(
            timestamp: Date(),
            level: .info,
            category: .unknown,
            message: "Recovery successful after \(attempt) attempts",
            operationId: operationId,
            attempt: attempt,
            details: [:]
        )

        writeLog(entry)
    }

    func logMaxRetriesExceeded(operationId: String) {
        let entry = ErrorLogEntry(
            timestamp: Date(),
            level: .error,
            category: .unknown,
            message: "Max retries exceeded",
            operationId: operationId,
            attempt: 0,
            details: [:]
        )

        writeLog(entry)
    }

    func logInfo(_ message: String) {
        let entry = ErrorLogEntry(
            timestamp: Date(),
            level: .info,
            category: .unknown,
            message: message,
            operationId: UUID().uuidString,
            attempt: 0,
            details: [:]
        )

        writeLog(entry)
    }

    func logWarning(_ message: String, details: [String: String] = [:]) {
        let entry = ErrorLogEntry(
            timestamp: Date(),
            level: .warning,
            category: .unknown,
            message: message,
            operationId: UUID().uuidString,
            attempt: 0,
            details: details
        )

        writeLog(entry)
    }

    // MARK: - Log Management

    private func writeLog(_ entry: ErrorLogEntry) {
        logQueue.async { [weak self] in
            guard let self = self else { return }

            // Add to buffer
            self.lock.lock()
            self.logBuffer.append(entry)

            // Flush if buffer is full
            if self.logBuffer.count >= self.maxBufferSize {
                self.flushBuffer()
            }
            self.lock.unlock()

            // Also write immediately for errors
            if entry.level == .error {
                self.flushBuffer()
            }
        }
    }

    private func flushBuffer() {
        lock.lock()
        let entries = logBuffer
        logBuffer.removeAll()
        lock.unlock()

        guard !entries.isEmpty else { return }

        var logText = ""
        for entry in entries {
            logText += formatLogEntry(entry) + "\n"
        }

        // Append to file
        if let data = logText.data(using: .utf8),
           let fileHandle = try? FileHandle(forWritingTo: logFileURL) {
            fileHandle.seekToEndOfFile()
            fileHandle.write(data)
            try? fileHandle.close()
        }
    }

    private func formatLogEntry(_ entry: ErrorLogEntry) -> String {
        let timestamp = dateFormatter.string(from: entry.timestamp)
        let level = entry.level.rawValue.uppercased()
        let category = "\(entry.category)".uppercased()

        var log = "[\(timestamp)] [\(level)] [\(category)] \(entry.message)"

        if entry.attempt > 0 {
            log += " [Attempt: \(entry.attempt)]"
        }

        log += " [OperationID: \(entry.operationId)]"

        if !entry.details.isEmpty {
            log += "\n  Details: \(entry.details)"
        }

        return log
    }

    private func cleanOldLogFiles(in directory: URL) {
        do {
            let files = try FileManager.default.contentsOfDirectory(
                at: directory,
                includingPropertiesForKeys: [.creationDateKey],
                options: .skipsHiddenFiles
            )

            let sevenDaysAgo = Date().addingTimeInterval(-7 * 24 * 60 * 60)

            for file in files where file.pathExtension == "txt" {
                if let attributes = try? FileManager.default.attributesOfItem(atPath: file.path),
                   let creationDate = attributes[.creationDate] as? Date,
                   creationDate < sevenDaysAgo {
                    try? FileManager.default.removeItem(at: file)
                }
            }
        } catch {
            print("Failed to clean old log files: \(error)")
        }
    }

    // MARK: - Public Methods

    func getRecentLogs(count: Int = 50) -> [ErrorLogEntry] {
        lock.lock()
        defer { lock.unlock() }
        return Array(logBuffer.suffix(count))
    }

    func exportLogs() -> URL? {
        flushBuffer()
        return logFileURL
    }

    func showLogFile() {
        flushBuffer()
        NSWorkspace.shared.activateFileViewerSelecting([logFileURL])
    }

    func clearLogs() {
        lock.lock()
        logBuffer.removeAll()
        lock.unlock()

        try? FileManager.default.removeItem(at: logFileURL)
        FileManager.default.createFile(atPath: logFileURL.path, contents: nil)
    }

    /// Generate error report for submission
    func generateErrorReport() -> String {
        flushBuffer()

        var report = """
        SwiftScreenShot Error Report
        Generated: \(dateFormatter.string(from: Date()))
        ================================

        """

        // Read recent logs
        if let logData = try? Data(contentsOf: logFileURL),
           let logContent = String(data: logData, encoding: .utf8) {
            let lines = logContent.components(separatedBy: .newlines)
            let recentLines = lines.suffix(100).joined(separator: "\n")
            report += recentLines
        }

        return report
    }
}

// MARK: - Log Entry

struct ErrorLogEntry {
    let timestamp: Date
    let level: ErrorLogLevel
    let category: ErrorCategory
    let message: String
    let operationId: String
    let attempt: Int
    let details: [String: String]
}

enum ErrorLogLevel: String {
    case info
    case warning
    case error
}

// MARK: - Date Formatter Extension

extension DateFormatter {
    static let yyyyMMdd: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()
}
