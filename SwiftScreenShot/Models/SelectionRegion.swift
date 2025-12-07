//
//  SelectionRegion.swift
//  SwiftScreenShot
//
//  Data model for screenshot selection region
//

import Foundation
import CoreGraphics

struct SelectionRegion {
    let rect: CGRect
    let screenFrame: CGRect

    var isValid: Bool {
        return rect.width > 5 && rect.height > 5
    }

    func toScreenCoordinates() -> CGRect {
        // macOS coordinate system: origin at bottom-left
        // Need to flip Y coordinate
        let flippedY = screenFrame.height - rect.origin.y - rect.height

        return CGRect(
            x: screenFrame.origin.x + rect.origin.x,
            y: screenFrame.origin.y + flippedY,
            width: rect.width,
            height: rect.height
        )
    }
}
