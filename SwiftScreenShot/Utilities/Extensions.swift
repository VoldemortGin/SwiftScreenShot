//
//  Extensions.swift
//  SwiftScreenShot
//
//  Useful Swift extensions
//

import AppKit

extension NSImage {
    var cgImage: CGImage? {
        return self.cgImage(forProposedRect: nil, context: nil, hints: nil)
    }
}

extension Notification.Name {
    static let triggerScreenshot = Notification.Name("triggerScreenshot")
    static let openSettings = Notification.Name("openSettings")
    static let openHistory = Notification.Name("openHistory")
    static let didCompleteSelection = Notification.Name("didCompleteSelection")

    // Delayed screenshot notifications
    static let triggerDelayedScreenshot = Notification.Name("triggerDelayedScreenshot")
    static let cancelDelayedScreenshot = Notification.Name("cancelDelayedScreenshot")
    static let delayedScreenshotCompleted = Notification.Name("delayedScreenshotCompleted")
    static let delayedScreenshotCancelled = Notification.Name("delayedScreenshotCancelled")

    // Editor notifications
    static let didCompleteEditing = Notification.Name("didCompleteEditing")
    static let didCancelEditing = Notification.Name("didCancelEditing")
    static let openEditor = Notification.Name("openEditor")
}
