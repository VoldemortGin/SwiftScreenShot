//
//  EditorToolbar.swift
//  SwiftScreenShot
//
//  Toolbar for editor with tools and controls
//

import AppKit

protocol EditorToolbarDelegate: AnyObject {
    func toolbarDidSelectTool(_ tool: EditorTool)
    func toolbarDidChangeColor(_ color: NSColor)
    func toolbarDidChangeLineWidth(_ width: CGFloat)
    func toolbarDidChangeFontSize(_ size: CGFloat)
    func toolbarDidRequestUndo()
    func toolbarDidRequestRedo()
    func toolbarDidRequestSave()
    func toolbarDidRequestCancel()
}

class EditorToolbar: NSView {
    weak var delegate: EditorToolbarDelegate?

    private var selectedTool: EditorTool = .arrow
    private var toolButtons: [EditorTool: NSButton] = [:]

    private var colorWell: NSColorWell!
    private var lineWidthSlider: NSSlider!
    private var lineWidthLabel: NSTextField!
    private var fontSizeSlider: NSSlider!
    private var fontSizeLabel: NSTextField!

    private var undoButton: NSButton!
    private var redoButton: NSButton!
    private var saveButton: NSButton!
    private var cancelButton: NSButton!

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setupToolbar()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupToolbar() {
        wantsLayer = true
        layer?.backgroundColor = NSColor.windowBackgroundColor.withAlphaComponent(0.95).cgColor

        var currentX: CGFloat = 20

        // Tool buttons
        let tools: [(EditorTool, String, String)] = [
            (.select, "hand.point.up", "选择"),
            (.arrow, "arrow.up.right", "箭头"),
            (.text, "textformat", "文字"),
            (.rectangle, "rectangle", "矩形"),
            (.ellipse, "circle", "椭圆"),
            (.mosaic, "squares.below.rectangle", "马赛克")
        ]

        for (tool, iconName, tooltip) in tools {
            let button = createToolButton(tool: tool, iconName: iconName, tooltip: tooltip)
            button.frame = NSRect(x: currentX, y: 10, width: 44, height: 44)
            addSubview(button)
            toolButtons[tool] = button
            currentX += 50
        }

        // Select arrow tool by default
        toolButtons[.arrow]?.state = .on

        currentX += 20

        // Color picker
        let colorLabel = NSTextField(labelWithString: "颜色:")
        colorLabel.frame = NSRect(x: currentX, y: 27, width: 40, height: 20)
        addSubview(colorLabel)
        currentX += 45

        colorWell = NSColorWell(frame: NSRect(x: currentX, y: 17, width: 44, height: 30))
        colorWell.color = .red
        colorWell.target = self
        colorWell.action = #selector(colorChanged)
        addSubview(colorWell)
        currentX += 60

        // Line width slider
        let widthLabel = NSTextField(labelWithString: "粗细:")
        widthLabel.frame = NSRect(x: currentX, y: 27, width: 40, height: 20)
        addSubview(widthLabel)
        currentX += 45

        lineWidthSlider = NSSlider(frame: NSRect(x: currentX, y: 22, width: 100, height: 25))
        lineWidthSlider.minValue = 1
        lineWidthSlider.maxValue = 10
        lineWidthSlider.doubleValue = 3
        lineWidthSlider.target = self
        lineWidthSlider.action = #selector(lineWidthChanged)
        addSubview(lineWidthSlider)
        currentX += 105

        lineWidthLabel = NSTextField(labelWithString: "3")
        lineWidthLabel.frame = NSRect(x: currentX, y: 27, width: 25, height: 20)
        lineWidthLabel.alignment = .center
        addSubview(lineWidthLabel)
        currentX += 40

        // Font size slider (initially hidden)
        let fontLabel = NSTextField(labelWithString: "字号:")
        fontLabel.frame = NSRect(x: currentX, y: 27, width: 40, height: 20)
        addSubview(fontLabel)
        currentX += 45

        fontSizeSlider = NSSlider(frame: NSRect(x: currentX, y: 22, width: 100, height: 25))
        fontSizeSlider.minValue = 12
        fontSizeSlider.maxValue = 48
        fontSizeSlider.doubleValue = 16
        fontSizeSlider.target = self
        fontSizeSlider.action = #selector(fontSizeChanged)
        fontSizeSlider.isHidden = true
        addSubview(fontSizeSlider)
        currentX += 105

        fontSizeLabel = NSTextField(labelWithString: "16")
        fontSizeLabel.frame = NSRect(x: currentX, y: 27, width: 25, height: 20)
        fontSizeLabel.alignment = .center
        fontSizeLabel.isHidden = true
        addSubview(fontSizeLabel)
        currentX += 40

        fontLabel.isHidden = true

        // Right side buttons
        let rightX = bounds.width - 20

        // Cancel button
        cancelButton = createActionButton(title: "取消", systemImage: "xmark.circle")
        cancelButton.frame = NSRect(x: rightX - 90, y: 10, width: 90, height: 44)
        cancelButton.target = self
        cancelButton.action = #selector(cancelClicked)
        addSubview(cancelButton)

        // Save button
        saveButton = createActionButton(title: "完成", systemImage: "checkmark.circle.fill")
        saveButton.frame = NSRect(x: rightX - 200, y: 10, width: 100, height: 44)
        saveButton.target = self
        saveButton.action = #selector(saveClicked)
        saveButton.keyEquivalent = "s"
        saveButton.keyEquivalentModifierMask = .command
        addSubview(saveButton)

        // Redo button
        redoButton = createActionButton(title: "", systemImage: "arrow.uturn.forward")
        redoButton.frame = NSRect(x: rightX - 320, y: 10, width: 44, height: 44)
        redoButton.target = self
        redoButton.action = #selector(redoClicked)
        redoButton.keyEquivalent = "Z"
        redoButton.keyEquivalentModifierMask = [.command, .shift]
        addSubview(redoButton)

        // Undo button
        undoButton = createActionButton(title: "", systemImage: "arrow.uturn.backward")
        undoButton.frame = NSRect(x: rightX - 374, y: 10, width: 44, height: 44)
        undoButton.target = self
        undoButton.action = #selector(undoClicked)
        undoButton.keyEquivalent = "z"
        undoButton.keyEquivalentModifierMask = .command
        addSubview(undoButton)
    }

    private func createToolButton(tool: EditorTool, iconName: String, tooltip: String) -> NSButton {
        let button = NSButton(frame: .zero)
        button.setButtonType(.toggle)
        button.bezelStyle = .regularSquare
        button.image = NSImage(systemSymbolName: iconName, accessibilityDescription: tooltip)
        button.toolTip = tooltip
        button.target = self
        button.action = #selector(toolButtonClicked(_:))
        button.tag = tool.hashValue
        return button
    }

    private func createActionButton(title: String, systemImage: String) -> NSButton {
        let button = NSButton(frame: .zero)
        button.title = title
        button.bezelStyle = .rounded
        if !systemImage.isEmpty {
            button.image = NSImage(systemSymbolName: systemImage, accessibilityDescription: title)
            button.imagePosition = .imageLeading
        }
        return button
    }

    @objc private func toolButtonClicked(_ sender: NSButton) {
        // Deselect all other tool buttons
        for (_, button) in toolButtons {
            if button != sender {
                button.state = .off
            }
        }

        // Ensure this button is selected
        sender.state = .on

        // Determine which tool was clicked
        for (tool, button) in toolButtons {
            if button == sender {
                selectedTool = tool
                delegate?.toolbarDidSelectTool(tool)

                // Show/hide font size controls based on tool
                let showFontSize = (tool == .text)
                fontSizeSlider.isHidden = !showFontSize
                fontSizeLabel.isHidden = !showFontSize

                break
            }
        }
    }

    @objc private func colorChanged() {
        delegate?.toolbarDidChangeColor(colorWell.color)
    }

    @objc private func lineWidthChanged() {
        let width = CGFloat(lineWidthSlider.doubleValue)
        lineWidthLabel.stringValue = String(format: "%.0f", width)
        delegate?.toolbarDidChangeLineWidth(width)
    }

    @objc private func fontSizeChanged() {
        let size = CGFloat(fontSizeSlider.doubleValue)
        fontSizeLabel.stringValue = String(format: "%.0f", size)
        delegate?.toolbarDidChangeFontSize(size)
    }

    @objc private func undoClicked() {
        delegate?.toolbarDidRequestUndo()
    }

    @objc private func redoClicked() {
        delegate?.toolbarDidRequestRedo()
    }

    @objc private func saveClicked() {
        delegate?.toolbarDidRequestSave()
    }

    @objc private func cancelClicked() {
        delegate?.toolbarDidRequestCancel()
    }

    func setUndoEnabled(_ enabled: Bool) {
        undoButton.isEnabled = enabled
    }

    func setRedoEnabled(_ enabled: Bool) {
        redoButton.isEnabled = enabled
    }
}
