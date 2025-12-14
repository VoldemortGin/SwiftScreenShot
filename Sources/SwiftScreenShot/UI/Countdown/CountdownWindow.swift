//
//  CountdownWindow.swift
//  SwiftScreenShot
//
//  Countdown window for delayed screenshot
//

import AppKit

class CountdownWindow: NSWindow {

    private let countdownLabel: NSTextField
    private let messageLabel: NSTextField
    private let cancelButton: NSButton

    init(initialSeconds: Int) {
        // Create labels
        countdownLabel = NSTextField(labelWithString: "\(initialSeconds)")
        messageLabel = NSTextField(labelWithString: "秒后截图")

        // Create cancel button
        cancelButton = NSButton(title: "取消 (ESC)", target: nil, action: #selector(cancelCountdown))

        // Create window
        let windowRect = NSRect(x: 0, y: 0, width: 300, height: 200)
        super.init(
            contentRect: windowRect,
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )

        setupWindow()
        setupUI()
    }

    private func setupWindow() {
        // Window properties
        backgroundColor = NSColor.black.withAlphaComponent(0.85)
        isOpaque = false
        hasShadow = true
        level = .floating
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]

        // Make it float above everything
        ignoresMouseEvents = false

        // Rounded corners
        contentView?.wantsLayer = true
        contentView?.layer?.cornerRadius = 16
        contentView?.layer?.masksToBounds = true
    }

    private func setupUI() {
        guard let contentView = contentView else { return }

        // Configure countdown label (large number)
        countdownLabel.font = NSFont.systemFont(ofSize: 80, weight: .bold)
        countdownLabel.textColor = .white
        countdownLabel.alignment = .center
        countdownLabel.isBordered = false
        countdownLabel.isBezeled = false
        countdownLabel.drawsBackground = false
        countdownLabel.isEditable = false
        countdownLabel.isSelectable = false

        // Configure message label
        messageLabel.font = NSFont.systemFont(ofSize: 20, weight: .medium)
        messageLabel.textColor = NSColor.white.withAlphaComponent(0.9)
        messageLabel.alignment = .center
        messageLabel.isBordered = false
        messageLabel.isBezeled = false
        messageLabel.drawsBackground = false
        messageLabel.isEditable = false
        messageLabel.isSelectable = false

        // Configure cancel button
        cancelButton.target = self
        cancelButton.bezelStyle = .rounded
        cancelButton.contentTintColor = .white

        // Layout
        let stackView = NSStackView(views: [countdownLabel, messageLabel, cancelButton])
        stackView.orientation = .vertical
        stackView.alignment = .centerX
        stackView.spacing = 16
        stackView.translatesAutoresizingMaskIntoConstraints = false

        contentView.addSubview(stackView)

        NSLayoutConstraint.activate([
            stackView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            stackView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            stackView.widthAnchor.constraint(equalTo: contentView.widthAnchor, multiplier: 0.8),

            countdownLabel.widthAnchor.constraint(equalTo: stackView.widthAnchor),
            messageLabel.widthAnchor.constraint(equalTo: stackView.widthAnchor),
            cancelButton.widthAnchor.constraint(equalToConstant: 120)
        ])
    }

    func updateCountdown(seconds: Int) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }

            self.countdownLabel.stringValue = "\(seconds)"

            // Add pulse animation
            self.animatePulse()

            // Change color when time is running out
            if seconds <= 1 {
                self.countdownLabel.textColor = NSColor.systemRed
            } else if seconds <= 3 {
                self.countdownLabel.textColor = NSColor.systemYellow
            } else {
                self.countdownLabel.textColor = .white
            }
        }
    }

    private func animatePulse() {
        NSAnimationContext.runAnimationGroup({ context in
            context.duration = 0.15
            context.timingFunction = CAMediaTimingFunction(name: .easeOut)

            countdownLabel.animator().alphaValue = 0.5
        }, completionHandler: {
            NSAnimationContext.runAnimationGroup({ context in
                context.duration = 0.15
                context.timingFunction = CAMediaTimingFunction(name: .easeIn)

                self.countdownLabel.animator().alphaValue = 1.0
            })
        })
    }

    @objc private func cancelCountdown() {
        NotificationCenter.default.post(name: .cancelDelayedScreenshot, object: nil)
    }

    override var canBecomeKey: Bool {
        return true
    }

    override var canBecomeMain: Bool {
        return true
    }
}
