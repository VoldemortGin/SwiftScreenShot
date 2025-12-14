//
//  EditorWindow.swift
//  SwiftScreenShot
//
//  Window for editing screenshots with annotations
//

import AppKit

class EditorWindow: NSWindow {
    private var editorView: EditorView!
    private var editorToolbar: EditorToolbar!
    private let annotationManager: AnnotationManager
    private let image: NSImage

    var onComplete: ((NSImage) -> Void)?
    var onCancel: (() -> Void)?

    init(image: NSImage) {
        self.image = image
        self.annotationManager = AnnotationManager()

        // Calculate window size (fit to screen with margins)
        let screenFrame = NSScreen.main?.visibleFrame ?? NSRect(x: 0, y: 0, width: 1200, height: 800)
        let maxWidth = screenFrame.width * 0.9
        let maxHeight = screenFrame.height * 0.9

        let aspectRatio = image.size.width / image.size.height
        var windowWidth = min(image.size.width, maxWidth)
        var windowHeight = windowWidth / aspectRatio

        if windowHeight > maxHeight {
            windowHeight = maxHeight
            windowWidth = windowHeight * aspectRatio
        }

        let toolbarHeight: CGFloat = 64
        let windowRect = NSRect(
            x: screenFrame.midX - windowWidth / 2,
            y: screenFrame.midY - windowHeight / 2,
            width: windowWidth,
            height: windowHeight + toolbarHeight
        )

        super.init(
            contentRect: windowRect,
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )

        setupWindow()
        setupViews(toolbarHeight: toolbarHeight)
        setupKeyboardShortcuts()
    }

    private func setupWindow() {
        title = "编辑截图"
        backgroundColor = .black
        isReleasedWhenClosed = false
        level = .floating
        makeKeyAndOrderFront(nil)
    }

    private func setupViews(toolbarHeight: CGFloat) {
        guard let contentView = contentView else { return }

        // Create editor view
        let editorFrame = NSRect(
            x: 0,
            y: toolbarHeight,
            width: contentView.bounds.width,
            height: contentView.bounds.height - toolbarHeight
        )
        editorView = EditorView(frame: editorFrame, image: image, annotationManager: annotationManager)
        editorView.autoresizingMask = [.width, .height]
        contentView.addSubview(editorView)

        // Create toolbar
        let toolbarFrame = NSRect(
            x: 0,
            y: 0,
            width: contentView.bounds.width,
            height: toolbarHeight
        )
        editorToolbar = EditorToolbar(frame: toolbarFrame)
        editorToolbar.autoresizingMask = [.width, .maxYMargin]
        editorToolbar.delegate = self
        contentView.addSubview(editorToolbar)

        // Setup annotation change observer
        annotationManager.onAnnotationsChanged = { [weak self] in
            self?.updateUndoRedoButtons()
        }

        updateUndoRedoButtons()
    }

    private func setupKeyboardShortcuts() {
        // ESC to cancel
        NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            if event.keyCode == 53 { // ESC key
                self?.handleCancel()
                return nil
            }
            return event
        }
    }

    private func updateUndoRedoButtons() {
        editorToolbar.setUndoEnabled(annotationManager.canUndo)
        editorToolbar.setRedoEnabled(annotationManager.canRedo)
    }

    private func handleSave() {
        let finalImage = editorView.renderFinalImage()
        onComplete?(finalImage)
        close()
    }

    private func handleCancel() {
        let alert = NSAlert()
        alert.messageText = "确定要取消编辑吗？"
        alert.informativeText = "所有未保存的标注将会丢失。"
        alert.addButton(withTitle: "取消编辑")
        alert.addButton(withTitle: "继续编辑")
        alert.alertStyle = .warning

        let response = alert.runModal()
        if response == .alertFirstButtonReturn {
            onCancel?()
            close()
        }
    }
}

// MARK: - EditorToolbarDelegate

extension EditorWindow: EditorToolbarDelegate {
    func toolbarDidSelectTool(_ tool: EditorTool) {
        editorView.setTool(tool)
    }

    func toolbarDidChangeColor(_ color: NSColor) {
        editorView.currentColor = color
    }

    func toolbarDidChangeLineWidth(_ width: CGFloat) {
        editorView.currentLineWidth = width
    }

    func toolbarDidChangeFontSize(_ size: CGFloat) {
        editorView.currentFontSize = size
    }

    func toolbarDidRequestUndo() {
        annotationManager.undo()
    }

    func toolbarDidRequestRedo() {
        annotationManager.redo()
    }

    func toolbarDidRequestSave() {
        handleSave()
    }

    func toolbarDidRequestCancel() {
        handleCancel()
    }
}
