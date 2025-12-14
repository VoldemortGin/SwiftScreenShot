# 声音反馈功能文档

## 功能概述

SwiftScreenShot 现在支持在截图成功时播放音效，为用户提供即时的听觉反馈。

## 实现细节

### 核心组件

#### 1. SoundManager (`Sources/SwiftScreenShot/Core/SoundManager.swift`)

声音管理器负责处理所有音效播放功能。

**特性：**
- 单例模式设计，确保全局只有一个实例
- 自动尝试使用 macOS 系统相机快门音效
- 如果系统音效不可用，回退到系统 "Pop" 音效
- 支持自定义音效文件（AIFF/WAV 格式）
- 异步播放，不阻塞主线程

**主要方法：**
```swift
// 播放截图音效（基于用户设置）
func playCaptureIfEnabled(enabled: Bool)

// 直接播放系统快门音效
func playSystemShutterSound()

// 播放自定义音效
func playCapture()
```

#### 2. ScreenshotSettings 更新

新增属性：
```swift
@Published var playSoundOnCapture: Bool
```

**持久化：**
- 设置保存在 UserDefaults 中
- 默认值为 `true`（启用音效）
- 自动同步到磁盘

#### 3. OutputManager 集成

在 `processScreenshot()` 方法中，音效播放是第一步操作：

```swift
func processScreenshot(_ image: NSImage) {
    // 1. 播放截图音效（如果启用）
    soundManager.playCaptureIfEnabled(enabled: settings.playSoundOnCapture)

    // 2. 复制到剪贴板
    copyToClipboard(image)

    // 3. 保存到文件（如果启用）
    if settings.shouldSaveToFile {
        saveToFile(image)
    }
}
```

#### 4. UI 设置界面

在设置窗口的"应用设置"部分添加了新的开关：

```swift
Toggle("播放截图音效", isOn: $settings.playSoundOnCapture)
    .help("截图成功时播放快门音效")
```

## 音效来源

### 优先级顺序

1. **macOS 系统相机快门音效**（优先）
   - 路径：`/System/Library/Components/CoreAudio.component/Contents/SharedSupport/SystemSounds/system/begin_record.caf`
   - 专业的相机快门声音

2. **自定义音效文件**（如果提供）
   - 支持格式：AIFF、WAV
   - 文件名：`capture.aiff` 或 `capture.wav`
   - 位置：`Sources/SwiftScreenShot/Resources/Sounds/`

3. **系统 Pop 音效**（回退方案）
   - macOS 内置音效
   - 作为最后的备选方案

## 添加自定义音效

如果您想使用自定义音效：

1. 准备音频文件：
   - 格式：AIFF 或 WAV
   - 时长：建议 < 1 秒
   - 采样率：44.1 kHz
   - 位深度：16-bit
   - 文件大小：< 100 KB

2. 将文件命名为 `capture.aiff` 或 `capture.wav`

3. 放置到 `Sources/SwiftScreenShot/Resources/Sounds/` 目录

4. 重新编译应用

## 性能考虑

### 非阻塞设计

音效播放在后台线程执行，确保不影响截图性能：

```swift
DispatchQueue.global(qos: .userInitiated).async {
    self?.audioPlayer?.play()
}
```

### 内存管理

- 使用 `NSSound` 的 `byReference: true` 选项，避免将整个音频文件加载到内存
- 音效资源只在初始化时加载一次
- 单例模式确保不会重复创建音频播放器

## 用户体验

### 默认行为
- 音效默认启用，为新用户提供即时反馈
- 音量适中（0.4-0.5），不会过于突兀

### 用户控制
- 用户可以在设置中轻松开启/关闭音效
- 设置立即生效，无需重启应用
- 设置持久化保存

## 测试

### 单元测试

已实施完整的测试覆盖：

**SoundManagerTests:**
- 单例模式验证
- 音效播放不崩溃测试
- 启用/禁用状态测试
- 快速连续调用测试

**ScreenshotSettingsTests:**
- 默认值测试（应为 true）
- 持久化测试
- 设置加载测试

所有测试均通过，确保功能稳定性。

## 技术规格

- **最低系统要求：** macOS 14.0+
- **框架依赖：**
  - AppKit（NSSound）
  - AVFoundation（可选，用于高级音频控制）
- **线程安全：** 是（使用 DispatchQueue）
- **内存占用：** 极低（< 1 MB）

## 未来增强

可能的改进方向：
1. 支持自定义音量调节
2. 提供多种音效选择
3. 添加音效预览功能
4. 支持不同事件的不同音效（成功/失败）

## 故障排除

### 音效不播放

1. 检查系统音量是否静音
2. 验证"播放截图音效"开关是否已启用
3. 检查系统音效文件是否存在
4. 查看控制台日志是否有错误信息

### 音效播放延迟

- 音效在后台线程播放，可能有轻微延迟（< 100ms）
- 这是正常行为，确保不影响截图性能

## 代码示例

### 手动播放音效

```swift
// 获取 SoundManager 实例
let soundManager = SoundManager.shared

// 播放音效（忽略设置）
soundManager.playCapture()

// 基于设置播放
soundManager.playCaptureIfEnabled(enabled: settings.playSoundOnCapture)
```

### 在设置中切换

```swift
// 在 SwiftUI 视图中
Toggle("播放截图音效", isOn: $settings.playSoundOnCapture)
```

## 许可证

此功能遵循 SwiftScreenShot 项目的整体许可证。

---

**最后更新：** 2025-12-14
**版本：** 1.0.0
