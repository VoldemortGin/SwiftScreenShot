//
//  ImageProcessor.swift
//  SwiftScreenShot
//
//  Image processing utilities for cropping and format conversion
//

import AppKit

class ImageProcessor {

    /// Crop an image to a specific rectangle
    func cropImage(_ image: NSImage, to rect: CGRect) -> NSImage? {
        guard let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            return nil
        }

        // Calculate crop rect considering retina scaling
        let scale = image.recommendedLayerContentsScale(0)
        let scaledRect = CGRect(
            x: rect.origin.x * scale,
            y: rect.origin.y * scale,
            width: rect.width * scale,
            height: rect.height * scale
        )

        guard let croppedCGImage = cgImage.cropping(to: scaledRect) else {
            return nil
        }

        let croppedImage = NSImage(cgImage: croppedCGImage, size: rect.size)
        return croppedImage
    }

    /// Convert image to data in specified format
    func imageData(from image: NSImage, format: ImageFormat) -> Data? {
        guard let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            return nil
        }

        let bitmapRep = NSBitmapImageRep(cgImage: cgImage)

        switch format {
        case .png:
            return bitmapRep.representation(using: .png, properties: [:])
        case .jpeg(let quality):
            return bitmapRep.representation(
                using: .jpeg,
                properties: [.compressionFactor: quality]
            )
        }
    }
}
