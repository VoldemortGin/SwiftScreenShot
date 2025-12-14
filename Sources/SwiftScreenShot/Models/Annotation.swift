//
//  Annotation.swift
//  SwiftScreenShot
//
//  Annotation protocol and implementations for image editing
//

import AppKit

// MARK: - Annotation Protocol

protocol Annotation: AnyObject {
    var id: UUID { get }
    var color: NSColor { get set }
    var lineWidth: CGFloat { get set }

    func draw(in context: CGContext)
    func contains(point: CGPoint) -> Bool
    func move(by offset: CGPoint)
}

// MARK: - Arrow Annotation

class ArrowAnnotation: Annotation {
    let id = UUID()
    var color: NSColor
    var lineWidth: CGFloat
    var startPoint: CGPoint
    var endPoint: CGPoint

    init(startPoint: CGPoint, endPoint: CGPoint, color: NSColor, lineWidth: CGFloat) {
        self.startPoint = startPoint
        self.endPoint = endPoint
        self.color = color
        self.lineWidth = lineWidth
    }

    func draw(in context: CGContext) {
        context.saveGState()

        // Draw arrow line
        let path = NSBezierPath()
        path.move(to: startPoint)
        path.line(to: endPoint)
        path.lineWidth = lineWidth
        path.lineCapStyle = .round

        color.setStroke()
        path.stroke()

        // Draw arrowhead
        let angle = atan2(endPoint.y - startPoint.y, endPoint.x - startPoint.x)
        let arrowLength: CGFloat = lineWidth * 3
        let arrowAngle: CGFloat = .pi / 6

        let arrowPath = NSBezierPath()
        arrowPath.move(to: endPoint)

        let point1 = CGPoint(
            x: endPoint.x - arrowLength * cos(angle - arrowAngle),
            y: endPoint.y - arrowLength * sin(angle - arrowAngle)
        )
        arrowPath.line(to: point1)

        arrowPath.move(to: endPoint)
        let point2 = CGPoint(
            x: endPoint.x - arrowLength * cos(angle + arrowAngle),
            y: endPoint.y - arrowLength * sin(angle + arrowAngle)
        )
        arrowPath.line(to: point2)

        arrowPath.lineWidth = lineWidth
        arrowPath.lineCapStyle = .round
        arrowPath.stroke()

        context.restoreGState()
    }

    func contains(point: CGPoint) -> Bool {
        let path = NSBezierPath()
        path.move(to: startPoint)
        path.line(to: endPoint)
        path.lineWidth = lineWidth + 10

        return path.contains(point)
    }

    func move(by offset: CGPoint) {
        startPoint.x += offset.x
        startPoint.y += offset.y
        endPoint.x += offset.x
        endPoint.y += offset.y
    }
}

// MARK: - Text Annotation

class TextAnnotation: Annotation {
    let id = UUID()
    var color: NSColor
    var lineWidth: CGFloat
    var position: CGPoint
    var text: String
    var fontSize: CGFloat

    init(position: CGPoint, text: String, color: NSColor, fontSize: CGFloat) {
        self.position = position
        self.text = text
        self.color = color
        self.fontSize = fontSize
        self.lineWidth = 1.0
    }

    func draw(in context: CGContext) {
        context.saveGState()

        let attributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: fontSize, weight: .medium),
            .foregroundColor: color
        ]

        let attributedString = NSAttributedString(string: text, attributes: attributes)
        let textSize = attributedString.size()
        let textRect = CGRect(
            x: position.x,
            y: position.y - textSize.height,
            width: textSize.width,
            height: textSize.height
        )

        attributedString.draw(in: textRect)

        context.restoreGState()
    }

    func contains(point: CGPoint) -> Bool {
        let attributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: fontSize, weight: .medium)
        ]
        let attributedString = NSAttributedString(string: text, attributes: attributes)
        let textSize = attributedString.size()
        let textRect = CGRect(
            x: position.x,
            y: position.y - textSize.height,
            width: textSize.width,
            height: textSize.height
        )

        return textRect.contains(point)
    }

    func move(by offset: CGPoint) {
        position.x += offset.x
        position.y += offset.y
    }
}

// MARK: - Rectangle Annotation

class RectangleAnnotation: Annotation {
    let id = UUID()
    var color: NSColor
    var lineWidth: CGFloat
    var rect: CGRect
    var fillColor: NSColor?
    var cornerRadius: CGFloat

    init(rect: CGRect, color: NSColor, lineWidth: CGFloat, fillColor: NSColor? = nil, cornerRadius: CGFloat = 0) {
        self.rect = rect
        self.color = color
        self.lineWidth = lineWidth
        self.fillColor = fillColor
        self.cornerRadius = cornerRadius
    }

    func draw(in context: CGContext) {
        context.saveGState()

        let path: NSBezierPath
        if cornerRadius > 0 {
            path = NSBezierPath(roundedRect: rect, xRadius: cornerRadius, yRadius: cornerRadius)
        } else {
            path = NSBezierPath(rect: rect)
        }

        path.lineWidth = lineWidth

        if let fillColor = fillColor {
            fillColor.setFill()
            path.fill()
        }

        color.setStroke()
        path.stroke()

        context.restoreGState()
    }

    func contains(point: CGPoint) -> Bool {
        return rect.insetBy(dx: -lineWidth, dy: -lineWidth).contains(point)
    }

    func move(by offset: CGPoint) {
        rect.origin.x += offset.x
        rect.origin.y += offset.y
    }
}

// MARK: - Ellipse Annotation

class EllipseAnnotation: Annotation {
    let id = UUID()
    var color: NSColor
    var lineWidth: CGFloat
    var rect: CGRect
    var fillColor: NSColor?

    init(rect: CGRect, color: NSColor, lineWidth: CGFloat, fillColor: NSColor? = nil) {
        self.rect = rect
        self.color = color
        self.lineWidth = lineWidth
        self.fillColor = fillColor
    }

    func draw(in context: CGContext) {
        context.saveGState()

        let path = NSBezierPath(ovalIn: rect)
        path.lineWidth = lineWidth

        if let fillColor = fillColor {
            fillColor.setFill()
            path.fill()
        }

        color.setStroke()
        path.stroke()

        context.restoreGState()
    }

    func contains(point: CGPoint) -> Bool {
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radiusX = rect.width / 2
        let radiusY = rect.height / 2

        let normalizedX = (point.x - center.x) / radiusX
        let normalizedY = (point.y - center.y) / radiusY

        return (normalizedX * normalizedX + normalizedY * normalizedY) <= 1.0
    }

    func move(by offset: CGPoint) {
        rect.origin.x += offset.x
        rect.origin.y += offset.y
    }
}

// MARK: - Mosaic Annotation

class MosaicAnnotation: Annotation {
    let id = UUID()
    var color: NSColor
    var lineWidth: CGFloat
    var rect: CGRect
    private(set) var mosaicImage: NSImage?

    init(rect: CGRect, sourceImage: NSImage) {
        self.rect = rect
        self.color = .clear
        self.lineWidth = 0
        self.mosaicImage = createMosaicEffect(from: sourceImage, in: rect)
    }

    func draw(in context: CGContext) {
        guard let mosaicImage = mosaicImage else { return }

        context.saveGState()

        let cgImage = mosaicImage.cgImage(forProposedRect: nil, context: nil, hints: nil)
        context.draw(cgImage!, in: rect)

        context.restoreGState()
    }

    func contains(point: CGPoint) -> Bool {
        return rect.contains(point)
    }

    func move(by offset: CGPoint) {
        rect.origin.x += offset.x
        rect.origin.y += offset.y
    }

    private func createMosaicEffect(from image: NSImage, in rect: CGRect) -> NSImage? {
        guard let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            return nil
        }

        let ciImage = CIImage(cgImage: cgImage)

        // Create pixelate filter
        guard let filter = CIFilter(name: "CIPixellate") else { return nil }
        filter.setValue(ciImage, forKey: kCIInputImageKey)
        filter.setValue(max(rect.width, rect.height) / 20, forKey: kCIInputScaleKey)

        guard let outputImage = filter.outputImage else { return nil }

        // Crop to the specified rect
        let croppedImage = outputImage.cropped(to: rect)

        // Convert back to NSImage
        let rep = NSCIImageRep(ciImage: croppedImage)
        let resultImage = NSImage(size: rect.size)
        resultImage.addRepresentation(rep)

        return resultImage
    }
}
