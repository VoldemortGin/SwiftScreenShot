//
//  SelectionView.swift
//  SwiftScreenShot
//
//  Selection view for drawing and handling user selection
//

import AppKit

class SelectionView: NSView {
    private var startPoint: CGPoint?
    private var currentPoint: CGPoint?
    private let backgroundImage: NSImage?
    private var keyMonitor: Any?

    var onComplete: ((CGRect) -> Void)?
    var onCancel: (() -> Void)?

    init(frame: NSRect, backgroundImage: NSImage?) {
        self.backgroundImage = backgroundImage
        super.init(frame: frame)
        setupKeyMonitor()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupKeyMonitor() {
        keyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            self?.handleKeyDown(event)
            return event
        }
    }

    override func mouseDown(with event: NSEvent) {
        startPoint = self.convert(event.locationInWindow, from: nil)
        currentPoint = startPoint
        needsDisplay = true
    }

    override func mouseDragged(with event: NSEvent) {
        currentPoint = self.convert(event.locationInWindow, from: nil)
        needsDisplay = true
    }

    override func mouseUp(with event: NSEvent) {
        guard let start = startPoint, let end = currentPoint else { return }

        let rect = normalizedRect(from: start, to: end)

        if rect.width > 5 && rect.height > 5 {  // Minimum selection size
            onComplete?(rect)
        }

        startPoint = nil
        currentPoint = nil
    }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        // Draw semi-transparent background
        NSColor.black.withAlphaComponent(0.3).setFill()
        dirtyRect.fill()

        // Draw background image if available
        if let bgImage = backgroundImage {
            bgImage.draw(in: self.bounds)
        }

        // Draw selection
        if let start = startPoint, let end = currentPoint {
            let selectionRect = normalizedRect(from: start, to: end)

            // Clear the mask in selection area (show original screen)
            NSColor.clear.setFill()
            selectionRect.fill(using: .copy)

            // Draw selection border
            NSColor.white.setStroke()
            let border = NSBezierPath(rect: selectionRect)
            border.lineWidth = 2.0
            border.stroke()

            // Draw size label
            drawSizeLabel(for: selectionRect)
        }
    }

    private func drawSizeLabel(for rect: CGRect) {
        let sizeText = "\(Int(rect.width)) × \(Int(rect.height))"
        let attributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 12),
            .foregroundColor: NSColor.white,
            .backgroundColor: NSColor.black.withAlphaComponent(0.7)
        ]

        let attributedString = NSAttributedString(string: " \(sizeText) ", attributes: attributes)
        let textSize = attributedString.size()

        // Display at bottom-right of selection
        let textRect = CGRect(
            x: rect.maxX - textSize.width - 5,
            y: rect.minY + 5,
            width: textSize.width,
            height: textSize.height
        )

        attributedString.draw(in: textRect)
    }

    private func normalizedRect(from start: CGPoint, to end: CGPoint) -> CGRect {
        let x = min(start.x, end.x)
        let y = min(start.y, end.y)
        let width = abs(end.x - start.x)
        let height = abs(end.y - start.y)

        return CGRect(x: x, y: y, width: width, height: height)
    }

    private func handleKeyDown(_ event: NSEvent) {
        switch event.keyCode {
        case 53:  // ESC
            onCancel?()
        case 36:  // Enter
            if let start = startPoint, let end = currentPoint {
                let rect = normalizedRect(from: start, to: end)
                onComplete?(rect)
            }
        default:
            break
        }
    }

    deinit {
        if let monitor = keyMonitor {
            NSEvent.removeMonitor(monitor)
        }
    }
}
