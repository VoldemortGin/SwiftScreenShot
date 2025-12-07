# 核心技术实现示例

## 1. 全局快捷键管理

### HotKeyManager.swift 示例
```swift
import Carbon
import Cocoa

class HotKeyManager {
    private var hotKeyRef: EventHotKeyRef?
    private var eventHandler: EventHandlerRef?
    var onHotKeyPressed: (() -> Void)?

    func register(key: UInt32, modifiers: UInt32) {
        // 注册快捷键
        var hotKeyID = EventHotKeyID(signature: 0x53535353, id: 1) // 'SSSS' for SwiftScreenShot
        var eventType = EventTypeSpec(eventClass: OSType(kEventClassKeyboard),
                                       eventKind: UInt32(kEventHotKeyPressed))

        // 安装事件处理器
        InstallEventHandler(GetApplicationEventTarget(),
                            { (nextHandler, theEvent, userData) -> OSStatus in
            let manager = Unmanaged<HotKeyManager>
                .fromOpaque(userData!)
                .takeUnretainedValue()
            manager.onHotKeyPressed?()
            return noErr
        }, 1, &eventType,
        Unmanaged.passUnretained(self).toOpaque(),
        &eventHandler)

        // 注册热键 (Ctrl+Cmd+A = cmdKey + controlKey + 0)
        RegisterEventHotKey(key,                    // keyCode for 'A' = 0
                           modifiers,               // cmdKey + controlKey
                           hotKeyID,
                           GetApplicationEventTarget(),
                           0,
                           &hotKeyRef)
    }

    func unregister() {
        if let hotKeyRef = hotKeyRef {
            UnregisterEventHotKey(hotKeyRef)
        }
        if let eventHandler = eventHandler {
            RemoveEventHandler(eventHandler)
        }
    }

    deinit {
        unregister()
    }
}

// 使用示例
let hotKeyManager = HotKeyManager()
hotKeyManager.register(key: 0, modifiers: UInt32(cmdKey | controlKey))
hotKeyManager.onHotKeyPressed = {
    print("快捷键被触发！")
    // 启动截图流程
}
```

## 2. 截图引擎

### ScreenshotEngine.swift 示例
```swift
import ScreenCaptureKit
import AppKit

class ScreenshotEngine {

    /// 捕获指定区域的截图
    func captureRegion(rect: CGRect, display: SCDisplay) async throws -> NSImage {
        // 创建截图配置
        let filter = SCContentFilter(display: display, excludingWindows: [])

        let config = SCStreamConfiguration()
        config.width = Int(rect.width * display.scaleFactor)
        config.height = Int(rect.height * display.scaleFactor)
        config.sourceRect = rect
        config.scalesToFit = false
        config.showsCursor = false

        // 执行截图
        let image = try await SCScreenshotManager.captureImage(
            contentFilter: filter,
            configuration: config
        )

        // 转换为 NSImage
        let nsImage = NSImage(cgImage: image, size: rect.size)
        return nsImage
    }

    /// 获取所有显示器
    func getDisplays() async throws -> [SCDisplay] {
        let content = try await SCShareableContent.excludingDesktopWindows(
            false,
            onScreenWindowsOnly: true
        )
        return content.displays
    }

    /// 捕获主显示器全屏
    func captureMainDisplay() async throws -> NSImage {
        let displays = try await getDisplays()
        guard let mainDisplay = displays.first else {
            throw ScreenshotError.noDisplay
        }

        let rect = CGRect(
            x: 0,
            y: 0,
            width: CGFloat(mainDisplay.width),
            height: CGFloat(mainDisplay.height)
        )

        return try await captureRegion(rect: rect, display: mainDisplay)
    }
}

enum ScreenshotError: Error {
    case noDisplay
    case permissionDenied
    case captureFailed
}
```

## 3. 选区窗口

### SelectionWindow.swift 示例
```swift
import AppKit

class SelectionWindow: NSWindow {
    private var selectionView: SelectionView!
    private let screenFrame: CGRect
    private var backgroundImage: NSImage?

    init(screen: NSScreen, backgroundImage: NSImage?) {
        self.screenFrame = screen.frame
        self.backgroundImage = backgroundImage

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
        // 窗口配置
        self.level = .screenSaver  // 显示在所有窗口之上
        self.backgroundColor = .clear
        self.isOpaque = false
        self.hasShadow = false
        self.ignoresMouseEvents = false
        self.acceptsMouseMovedEvents = true

        // 全屏和空间行为
        self.collectionBehavior = [
            .canJoinAllSpaces,
            .fullScreenAuxiliary,
            .transient
        ]

        // 设置为关键窗口以接收键盘事件
        self.makeKeyAndOrderFront(nil)
    }

    private func setupSelectionView() {
        selectionView = SelectionView(
            frame: self.contentView!.bounds,
            backgroundImage: backgroundImage
        )
        selectionView.onComplete = { [weak self] rect in
            self?.handleSelection(rect: rect)
        }
        selectionView.onCancel = { [weak self] in
            self?.close()
        }

        self.contentView = selectionView
    }

    private func handleSelection(rect: CGRect) {
        // 将窗口坐标转换为屏幕坐标
        let screenRect = convertToScreenCoordinates(rect)

        // 通知代理
        NotificationCenter.default.post(
            name: .didCompleteSelection,
            object: screenRect
        )

        self.close()
    }

    private func convertToScreenCoordinates(_ rect: CGRect) -> CGRect {
        // macOS 坐标系统：原点在左下角
        // 需要转换为正确的屏幕坐标
        let flippedY = screenFrame.height - rect.origin.y - rect.height

        return CGRect(
            x: screenFrame.origin.x + rect.origin.x,
            y: screenFrame.origin.y + flippedY,
            width: rect.width,
            height: rect.height
        )
    }
}

extension Notification.Name {
    static let didCompleteSelection = Notification.Name("didCompleteSelection")
}
```

### SelectionView.swift 示例
```swift
import AppKit

class SelectionView: NSView {
    private var startPoint: CGPoint?
    private var currentPoint: CGPoint?
    private let backgroundImage: NSImage?

    var onComplete: ((CGRect) -> Void)?
    var onCancel: (() -> Void)?

    init(frame: NSRect, backgroundImage: NSImage?) {
        self.backgroundImage = backgroundImage
        super.init(frame: frame)

        // 监听键盘事件
        NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            self?.handleKeyDown(event)
            return event
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
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

        if rect.width > 5 && rect.height > 5 {  // 最小选区大小
            onComplete?(rect)
        }

        startPoint = nil
        currentPoint = nil
    }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        // 绘制半透明背景
        NSColor.black.withAlphaComponent(0.3).setFill()
        dirtyRect.fill()

        // 如果有背景图片，绘制它
        if let bgImage = backgroundImage {
            bgImage.draw(in: self.bounds)
        }

        // 绘制选区
        if let start = startPoint, let end = currentPoint {
            let selectionRect = normalizedRect(from: start, to: end)

            // 清除选区内的遮罩（显示原始屏幕）
            NSColor.clear.setFill()
            selectionRect.fill(using: .copy)

            // 绘制选区边框
            NSColor.white.setStroke()
            let border = NSBezierPath(rect: selectionRect)
            border.lineWidth = 2.0
            border.stroke()

            // 绘制尺寸信息
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

        let attributedString = NSAttributedString(string: sizeText, attributes: attributes)
        let textSize = attributedString.size()

        // 显示在选区右下角
        let textRect = CGRect(
            x: rect.maxX - textSize.width - 5,
            y: rect.minY + 5,
            width: textSize.width + 8,
            height: textSize.height + 4
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
}
```

## 4. 输出管理

### OutputManager.swift 示例
```swift
import AppKit

class OutputManager {
    private let settings: ScreenshotSettings

    init(settings: ScreenshotSettings) {
        self.settings = settings
    }

    /// 处理截图输出
    func processScreenshot(_ image: NSImage) {
        // 1. 复制到剪贴板（总是执行）
        copyToClipboard(image)

        // 2. 保存到文件（如果设置中启用）
        if settings.shouldSaveToFile {
            saveToFile(image)
        }
    }

    /// 复制图像到剪贴板
    private func copyToClipboard(_ image: NSImage) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.writeObjects([image])
    }

    /// 保存图像到文件
    private func saveToFile(_ image: NSImage) {
        guard let savePath = settings.savePath else { return }

        // 生成文件名
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd_HHmmss"
        let timestamp = formatter.string(from: Date())
        let fileName = "Screenshot_\(timestamp).\(settings.imageFormat.fileExtension)"

        let fileURL = savePath.appendingPathComponent(fileName)

        // 转换图像格式并保存
        if let imageData = imageData(from: image, format: settings.imageFormat) {
            try? imageData.write(to: fileURL)

            // 可选：显示通知
            showNotification(fileName: fileName, path: fileURL)
        }
    }

    /// 转换图像为指定格式的数据
    private func imageData(from image: NSImage, format: ImageFormat) -> Data? {
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

    /// 显示保存成功通知
    private func showNotification(fileName: String, path: URL) {
        let notification = NSUserNotification()
        notification.title = "截图已保存"
        notification.informativeText = fileName
        notification.soundName = NSUserNotificationDefaultSoundName

        // 点击通知打开文件位置
        notification.userInfo = ["path": path.path]

        NSUserNotificationCenter.default.deliver(notification)
    }
}

// 图像格式枚举
enum ImageFormat {
    case png
    case jpeg(quality: Double)  // 0.0 - 1.0

    var fileExtension: String {
        switch self {
        case .png: return "png"
        case .jpeg: return "jpg"
        }
    }
}
```

## 5. 设置管理

### ScreenshotSettings.swift 示例
```swift
import Foundation

class ScreenshotSettings: ObservableObject {
    @Published var shouldSaveToFile: Bool {
        didSet { UserDefaults.standard.set(shouldSaveToFile, forKey: "shouldSaveToFile") }
    }

    @Published var savePath: URL? {
        didSet {
            if let path = savePath {
                UserDefaults.standard.set(path.path, forKey: "savePath")
            }
        }
    }

    @Published var imageFormat: ImageFormat {
        didSet { UserDefaults.standard.set(imageFormat.rawValue, forKey: "imageFormat") }
    }

    @Published var launchAtLogin: Bool {
        didSet {
            UserDefaults.standard.set(launchAtLogin, forKey: "launchAtLogin")
            configureLaunchAtLogin(launchAtLogin)
        }
    }

    init() {
        self.shouldSaveToFile = UserDefaults.standard.bool(forKey: "shouldSaveToFile")

        if let pathString = UserDefaults.standard.string(forKey: "savePath") {
            self.savePath = URL(fileURLWithPath: pathString)
        } else {
            // 默认保存到桌面
            self.savePath = FileManager.default.urls(
                for: .desktopDirectory,
                in: .userDomainMask
            ).first
        }

        let formatRaw = UserDefaults.standard.string(forKey: "imageFormat") ?? "png"
        self.imageFormat = ImageFormat(rawValue: formatRaw) ?? .png

        self.launchAtLogin = UserDefaults.standard.bool(forKey: "launchAtLogin")
    }

    private func configureLaunchAtLogin(_ enabled: Bool) {
        // 使用 SMAppService (macOS 13+) 或 LSSharedFileList (旧版本)
        // 这里简化示例
        let appService = SMAppService.mainApp

        do {
            if enabled {
                try appService.register()
            } else {
                try appService.unregister()
            }
        } catch {
            print("Failed to configure launch at login: \(error)")
        }
    }
}

extension ImageFormat: RawRepresentable {
    var rawValue: String {
        switch self {
        case .png: return "png"
        case .jpeg: return "jpeg"
        }
    }

    init?(rawValue: String) {
        switch rawValue {
        case "png": self = .png
        case "jpeg": self = .jpeg(quality: 0.9)
        default: return nil
        }
    }
}
```

## 6. 菜单栏控制器

### MenuBarController.swift 示例
```swift
import AppKit

class MenuBarController {
    private var statusItem: NSStatusItem?
    private let menu = NSMenu()

    init() {
        setupStatusItem()
        setupMenu()
    }

    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(
            withLength: NSStatusItem.squareLength
        )

        if let button = statusItem?.button {
            // 设置图标（需要准备一个图标）
            button.image = NSImage(
                systemSymbolName: "camera.viewfinder",
                accessibilityDescription: "截图"
            )
        }

        statusItem?.menu = menu
    }

    private func setupMenu() {
        // 截图菜单项
        let screenshotItem = NSMenuItem(
            title: "截图 (⌃⌘A)",
            action: #selector(takeScreenshot),
            keyEquivalent: ""
        )
        screenshotItem.target = self
        menu.addItem(screenshotItem)

        menu.addItem(NSMenuItem.separator())

        // 设置菜单项
        let settingsItem = NSMenuItem(
            title: "设置...",
            action: #selector(openSettings),
            keyEquivalent: ","
        )
        settingsItem.target = self
        menu.addItem(settingsItem)

        menu.addItem(NSMenuItem.separator())

        // 退出菜单项
        let quitItem = NSMenuItem(
            title: "退出",
            action: #selector(quitApp),
            keyEquivalent: "q"
        )
        quitItem.target = self
        menu.addItem(quitItem)
    }

    @objc private func takeScreenshot() {
        NotificationCenter.default.post(name: .triggerScreenshot, object: nil)
    }

    @objc private func openSettings() {
        NotificationCenter.default.post(name: .openSettings, object: nil)
    }

    @objc private func quitApp() {
        NSApplication.shared.terminate(nil)
    }
}

extension Notification.Name {
    static let triggerScreenshot = Notification.Name("triggerScreenshot")
    static let openSettings = Notification.Name("openSettings")
}
```

## 7. 权限管理

### PermissionManager.swift 示例
```swift
import ScreenCaptureKit
import AppKit

class PermissionManager {

    /// 检查屏幕录制权限
    static func checkScreenRecordingPermission() -> Bool {
        // macOS 10.15+ 需要屏幕录制权限
        if #available(macOS 10.15, *) {
            return CGPreflightScreenCaptureAccess()
        }
        return true
    }

    /// 请求屏幕录制权限
    static func requestScreenRecordingPermission() {
        CGRequestScreenCaptureAccess()
    }

    /// 显示权限提示对话框
    static func showPermissionAlert() {
        let alert = NSAlert()
        alert.messageText = "需要屏幕录制权限"
        alert.informativeText = """
        SwiftScreenShot 需要屏幕录制权限来实现截图功能。

        请在"系统偏好设置 > 安全性与隐私 > 隐私 > 屏幕录制"中，
        勾选 SwiftScreenShot 并重启应用。
        """
        alert.alertStyle = .warning
        alert.addButton(withTitle: "打开系统偏好设置")
        alert.addButton(withTitle: "稍后")

        let response = alert.runModal()

        if response == .alertFirstButtonReturn {
            openSystemPreferences()
        }
    }

    /// 打开系统偏好设置的屏幕录制页面
    private static func openSystemPreferences() {
        let url: URL

        if #available(macOS 13.0, *) {
            // macOS 13+ 使用新的设置 URL
            url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture")!
        } else {
            url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture")!
        }

        NSWorkspace.shared.open(url)
    }
}
```

## 核心流程图

```
用户按下 Ctrl+Cmd+A
        ↓
HotKeyManager 触发事件
        ↓
ScreenshotEngine 捕获屏幕
        ↓
SelectionWindow 显示选区界面
        ↓
用户拖拽选择区域
        ↓
SelectionView 捕获选区坐标
        ↓
ImageProcessor 裁剪图像
        ↓
OutputManager 处理输出
        ├→ 复制到剪贴板（默认）
        └→ 保存到文件（可选）
```

## 关键技术点总结

1. **全局快捷键**: Carbon Event Manager + Bridging Header
2. **截图**: ScreenCaptureKit (macOS 12.3+)
3. **选区界面**: NSWindow + NSView 自定义绘制
4. **坐标系统**: macOS 原点在左下角，需要坐标转换
5. **权限**: 屏幕录制权限 (Info.plist + 运行时检查)
6. **菜单栏**: NSStatusItem + NSMenu
7. **设置持久化**: UserDefaults
8. **多显示器**: NSScreen.screens 处理

这些代码示例展示了项目的核心技术实现，可以直接作为开发的参考模板。
