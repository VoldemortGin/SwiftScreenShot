//
//  ErrorRecoveryTests.swift
//  SwiftScreenShotTests
//
//  Unit tests for error recovery mechanism
//

import XCTest
@testable import SwiftScreenShot

final class ErrorRecoveryTests: XCTestCase {

    var errorRecoveryManager: ErrorRecoveryManager!
    var errorLogger: ErrorLogger!

    override func setUp() async throws {
        try await super.setUp()
        errorRecoveryManager = ErrorRecoveryManager.shared
        errorLogger = ErrorLogger.shared
    }

    override func tearDown() async throws {
        errorLogger.clearLogs()
        try await super.tearDown()
    }

    // MARK: - Error Classification Tests

    func testPermissionDeniedError() {
        let error = ScreenshotRecoverableError.permissionDenied

        XCTAssertEqual(error.category, .permissionDenied)
        XCTAssertFalse(error.category.isRecoverable)
        XCTAssertNotNil(error.quickAction)
        XCTAssertEqual(error.quickAction, .openSystemPreferences)
    }

    func testSystemBusyError() {
        let error = ScreenshotRecoverableError.systemBusy(attempt: 1)

        XCTAssertEqual(error.category, .systemBusy)
        XCTAssertTrue(error.category.isRecoverable)
        XCTAssertEqual(error.quickAction, .retryNow)
    }

    func testDiskFullError() {
        let error = ScreenshotRecoverableError.diskFull(availableSpace: 1024 * 1024)

        XCTAssertEqual(error.category, .diskFull)
        XCTAssertFalse(error.category.isRecoverable)
        XCTAssertEqual(error.quickAction, .cleanupDiskSpace)
        XCTAssertTrue(error.localizedDescription.contains("1.0 MB"))
    }

    func testNetworkError() {
        let underlyingError = NSError(domain: "test", code: -1009, userInfo: nil)
        let error = ScreenshotRecoverableError.networkError(underlying: underlyingError)

        XCTAssertEqual(error.category, .networkError)
        XCTAssertTrue(error.category.isRecoverable)
        XCTAssertEqual(error.quickAction, .checkNetwork)
    }

    // MARK: - Retry Configuration Tests

    func testDefaultRetryConfiguration() {
        let config = RetryConfiguration.default

        XCTAssertEqual(config.maxAttempts, 3)
        XCTAssertEqual(config.delays.count, 3)
        XCTAssertTrue(config.enabled)
        XCTAssertEqual(config.delays[0], 0.5)
        XCTAssertEqual(config.delays[1], 1.0)
        XCTAssertEqual(config.delays[2], 2.0)
    }

    func testCustomRetryConfiguration() {
        let config = RetryConfiguration(
            maxAttempts: 5,
            delays: [0.25, 0.5, 1.0, 2.0, 4.0],
            enabled: true
        )

        XCTAssertEqual(config.maxAttempts, 5)
        XCTAssertEqual(config.delays.count, 5)
        XCTAssertEqual(config.delayForAttempt(1), 0.25)
        XCTAssertEqual(config.delayForAttempt(3), 1.0)
        XCTAssertEqual(config.delayForAttempt(5), 4.0)
    }

    func testRetryConfigurationBoundary() {
        let config = RetryConfiguration.default

        // Test out of bounds
        XCTAssertEqual(config.delayForAttempt(0), 2.0) // Returns last
        XCTAssertEqual(config.delayForAttempt(10), 2.0) // Returns last
    }

    // MARK: - Retry Logic Tests

    func testSuccessfulOperationNoRetry() async {
        var attemptCount = 0

        let result = await errorRecoveryManager.executeWithRetry(
            operation: {
                attemptCount += 1
                return "Success"
            }
        )

        XCTAssertEqual(attemptCount, 1, "Should only attempt once on success")

        if case .recovered = result {
            // Success
        } else {
            XCTFail("Expected recovered result")
        }
    }

    func testRecoverableErrorWithRetry() async {
        var attemptCount = 0

        let result = await errorRecoveryManager.executeWithRetry(
            operation: {
                attemptCount += 1
                if attemptCount < 3 {
                    throw ScreenshotRecoverableError.systemBusy(attempt: attemptCount)
                }
                return "Success"
            }
        )

        XCTAssertEqual(attemptCount, 3, "Should retry until success")

        if case .recovered = result {
            // Success after retries
        } else {
            XCTFail("Expected recovered result after retries")
        }
    }

    func testMaxRetriesExceeded() async {
        var attemptCount = 0
        let maxAttempts = 3

        let result = await errorRecoveryManager.executeWithRetry(
            operation: {
                attemptCount += 1
                throw ScreenshotRecoverableError.systemBusy(attempt: attemptCount)
            }
        )

        XCTAssertEqual(attemptCount, maxAttempts, "Should attempt max times")

        if case .maxRetriesExceeded = result {
            // Expected
        } else {
            XCTFail("Expected maxRetriesExceeded result")
        }
    }

    func testNonRecoverableErrorNoRetry() async {
        var attemptCount = 0

        let result = await errorRecoveryManager.executeWithRetry(
            operation: {
                attemptCount += 1
                throw ScreenshotRecoverableError.permissionDenied
            }
        )

        XCTAssertEqual(attemptCount, 1, "Should not retry non-recoverable error")

        if case .userActionRequired = result {
            // Expected
        } else {
            XCTFail("Expected userActionRequired result")
        }
    }

    // MARK: - Error Logging Tests

    func testErrorLogging() {
        let error = ScreenshotRecoverableError.captureFailed(reason: "Test failure")
        let operationId = UUID().uuidString

        errorLogger.logError(error, operationId: operationId, attempt: 1)

        let recentLogs = errorLogger.getRecentLogs(count: 10)
        XCTAssertGreaterThan(recentLogs.count, 0)

        let lastLog = recentLogs.last!
        XCTAssertEqual(lastLog.level, .error)
        XCTAssertEqual(lastLog.operationId, operationId)
        XCTAssertEqual(lastLog.attempt, 1)
    }

    func testRetryLogging() {
        let operationId = UUID().uuidString

        errorLogger.logRetryAttempt(operationId: operationId, attempt: 2)

        let recentLogs = errorLogger.getRecentLogs(count: 10)
        let retryLog = recentLogs.first { $0.operationId == operationId }

        XCTAssertNotNil(retryLog)
        XCTAssertEqual(retryLog?.level, .info)
        XCTAssertEqual(retryLog?.attempt, 2)
    }

    func testRecoverySuccessLogging() {
        let operationId = UUID().uuidString

        errorLogger.logRecoverySuccess(operationId: operationId, attempt: 3)

        let recentLogs = errorLogger.getRecentLogs(count: 10)
        let successLog = recentLogs.first { $0.operationId == operationId }

        XCTAssertNotNil(successLog)
        XCTAssertEqual(successLog?.level, .info)
        XCTAssertTrue(successLog!.message.contains("successful"))
    }

    func testLogBuffering() {
        // Generate many logs
        for i in 0..<150 {
            errorLogger.logInfo("Test log \(i)")
        }

        let recentLogs = errorLogger.getRecentLogs(count: 200)
        XCTAssertLessThanOrEqual(recentLogs.count, 150)
    }

    // MARK: - Error Report Tests

    func testErrorReportGeneration() {
        // Log some errors
        errorLogger.logError(
            ScreenshotRecoverableError.permissionDenied,
            operationId: UUID().uuidString,
            attempt: 1
        )
        errorLogger.logError(
            ScreenshotRecoverableError.systemBusy(attempt: 2),
            operationId: UUID().uuidString,
            attempt: 2
        )

        let report = errorLogger.generateErrorReport()

        XCTAssertTrue(report.contains("SwiftScreenShot Error Report"))
        XCTAssertTrue(report.contains("Generated:"))
    }

    // MARK: - Integration Tests

    func testEndToEndRecovery() async {
        var attemptCount = 0
        let expectedAttempts = 2

        let result = await errorRecoveryManager.executeWithRetry(
            operation: {
                attemptCount += 1
                if attemptCount < expectedAttempts {
                    throw ScreenshotRecoverableError.systemBusy(attempt: attemptCount)
                }
                return "Success"
            },
            onError: { error in
                self.errorLogger.logError(error, operationId: UUID().uuidString, attempt: attemptCount)
            }
        )

        XCTAssertEqual(attemptCount, expectedAttempts)

        if case .recovered = result {
            // Verify logs
            let recentLogs = errorLogger.getRecentLogs(count: 10)
            let errorLogs = recentLogs.filter { $0.level == .error }
            XCTAssertGreaterThan(errorLogs.count, 0)
        } else {
            XCTFail("Expected recovered result")
        }
    }

    // MARK: - Performance Tests

    func testRetryPerformance() async {
        measure {
            Task {
                var count = 0
                _ = await errorRecoveryManager.executeWithRetry {
                    count += 1
                    if count < 3 {
                        throw ScreenshotRecoverableError.systemBusy(attempt: count)
                    }
                    return true
                }
            }
        }
    }

    func testLoggingPerformance() {
        measure {
            for i in 0..<100 {
                errorLogger.logInfo("Performance test log \(i)")
            }
        }
    }

    // MARK: - Edge Cases

    func testEmptyErrorMessage() {
        let error = ScreenshotRecoverableError.captureFailed(reason: "")
        XCTAssertNotNil(error.localizedDescription)
    }

    func testVeryLargeRetryCount() {
        let config = RetryConfiguration(
            maxAttempts: 100,
            delays: [0.1, 0.2, 0.3],
            enabled: true
        )

        XCTAssertEqual(config.delayForAttempt(50), 0.3)
    }

    func testConcurrentRetries() async {
        await withTaskGroup(of: RecoveryResult.self) { group in
            for _ in 0..<5 {
                group.addTask {
                    await self.errorRecoveryManager.executeWithRetry {
                        try await Task.sleep(nanoseconds: 100_000_000)
                        return true
                    }
                }
            }

            var successCount = 0
            for await result in group {
                if case .recovered = result {
                    successCount += 1
                }
            }

            XCTAssertEqual(successCount, 5, "All concurrent operations should succeed")
        }
    }
}

// MARK: - Mock Classes for Testing

class MockErrorRecoveryDelegate {
    var errorCount = 0
    var successCount = 0
    var retryCount = 0

    func onError(_ error: SwiftScreenShot.RecoverableError) {
        errorCount += 1
    }

    func onSuccess() {
        successCount += 1
    }

    func onRetry(attempt: Int) {
        retryCount += 1
    }
}
