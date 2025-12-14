# 窗口截图功能文档

## 功能概述

SwiftScreenShot 现已支持窗口截图模式，可以智能检测并捕获单个窗口的截图。该功能使用 macOS 的 ScreenCaptureKit 和 CGWindowListCopyWindowInfo API 实现。

## 核心功能特性

### 1. 智能窗口检测
- 鼠标悬停时自动检测窗口边界
- 实时高亮显示当前悬停的窗口
- 支持多窗口重叠情况（自动选择最上层窗口）

### 2. 可视化交互
- 蓝色高亮边框标识选中窗口
- 虚线内边框增强视觉效果
- 显示窗口信息（应用名称、窗口标题、尺寸）
- 点击即可完成截图

### 3. 窗口阴影支持
- 可选择是否包含窗口阴影
- 在设置中提供"包含窗口阴影"开关
- 阴影区域自动计算（默认 20px 边距）

### 4. 快捷键支持
- 默认快捷键：⌃⌘W (Control + Command + W)
- 可在设置中自定义快捷键
- 支持全局热键触发

## 实现架构

### 新增文件

#### 1. WindowInfo.swift
窗口信息模型，存储窗口的核心属性：
- `windowID`: CGWindowID 唯一标识符
- `bounds`: 窗口在屏幕上的位置和大小
- `name`: 窗口标题
- `ownerName`: 所属应用名称
- `layer`: 窗口层级
- `isOnScreen`: 是否在屏幕上可见
- `alpha`: 窗口透明度

提供了以下辅助方法：
- `contains(point:)`: 判断点是否在窗口内
- `isValidForScreenshot`: 验证窗口是否适合截图

#### 2. WindowDetector.swift
窗口检测和管理类，负责：
- 使用 `CGWindowListCopyWindowInfo` 获取所有窗口列表
- 根据鼠标位置查找对应窗口
- 获取窗口边界（含/不含阴影）
- 使用 ScreenCaptureKit 获取可截图窗口
- 通过窗口 ID 查找 SCWindow 对象

关键方法：
- `getAllWindows()`: 获取所有可见窗口
- `windowAtPoint(_:)`: 查找指定位置的窗口
- `getShareableWindows()`: 获取 SCWindow 列表
- `getWindowBounds(windowID:includeShadow:)`: 获取窗口边界

### 修改的文件

#### 1. ScreenshotMode.swift
添加了新的枚举值：
```swift
case window  // 窗口截图模式
```

#### 2. HotKeyConfig.swift
添加窗口截图默认快捷键：
```swift
static let defaultWindowScreenshot = HotKeyConfig(
    keyCode: 13,  // 'W' key
    modifiers: UInt32(cmdKey | controlKey)
)
```

扩展了 `HotKeyType` 枚举：
```swift
case windowScreenshot = "windowScreenshot"
```

#### 3. ScreenshotSettings.swift
添加了两个新配置项：
```swift
@Published var windowScreenshotHotKey: HotKeyConfig
@Published var includeWindowShadow: Bool
```

默认值：
- 窗口截图快捷键：⌃⌘W
- 包含窗口阴影：true

#### 4. SelectionView.swift
扩展支持窗口模式：
- 添加 `mode` 参数（.region 或 .window）
- 新增 `WindowDetector` 实例
- 实现鼠标追踪（NSTrackingArea）
- 新增 `mouseMoved(with:)` 处理鼠标移动
- 修改 `mouseDown(with:)` 支持窗口选择
- 新增 `drawWindowHighlight(for:)` 绘制窗口高亮
- 新增 `drawWindowLabel(for:in:)` 绘制窗口信息标签
- 添加坐标转换方法：
  - `convertToScreenCoordinates(_:)`: 视图坐标→屏幕坐标
  - `convertFromScreenCoordinates(_:)`: 屏幕坐标→视图坐标

#### 5. SelectionWindow.swift
添加窗口模式支持：
- 新增 `mode` 参数
- 添加 `onWindowSelected` 回调
- 新增 `handleWindowSelection(window:)` 方法
- 发送 `.didCompleteWindowSelection` 通知

#### 6. ScreenshotEngine.swift
添加窗口截图方法：
```swift
func captureWindow(windowInfo: WindowInfo, includeShadow: Bool) async throws -> NSImage
func captureWindow(windowID: CGWindowID, includeShadow: Bool) async throws -> NSImage
```

实现细节：
- 使用 `SCContentFilter(desktopIndependentWindow:)` 创建窗口过滤器
- 配置 Retina 支持（2x 缩放）
- 根据设置添加阴影边距
- 返回正确尺寸的 NSImage

#### 7. MenuBarController.swift
添加窗口截图菜单项：
- 新增 `windowScreenshotMenuItem`
- 添加 `takeWindowScreenshot()` 方法
- 添加 `getWindowScreenshotTitle()` 方法
- 更新 `updateMenuItemTitles()` 包含窗口截图

#### 8. AppDelegate.swift
集成窗口截图功能：
- 添加 `windowScreenshotHotKeyID` 追踪
- 注册 `.triggerWindowScreenshot` 通知监听
- 注册 `.didCompleteWindowSelection` 通知监听
- 添加 `handleTriggerWindowScreenshot()` 处理器
- 添加 `handleDidCompleteWindowSelection(_:)` 处理器
- 修改 `startScreenshotProcess(mode:)` 支持窗口模式
- 添加 `captureSelectedWindow(_:)` 方法
- 在 `registerHotKeys()` 中注册窗口截图快捷键

#### 9. Extensions.swift
添加新的通知名称：
```swift
static let triggerWindowScreenshot = Notification.Name("triggerWindowScreenshot")
static let didCompleteWindowSelection = Notification.Name("didCompleteWindowSelection")
```

#### 10. SettingsView.swift
添加窗口截图设置界面：
- 新增"窗口截图设置"部分
- 添加"包含窗口阴影"开关
- 添加窗口截图说明文字
- 在快捷键设置中添加窗口截图快捷键配置
- 增加窗口高度至 700px

## 使用方法

### 1. 使用快捷键
1. 按下 ⌃⌘W（或自定义快捷键）
2. 屏幕进入窗口选择模式
3. 移动鼠标到要截图的窗口上
4. 窗口会以蓝色高亮边框显示
5. 点击鼠标完成截图
6. 按 ESC 取消

### 2. 使用菜单栏
1. 点击菜单栏图标
2. 选择"窗口截图 (⌃⌘W)"
3. 按照上述步骤 2-6 操作

### 3. 自定义设置
在"设置"窗口中：
- **窗口截图设置** → 勾选/取消"包含窗口阴影"
- **快捷键设置** → 点击"窗口截图"行，按下新的快捷键组合

## 技术细节

### 窗口检测流程
1. `CGWindowListCopyWindowInfo` 获取所有窗口信息
2. 过滤条件：
   - `isOnScreen = true`
   - `alpha > 0.1`
   - 尺寸 > 50x50
   - `layer >= 0`
3. 按窗口层级排序（layer 值越大越靠前）
4. 使用 `contains(point:)` 查找鼠标位置的窗口

### 窗口截图流程
1. 通过 `WindowDetector.getShareableWindows()` 获取 SCWindow 列表
2. 根据 windowID 查找对应的 SCWindow
3. 创建 `SCContentFilter(desktopIndependentWindow:)`
4. 配置 `SCStreamConfiguration`:
   - width/height: 窗口尺寸 × 2（Retina）
   - showsCursor: false
   - scalesToFit: false
5. 调用 `SCScreenshotManager.captureImage()`
6. 如果包含阴影，调整最终图像尺寸（+40px 宽高）

### 坐标系统
macOS 使用多种坐标系统：
- **屏幕坐标**：原点在左下角（主显示器）
- **窗口坐标**：原点在左下角（窗口本身）
- **视图坐标**：原点在左上角（NSView）

转换逻辑：
```swift
// 视图 → 屏幕
let windowPoint = view.convert(point, to: nil)
let screenPoint = window.convertToScreen(CGRect(origin: windowPoint, size: .zero)).origin

// 屏幕 → 视图
let flippedY = screenFrame.height - rect.origin.y - rect.height
let viewY = flippedY - window.frame.origin.y
```

### 性能优化
1. 窗口列表缓存在鼠标移动时重用
2. 仅在窗口模式下启用鼠标追踪
3. 使用异步 API 避免阻塞主线程
4. 窗口过滤减少不必要的检测

## 权限要求

窗口截图功能需要以下权限：
- **屏幕录制权限**：已在现有代码中请求
- 首次使用时系统会提示授权
- 可在"系统偏好设置 → 安全性与隐私 → 屏幕录制"中管理

## 已知限制

1. **系统窗口限制**
   - 某些系统窗口可能无法检测或截图
   - Dock、菜单栏等系统 UI 元素不可截图

2. **最小化窗口**
   - 最小化的窗口不会出现在检测列表中
   - 只能截图当前屏幕可见的窗口

3. **多显示器**
   - 窗口检测仅在当前屏幕有效
   - 跨屏幕的窗口按主显示器处理

4. **透明窗口**
   - alpha < 0.1 的窗口被过滤
   - 完全透明的窗口无法选择

## 故障排除

### 问题：无法检测到窗口
**解决方案**：
1. 检查屏幕录制权限是否已授予
2. 确认窗口在当前屏幕可见
3. 尝试重启应用程序

### 问题：窗口边界不准确
**解决方案**：
1. 检查是否为 Retina 显示器
2. 确认窗口未处于动画过程中
3. 尝试关闭窗口透明效果

### 问题：快捷键冲突
**解决方案**：
1. 打开设置窗口
2. 在"快捷键设置"中重新设置
3. 选择未被其他应用占用的组合键

## 未来改进方向

1. **功能增强**
   - 支持多窗口批量截图
   - 添加窗口截图历史记录
   - 支持截图后编辑窗口内容

2. **用户体验**
   - 添加窗口预览功能
   - 支持窗口搜索/过滤
   - 添加窗口截图动画效果

3. **性能优化**
   - 优化窗口检测算法
   - 减少内存占用
   - 提升大窗口截图速度

## 相关文件清单

### 新增文件
- `Sources/SwiftScreenShot/Models/WindowInfo.swift`
- `Sources/SwiftScreenShot/Core/WindowDetector.swift`

### 修改文件
- `Sources/SwiftScreenShot/Models/ScreenshotMode.swift`
- `Sources/SwiftScreenShot/Models/HotKeyConfig.swift`
- `Sources/SwiftScreenShot/Models/ScreenshotSettings.swift`
- `Sources/SwiftScreenShot/UI/Selection/SelectionView.swift`
- `Sources/SwiftScreenShot/UI/Selection/SelectionWindow.swift`
- `Sources/SwiftScreenShot/Core/ScreenshotEngine.swift`
- `Sources/SwiftScreenShot/UI/MenuBar/MenuBarController.swift`
- `Sources/SwiftScreenShot/App/AppDelegate.swift`
- `Sources/SwiftScreenShot/Utilities/Extensions.swift`
- `Sources/SwiftScreenShot/UI/Settings/SettingsView.swift`

## 代码示例

### 使用 WindowDetector
```swift
let detector = WindowDetector()

// 获取所有窗口
let windows = detector.getAllWindows()

// 查找鼠标位置的窗口
let mouseLocation = NSEvent.mouseLocation
if let window = detector.windowAtPoint(mouseLocation) {
    print("Found window: \(window.description)")
}
```

### 捕获窗口截图
```swift
let engine = ScreenshotEngine()
let settings = ScreenshotSettings()

Task {
    do {
        let screenshot = try await engine.captureWindow(
            windowInfo: windowInfo,
            includeShadow: settings.includeWindowShadow
        )
        // 处理截图
    } catch {
        print("Failed to capture window: \(error)")
    }
}
```

## 测试建议

1. **功能测试**
   - 测试不同应用的窗口截图
   - 测试重叠窗口的选择
   - 测试阴影开关效果

2. **边界测试**
   - 测试最小化窗口
   - 测试透明窗口
   - 测试多显示器场景

3. **性能测试**
   - 测试大量窗口时的性能
   - 测试高分辨率窗口截图
   - 测试内存占用情况

---

**版本**: 1.0.0
**最后更新**: 2025-12-14
**作者**: SwiftScreenShot Team
