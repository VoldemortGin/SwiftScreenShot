//
//  AppLogger.swift
//  SwiftScreenShot
//
//  Structured logging system using os.Logger
//

import Foundation
import OSLog

/// Log levels for controlling verbosity
enum LogLevel: String, Codable, CaseIterable {
    case debug = "debug"
    case info = "info"
    case warning = "warning"
    case error = "error"
    case fault = "fault"

    var displayName: String {
        switch self {
        case .debug: return "Debug"
        case .info: return "Info"
        case .warning: return "Warning"
        case .error: return "Error"
        case .fault: return "Fault"
        }
    }

    var osLogType: OSLogType {
        switch self {
        case .debug: return .debug
        case .info: return .info
        case .warning: return .default
        case .error: return .error
        case .fault: return .fault
        }
    }
}

/// Log categories for different modules
enum LogCategory: String, CaseIterable {
    case screenshot = "screenshot"
    case hotkey = "hotkey"
    case settings = "settings"
    case editor = "editor"
    case history = "history"
    case window = "window"
    case permission = "permission"
    case output = "output"
    case sound = "sound"
    case annotation = "annotation"
    case delay = "delay"
    case app = "app"

    var displayName: String {
        return rawValue.capitalized
    }
}

/// Centralized logging manager
class AppLogger {
    static let shared = AppLogger()

    /// The subsystem identifier for all app logs
    private let subsystem = "com.swiftscreenshot.app"

    /// Individual loggers for each category
    private var loggers: [LogCategory: Logger] = [:]

    /// Current minimum log level (controlled by settings)
    @Published private(set) var minimumLevel: LogLevel = .info

    /// Whether to enable file logging
    @Published private(set) var fileLoggingEnabled: Bool = false

    /// Log file URL
    private var logFileURL: URL?

    /// Date formatter for log timestamps
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
        return formatter
    }()

    /// File logging queue
    private let fileLoggingQueue = DispatchQueue(label: "com.swiftscreenshot.logging", qos: .utility)

    private init() {
        // Initialize loggers for each category
        for category in LogCategory.allCases {
            loggers[category] = Logger(subsystem: subsystem, category: category.rawValue)
        }

        // Load settings
        loadSettings()

        // Setup log file if enabled
        if fileLoggingEnabled {
            setupLogFile()
        }
    }

    // MARK: - Settings Management

    private func loadSettings() {
        if let levelString = UserDefaults.standard.string(forKey: "logLevel"),
           let level = LogLevel(rawValue: levelString) {
            minimumLevel = level
        } else {
            // Default to info in production, debug in development
            #if DEBUG
            minimumLevel = .debug
            #else
            minimumLevel = .info
            #endif
        }

        fileLoggingEnabled = UserDefaults.standard.bool(forKey: "fileLoggingEnabled")
    }

    func setMinimumLevel(_ level: LogLevel) {
        minimumLevel = level
        UserDefaults.standard.set(level.rawValue, forKey: "logLevel")
        log(.info, category: .app, "Log level changed to \(level.displayName)")
    }

    func setFileLogging(enabled: Bool) {
        fileLoggingEnabled = enabled
        UserDefaults.standard.set(enabled, forKey: "fileLoggingEnabled")

        if enabled {
            setupLogFile()
            log(.info, category: .app, "File logging enabled")
        } else {
            log(.info, category: .app, "File logging disabled")
        }
    }

    // MARK: - File Logging

    private func setupLogFile() {
        let logsDirectory = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first?
            .appendingPathComponent("SwiftScreenShot")
            .appendingPathComponent("Logs")

        guard let logsDir = logsDirectory else { return }

        // Create logs directory if needed
        try? FileManager.default.createDirectory(at: logsDir, withIntermediateDirectories: true)

        // Create log file with current date
        let dateString = DateFormatter.localizedString(from: Date(), dateStyle: .short, timeStyle: .none)
            .replacingOccurrences(of: "/", with: "-")
        let fileName = "SwiftScreenShot_\(dateString).log"
        logFileURL = logsDir.appendingPathComponent(fileName)

        // Write header
        if let url = logFileURL {
            let header = "=== SwiftScreenShot Log Started at \(dateFormatter.string(from: Date())) ===\n"
            try? header.write(to: url, atomically: true, encoding: .utf8)
        }
    }

    private func writeToFile(_ message: String, level: LogLevel, category: LogCategory) {
        guard fileLoggingEnabled, let url = logFileURL else { return }

        fileLoggingQueue.async { [weak self] in
            guard let self = self else { return }

            let timestamp = self.dateFormatter.string(from: Date())
            let logEntry = "[\(timestamp)] [\(level.rawValue.uppercased())] [\(category.rawValue)] \(message)\n"

            if let handle = try? FileHandle(forWritingTo: url) {
                handle.seekToEndOfFile()
                handle.write(logEntry.data(using: .utf8) ?? Data())
                handle.closeFile()
            } else {
                // File doesn't exist, create it
                try? logEntry.write(to: url, atomically: true, encoding: .utf8)
            }
        }
    }

    // MARK: - Logging Methods

    /// Main logging function
    private func log(_ level: LogLevel, category: LogCategory, _ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        // Check if this log level should be recorded
        guard shouldLog(level) else { return }

        guard let logger = loggers[category] else { return }

        // Add file/function/line info for debug logs
        var finalMessage = message
        #if DEBUG
        if level == .debug {
            let fileName = (file as NSString).lastPathComponent
            finalMessage = "[\(fileName):\(line)] \(function) - \(message)"
        }
        #endif

        // Log to os_log
        logger.log(level: level.osLogType, "\(finalMessage)")

        // Log to file if enabled
        if fileLoggingEnabled {
            writeToFile(message, level: level, category: category)
        }
    }

    private func shouldLog(_ level: LogLevel) -> Bool {
        let levels: [LogLevel] = [.debug, .info, .warning, .error, .fault]
        guard let currentIndex = levels.firstIndex(of: minimumLevel),
              let logIndex = levels.firstIndex(of: level) else {
            return false
        }
        return logIndex >= currentIndex
    }

    // MARK: - Public Logging APIs

    func debug(_ message: String, category: LogCategory, file: String = #file, function: String = #function, line: Int = #line) {
        log(.debug, category: category, message, file: file, function: function, line: line)
    }

    func info(_ message: String, category: LogCategory) {
        log(.info, category: category, message)
    }

    func warning(_ message: String, category: LogCategory) {
        log(.warning, category: category, message)
    }

    func error(_ message: String, category: LogCategory, error: Error? = nil) {
        var message = message
        if let error = error {
            message += " - Error: \(error.localizedDescription)"
        }
        log(.error, category: category, message)
    }

    func fault(_ message: String, category: LogCategory) {
        log(.fault, category: category, message)
    }

    // MARK: - Log Export

    /// Export current log file
    func exportLogs() -> URL? {
        return logFileURL
    }

    /// Get all log files
    func getAllLogFiles() -> [URL] {
        let logsDirectory = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first?
            .appendingPathComponent("SwiftScreenShot")
            .appendingPathComponent("Logs")

        guard let logsDir = logsDirectory,
              let files = try? FileManager.default.contentsOfDirectory(at: logsDir, includingPropertiesForKeys: [.creationDateKey], options: .skipsHiddenFiles) else {
            return []
        }

        return files.sorted { url1, url2 in
            let date1 = try? url1.resourceValues(forKeys: [.creationDateKey]).creationDate
            let date2 = try? url2.resourceValues(forKeys: [.creationDateKey]).creationDate
            return (date1 ?? Date.distantPast) > (date2 ?? Date.distantPast)
        }
    }

    /// Clear old log files (keep last N files)
    func cleanOldLogs(keepLast: Int = 7) {
        let allLogs = getAllLogFiles()
        guard allLogs.count > keepLast else { return }

        let logsToDelete = allLogs.dropFirst(keepLast)
        for logFile in logsToDelete {
            try? FileManager.default.removeItem(at: logFile)
        }

        info("Cleaned \(logsToDelete.count) old log files", category: .app)
    }
}

// MARK: - Convenience Extensions

extension Logger {
    /// Screenshot logger
    static let screenshot = AppLogger.shared

    /// Hotkey logger
    static let hotkey = AppLogger.shared

    /// Settings logger
    static let settings = AppLogger.shared

    /// Editor logger
    static let editor = AppLogger.shared

    /// History logger
    static let history = AppLogger.shared

    /// Window logger
    static let window = AppLogger.shared

    /// Permission logger
    static let permission = AppLogger.shared

    /// Output logger
    static let output = AppLogger.shared

    /// Sound logger
    static let sound = AppLogger.shared

    /// Annotation logger
    static let annotation = AppLogger.shared

    /// Delay logger
    static let delay = AppLogger.shared

    /// App logger
    static let app = AppLogger.shared
}
