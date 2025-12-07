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
    static let didCompleteSelection = Notification.Name("didCompleteSelection")
}
