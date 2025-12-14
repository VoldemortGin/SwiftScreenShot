//
//  DelayedScreenshotManager.swift
//  SwiftScreenShot
//
//  Manager for delayed screenshot functionality with countdown timer
//

import AppKit
import Foundation

class DelayedScreenshotManager {

    // MARK: - Properties

    private var countdownTimer: Timer?
    private var remainingSeconds: Int = 0
    private var screenshotMode: ScreenshotMode = .region
    private var countdownWindow: CountdownWindow?
    private var cancelObserver: Any?

    // Callback for when countdown completes
    var onCountdownComplete: ((ScreenshotMode) -> Void)?

    // MARK: - Public Methods

    /// Start a delayed screenshot with specified delay and mode
    func startDelayedScreenshot(delaySeconds: Int, mode: ScreenshotMode) {
        AppLogger.shared.info("Starting delayed screenshot: \(delaySeconds)s delay, mode: \(mode)", category: .delay)

        // Cancel any existing countdown
        cancelDelayedScreenshot()

        remainingSeconds = delaySeconds
        screenshotMode = mode

        // Show countdown window
        showCountdownWindow()

        // Setup ESC key observer
        setupCancelObserver()

        // Start countdown timer
        startCountdownTimer()
    }

    /// Cancel the current delayed screenshot
    func cancelDelayedScreenshot() {
        if countdownTimer != nil {
            AppLogger.shared.info("Delayed screenshot cancelled", category: .delay)
        }

        countdownTimer?.invalidate()
        countdownTimer = nil

        hideCountdownWindow()
        removeCancelObserver()

        // Post cancellation notification
        NotificationCenter.default.post(name: .delayedScreenshotCancelled, object: nil)
    }

    // MARK: - Private Methods

    private func showCountdownWindow() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }

            self.countdownWindow = CountdownWindow(initialSeconds: self.remainingSeconds)
            self.countdownWindow?.makeKeyAndOrderFront(nil)
            self.countdownWindow?.level = .floating

            // Center the window
            if let window = self.countdownWindow {
                window.center()
            }
        }
    }

    private func hideCountdownWindow() {
        DispatchQueue.main.async { [weak self] in
            self?.countdownWindow?.close()
            self?.countdownWindow = nil
        }
    }

    private func startCountdownTimer() {
        countdownTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] timer in
            guard let self = self else {
                timer.invalidate()
                return
            }

            self.remainingSeconds -= 1

            // Update countdown display
            DispatchQueue.main.async {
                self.countdownWindow?.updateCountdown(seconds: self.remainingSeconds)
            }

            // Check if countdown finished
            if self.remainingSeconds <= 0 {
                timer.invalidate()
                self.completeCountdown()
            }
        }
    }

    private func completeCountdown() {
        AppLogger.shared.info("Delayed screenshot countdown completed, executing screenshot", category: .delay)

        // Hide countdown window
        hideCountdownWindow()
        removeCancelObserver()

        // Trigger screenshot
        let mode = screenshotMode

        // Small delay to ensure window is hidden
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            self?.onCountdownComplete?(mode)

            // Post completion notification
            NotificationCenter.default.post(
                name: .delayedScreenshotCompleted,
                object: mode
            )
        }
    }

    private func setupCancelObserver() {
        cancelObserver = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            if event.keyCode == 53 { // ESC key
                self?.cancelDelayedScreenshot()
                return nil
            }
            return event
        }
    }

    private func removeCancelObserver() {
        if let observer = cancelObserver {
            NSEvent.removeMonitor(observer)
            cancelObserver = nil
        }
    }

    deinit {
        cancelDelayedScreenshot()
    }
}
