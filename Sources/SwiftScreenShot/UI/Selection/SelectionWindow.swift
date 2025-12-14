//
//  SelectionWindow.swift
//  SwiftScreenShot
//
//  Full-screen selection window overlay
//

import AppKit

class SelectionWindow: NSWindow {
    private var selectionView: SelectionView!
    private let screenFrame: CGRect
    private var backgroundImage: NSImage?
    private let mode: ScreenshotMode

    init(screen: NSScreen, backgroundImage: NSImage?, mode: ScreenshotMode = .region) {
        self.screenFrame = screen.frame
        self.backgroundImage = backgroundImage
        self.mode = mode

        super.init(
            contentRect: screenFrame,
            styleMask: [.borderless, .fullSizeContentView],
            backing: .buffered,
            defer: false,
            screen: screen
        )

        setupWindow()
        setupSelectionView()
    }

    private func setupWindow() {
        // Window configuration
        self.level = .screenSaver  // Display above all windows
        self.backgroundColor = .clear
        self.isOpaque = false
        self.hasShadow = false
        self.ignoresMouseEvents = false
        self.acceptsMouseMovedEvents = true

        // Fullscreen and spaces behavior
        self.collectionBehavior = [
            .canJoinAllSpaces,
            .fullScreenAuxiliary,
            .transient
        ]

        // Set as key window to receive keyboard events
        self.makeKeyAndOrderFront(nil)
    }

    private func setupSelectionView() {
        selectionView = SelectionView(
            frame: self.contentView!.bounds,
            backgroundImage: backgroundImage,
            mode: mode
        )
        selectionView.onComplete = { [weak self] rect in
            self?.handleSelection(rect: rect)
        }
        selectionView.onCancel = { [weak self] in
            self?.close()
        }
        selectionView.onWindowSelected = { [weak self] window in
            self?.handleWindowSelection(window: window)
        }

        self.contentView = selectionView
    }

    private func handleSelection(rect: CGRect) {
        // Convert window coordinates to screen coordinates
        let screenRect = convertToScreenCoordinates(rect)

        // Notify via notification center
        NotificationCenter.default.post(
            name: .didCompleteSelection,
            object: screenRect
        )

        self.close()
    }

    private func handleWindowSelection(window: WindowInfo) {
        // Notify via notification center
        NotificationCenter.default.post(
            name: .didCompleteWindowSelection,
            object: window
        )

        self.close()
    }

    private func convertToScreenCoordinates(_ rect: CGRect) -> CGRect {
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
