//
//  EditorView.swift
//  SwiftScreenShot
//
//  Editor view for annotating screenshots
//

import AppKit

enum EditorTool {
    case select
    case arrow
    case text
    case rectangle
    case ellipse
    case mosaic
}

class EditorView: NSView {
    // MARK: - Properties

    private let image: NSImage
    private let annotationManager: AnnotationManager
    private var currentTool: EditorTool = .arrow

    // Drawing state
    private var isDrawing = false
    private var startPoint: CGPoint = .zero
    private var currentPoint: CGPoint = .zero
    private var tempAnnotation: Annotation?
    private var selectedAnnotation: Annotation?
    private var dragOffset: CGPoint = .zero

    // Tool settings
    var currentColor: NSColor = .red
    var currentLineWidth: CGFloat = 3.0
    var currentFontSize: CGFloat = 16.0

    // Callbacks
    var onToolChanged: ((EditorTool) -> Void)?

    // MARK: - Initialization

    init(frame: CGRect, image: NSImage, annotationManager: AnnotationManager) {
        self.image = image
        self.annotationManager = annotationManager
        super.init(frame: frame)

        setupView()
        setupAnnotationObserver()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupView() {
        wantsLayer = true
        layer?.backgroundColor = NSColor.black.cgColor
    }

    private func setupAnnotationObserver() {
        annotationManager.onAnnotationsChanged = { [weak self] in
            self?.needsDisplay = true
        }
    }

    // MARK: - Drawing

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        guard let context = NSGraphicsContext.current?.cgContext else { return }

        // Calculate image rect (centered and scaled to fit)
        let imageRect = calculateImageRect()

        // Draw the screenshot image
        image.draw(in: imageRect)

        // Draw all annotations
        for annotation in annotationManager.getAllAnnotations() {
            annotation.draw(in: context)
        }

        // Draw temporary annotation while drawing
        if let tempAnnotation = tempAnnotation {
            tempAnnotation.draw(in: context)
        }

        // Highlight selected annotation
        if let selected = selectedAnnotation, currentTool == .select {
            context.saveGState()
            context.setStrokeColor(NSColor.systemBlue.cgColor)
            context.setLineWidth(2.0)
            context.setLineDash(phase: 0, lengths: [5, 5])

            if let arrow = selected as? ArrowAnnotation {
                let rect = CGRect(
                    x: min(arrow.startPoint.x, arrow.endPoint.x) - 5,
                    y: min(arrow.startPoint.y, arrow.endPoint.y) - 5,
                    width: abs(arrow.endPoint.x - arrow.startPoint.x) + 10,
                    height: abs(arrow.endPoint.y - arrow.startPoint.y) + 10
                )
                context.stroke(rect)
            } else if let text = selected as? TextAnnotation {
                let attributes: [NSAttributedString.Key: Any] = [
                    .font: NSFont.systemFont(ofSize: text.fontSize, weight: .medium)
                ]
                let size = NSAttributedString(string: text.text, attributes: attributes).size()
                let rect = CGRect(x: text.position.x - 5, y: text.position.y - size.height - 5,
                                width: size.width + 10, height: size.height + 10)
                context.stroke(rect)
            } else if let rect = selected as? RectangleAnnotation {
                context.stroke(rect.rect.insetBy(dx: -5, dy: -5))
            } else if let ellipse = selected as? EllipseAnnotation {
                context.strokeEllipse(in: ellipse.rect.insetBy(dx: -5, dy: -5))
            } else if let mosaic = selected as? MosaicAnnotation {
                context.stroke(mosaic.rect.insetBy(dx: -5, dy: -5))
            }

            context.restoreGState()
        }
    }

    private func calculateImageRect() -> CGRect {
        let imageSize = image.size
        let viewSize = bounds.size

        let scaleX = viewSize.width / imageSize.width
        let scaleY = viewSize.height / imageSize.height
        let scale = min(scaleX, scaleY)

        let scaledWidth = imageSize.width * scale
        let scaledHeight = imageSize.height * scale

        let x = (viewSize.width - scaledWidth) / 2
        let y = (viewSize.height - scaledHeight) / 2

        return CGRect(x: x, y: y, width: scaledWidth, height: scaledHeight)
    }

    // MARK: - Mouse Events

    override func mouseDown(with event: NSEvent) {
        let point = convert(event.locationInWindow, from: nil)
        startPoint = point
        currentPoint = point

        switch currentTool {
        case .select:
            selectedAnnotation = annotationManager.getAnnotation(at: point)
            if let selected = selectedAnnotation {
                if let arrow = selected as? ArrowAnnotation {
                    dragOffset = CGPoint(x: point.x - arrow.startPoint.x, y: point.y - arrow.startPoint.y)
                } else if let text = selected as? TextAnnotation {
                    dragOffset = CGPoint(x: point.x - text.position.x, y: point.y - text.position.y)
                } else if let rect = selected as? RectangleAnnotation {
                    dragOffset = CGPoint(x: point.x - rect.rect.origin.x, y: point.y - rect.rect.origin.y)
                } else if let ellipse = selected as? EllipseAnnotation {
                    dragOffset = CGPoint(x: point.x - ellipse.rect.origin.x, y: point.y - ellipse.rect.origin.y)
                } else if let mosaic = selected as? MosaicAnnotation {
                    dragOffset = CGPoint(x: point.x - mosaic.rect.origin.x, y: point.y - mosaic.rect.origin.y)
                }
            }
            isDrawing = true

        case .arrow:
            isDrawing = true

        case .text:
            showTextInputDialog(at: point)

        case .rectangle, .ellipse, .mosaic:
            isDrawing = true
        }

        needsDisplay = true
    }

    override func mouseDragged(with event: NSEvent) {
        guard isDrawing else { return }

        let point = convert(event.locationInWindow, from: nil)
        currentPoint = point

        switch currentTool {
        case .select:
            if let selected = selectedAnnotation {
                let offset = CGPoint(x: point.x - startPoint.x, y: point.y - startPoint.y)
                selected.move(by: offset)
                startPoint = point
            }

        case .arrow:
            tempAnnotation = ArrowAnnotation(
                startPoint: startPoint,
                endPoint: currentPoint,
                color: currentColor,
                lineWidth: currentLineWidth
            )

        case .rectangle:
            let rect = CGRect(
                x: min(startPoint.x, currentPoint.x),
                y: min(startPoint.y, currentPoint.y),
                width: abs(currentPoint.x - startPoint.x),
                height: abs(currentPoint.y - startPoint.y)
            )
            tempAnnotation = RectangleAnnotation(
                rect: rect,
                color: currentColor,
                lineWidth: currentLineWidth,
                fillColor: currentColor.withAlphaComponent(0.1),
                cornerRadius: 5
            )

        case .ellipse:
            let rect = CGRect(
                x: min(startPoint.x, currentPoint.x),
                y: min(startPoint.y, currentPoint.y),
                width: abs(currentPoint.x - startPoint.x),
                height: abs(currentPoint.y - startPoint.y)
            )
            tempAnnotation = EllipseAnnotation(
                rect: rect,
                color: currentColor,
                lineWidth: currentLineWidth,
                fillColor: currentColor.withAlphaComponent(0.1)
            )

        case .mosaic:
            let rect = CGRect(
                x: min(startPoint.x, currentPoint.x),
                y: min(startPoint.y, currentPoint.y),
                width: abs(currentPoint.x - startPoint.x),
                height: abs(currentPoint.y - startPoint.y)
            )
            tempAnnotation = MosaicAnnotation(rect: rect, sourceImage: image)

        case .text:
            break
        }

        needsDisplay = true
    }

    override func mouseUp(with event: NSEvent) {
        guard isDrawing else { return }

        isDrawing = false

        if let annotation = tempAnnotation {
            annotationManager.addAnnotation(annotation)
            tempAnnotation = nil
        }

        needsDisplay = true
    }

    // MARK: - Tool Management

    func setTool(_ tool: EditorTool) {
        currentTool = tool
        selectedAnnotation = nil
        onToolChanged?(tool)
        needsDisplay = true
    }

    func deleteSelectedAnnotation() {
        if let selected = selectedAnnotation {
            annotationManager.removeAnnotation(selected)
            selectedAnnotation = nil
        }
    }

    // MARK: - Text Input

    private func showTextInputDialog(at point: CGPoint) {
        let alert = NSAlert()
        alert.messageText = "输入文字"
        alert.informativeText = "请输入要添加的文字标注："
        alert.addButton(withTitle: "确定")
        alert.addButton(withTitle: "取消")

        let textField = NSTextField(frame: NSRect(x: 0, y: 0, width: 300, height: 24))
        textField.placeholderString = "在此输入文字..."
        alert.accessoryView = textField

        alert.window.initialFirstResponder = textField

        let response = alert.runModal()
        if response == .alertFirstButtonReturn {
            let text = textField.stringValue
            if !text.isEmpty {
                let annotation = TextAnnotation(
                    position: point,
                    text: text,
                    color: currentColor,
                    fontSize: currentFontSize
                )
                annotationManager.addAnnotation(annotation)
            }
        }
    }

    // MARK: - Export

    func renderFinalImage() -> NSImage {
        let finalSize = image.size
        let finalImage = NSImage(size: finalSize)

        finalImage.lockFocus()

        // Draw original image
        image.draw(in: NSRect(origin: .zero, size: finalSize))

        // Draw all annotations
        if let context = NSGraphicsContext.current?.cgContext {
            for annotation in annotationManager.getAllAnnotations() {
                annotation.draw(in: context)
            }
        }

        finalImage.unlockFocus()

        return finalImage
    }
}
