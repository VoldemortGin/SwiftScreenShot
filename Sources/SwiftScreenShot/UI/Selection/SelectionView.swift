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

    // Window detection support
    private let mode: ScreenshotMode
    private let windowDetector: WindowDetector
    private var hoveredWindow: WindowInfo?
    private var trackingArea: NSTrackingArea?

    var onComplete: ((CGRect) -> Void)?
    var onCancel: (() -> Void)?
    var onWindowSelected: ((WindowInfo) -> Void)?

    init(frame: NSRect, backgroundImage: NSImage?, mode: ScreenshotMode = .region) {
        self.backgroundImage = backgroundImage
        self.mode = mode
        self.windowDetector = WindowDetector()
        super.init(frame: frame)
        setupKeyMonitor()
        if mode == .window {
            setupMouseTracking()
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupMouseTracking() {
        let options: NSTrackingArea.Options = [
            .activeAlways,
            .mouseMoved,
            .inVisibleRect
        ]
        trackingArea = NSTrackingArea(
            rect: self.bounds,
            options: options,
            owner: self,
            userInfo: nil
        )
        if let trackingArea = trackingArea {
            self.addTrackingArea(trackingArea)
        }
    }

    private func setupKeyMonitor() {
        keyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            self?.handleKeyDown(event)
            return event
        }
    }

    override func mouseMoved(with event: NSEvent) {
        guard mode == .window else { return }

        let locationInView = self.convert(event.locationInWindow, from: nil)
        let locationInScreen = convertToScreenCoordinates(locationInView)

        // Find window at this location
        hoveredWindow = windowDetector.windowAtPoint(locationInScreen)
        needsDisplay = true
    }

    override func mouseDown(with event: NSEvent) {
        if mode == .window {
            // Window mode - select the hovered window
            if let window = hoveredWindow {
                onWindowSelected?(window)
            }
            return
        }

        // Region mode - start selection
        startPoint = self.convert(event.locationInWindow, from: nil)
        currentPoint = startPoint
        needsDisplay = true
    }

    override func mouseDragged(with event: NSEvent) {
        guard mode == .region else { return }
        currentPoint = self.convert(event.locationInWindow, from: nil)
        needsDisplay = true
    }

    override func mouseUp(with event: NSEvent) {
        guard mode == .region else { return }
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

        // Window mode - draw window highlight
        if mode == .window, let window = hoveredWindow {
            drawWindowHighlight(for: window)
        }

        // Region mode - draw selection
        if mode == .region, let start = startPoint, let end = currentPoint {
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

    private func drawWindowHighlight(for window: WindowInfo) {
        // Convert window bounds to view coordinates
        let viewRect = convertFromScreenCoordinates(window.bounds)

        // Clear the mask to show the window
        NSColor.clear.setFill()
        viewRect.fill(using: .copy)

        // Draw window border with highlight
        NSColor.systemBlue.withAlphaComponent(0.8).setStroke()
        let border = NSBezierPath(rect: viewRect)
        border.lineWidth = 3.0
        border.stroke()

        // Draw dashed inner border for visual effect
        let dashedBorder = NSBezierPath(rect: viewRect.insetBy(dx: 2, dy: 2))
        dashedBorder.lineWidth = 1.0
        dashedBorder.setLineDash([5, 3], count: 2, phase: 0)
        NSColor.white.setStroke()
        dashedBorder.stroke()

        // Draw window info label
        drawWindowLabel(for: window, in: viewRect)
    }

    private func drawWindowLabel(for window: WindowInfo, in rect: CGRect) {
        let ownerName = window.ownerName ?? "Unknown"
        let windowTitle = window.name ?? "Untitled"
        let infoText = "\(ownerName): \(windowTitle)\n\(Int(window.bounds.width)) × \(Int(window.bounds.height))"

        let attributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 12),
            .foregroundColor: NSColor.white,
            .backgroundColor: NSColor.black.withAlphaComponent(0.8)
        ]

        let attributedString = NSAttributedString(string: " \(infoText) ", attributes: attributes)
        let textSize = attributedString.size()

        // Display at top-left of window
        let textRect = CGRect(
            x: rect.minX + 5,
            y: rect.maxY - textSize.height - 5,
            width: min(textSize.width, rect.width - 10),
            height: textSize.height
        )

        attributedString.draw(in: textRect)
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

    private func convertToScreenCoordinates(_ point: CGPoint) -> CGPoint {
        guard let window = self.window else { return point }
        // Convert from view coordinates to screen coordinates
        // macOS uses bottom-left origin for screen coordinates
        let windowPoint = self.convert(point, to: nil)
        let screenPoint = window.convertToScreen(CGRect(origin: windowPoint, size: .zero)).origin
        return screenPoint
    }

    private func convertFromScreenCoordinates(_ rect: CGRect) -> CGRect {
        guard let window = self.window else { return rect }
        let screenFrame = window.screen?.frame ?? .zero

        // Convert screen coordinates to view coordinates
        // Flip Y coordinate (screen uses bottom-left, view uses top-left)
        let flippedY = screenFrame.height - rect.origin.y - rect.height
        let viewY = flippedY - window.frame.origin.y

        return CGRect(
            x: rect.origin.x - window.frame.origin.x,
            y: viewY,
            width: rect.width,
            height: rect.height
        )
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
        if let trackingArea = trackingArea {
            self.removeTrackingArea(trackingArea)
        }
    }
}
