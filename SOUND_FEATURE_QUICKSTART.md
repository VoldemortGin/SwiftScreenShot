# 声音反馈功能 - 快速入门指南

## 功能简介

SwiftScreenShot 现在在截图时会播放快门音效，就像使用相机拍照一样！

## 用户使用指南

### 启用/禁用音效

1. 点击菜单栏中的 SwiftScreenShot 图标
2. 选择"设置..."
3. 在"应用设置"部分，找到"播放截图音效"开关
4. 勾选启用，取消勾选禁用

**默认状态：** 音效默认启用

### 音效来源

应用会自动选择最佳音效：
1. macOS 系统相机快门音（推荐）
2. 自定义音效文件（如果您添加了）
3. 系统 Pop 音效（备用）

## 开发者指南

### 项目结构

```
SwiftScreenShot/
├── Sources/SwiftScreenShot/
│   ├── Core/
│   │   ├── SoundManager.swift          ← 新增：声音管理器
│   │   └── OutputManager.swift         ← 已修改：集成音效
│   ├── Models/
│   │   └── ScreenshotSettings.swift    ← 已修改：添加音效设置
│   ├── UI/Settings/
│   │   └── SettingsView.swift          ← 已修改：添加音效开关
│   └── Resources/
│       └── Sounds/
│           └── README.md               ← 新增：音效说明
├── Tests/SwiftScreenShotTests/
│   ├── SoundManagerTests.swift         ← 新增：音效测试
│   └── ScreenshotSettingsTests.swift   ← 已修改：添加设置测试
└── docs/
    └── SOUND_FEEDBACK.md               ← 新增：完整文档
```

### 快速编译和测试

```bash
# 编译项目
swift build

# 运行所有测试
swift test

# 运行应用
swift run SwiftScreenShot
```

### 代码集成示例

#### 在您的代码中使用 SoundManager

```swift
import Foundation

// 获取共享实例
let soundManager = SoundManager.shared

// 播放音效（忽略设置）
soundManager.playCapture()

// 基于用户设置播放
soundManager.playCaptureIfEnabled(enabled: true)

// 播放系统快门音
soundManager.playSystemShutterSound()
```

#### 在设置中控制音效

```swift
import SwiftUI

struct MySettingsView: View {
    @ObservedObject var settings: ScreenshotSettings

    var body: some View {
        Toggle("播放音效", isOn: $settings.playSoundOnCapture)
    }
}
```

### 添加自定义音效

1. **准备音频文件**
   - 格式：AIFF 或 WAV
   - 文件名：`capture.aiff` 或 `capture.wav`
   - 时长：< 1 秒
   - 大小：< 100 KB

2. **放置文件**
   ```bash
   cp your-sound.aiff Sources/SwiftScreenShot/Resources/Sounds/capture.aiff
   ```

3. **重新编译**
   ```bash
   swift build
   ```

### 测试覆盖

当前测试覆盖率：
- ✓ SoundManager 单例模式
- ✓ 音效播放功能
- ✓ 启用/禁用状态
- ✓ 设置持久化
- ✓ 快速连续调用

运行特定测试：
```bash
# ���运行 SoundManager 测试
swift test --filter SoundManagerTests

# 仅运行设置测试
swift test --filter ScreenshotSettingsTests
```

## 技术要点

### 性能特性
- **异步播放**：音效在后台线程播放
- **低内存占用**：使用引用方式加载音频
- **非阻塞**：不影响截图速度

### 线程安全
```swift
// 音效在后台线程播放
DispatchQueue.global(qos: .userInitiated).async {
    self.audioPlayer?.play()
}
```

### 错误处理
- 自动回退到备用音效
- 静默失败，不中断截图流程
- 错误记录到控制台

## 常见问题

### Q: 音效不播放怎么办？
A: 检查以下几点：
1. 系统音量是否静音
2. 设置中"播放截图音效"是否启用
3. 查看控制台是否有错误信息

### Q: 可以调整音量吗？
A: 当前版本音量固定为 0.4-0.5。未来版本可能添加音量控制。

### Q: 支持什么音频格式？
A: 支持 AIFF 和 WAV 格式。推荐使用 AIFF。

### Q: 会影响截图性能吗？
A: 不会。音效在后台线程播放，完全不阻塞截图流程。

## 配置选项

### UserDefaults 键
```swift
// 音效开关
UserDefaults.standard.bool(forKey: "playSoundOnCapture")

// 编程方式修改
UserDefaults.standard.set(true, forKey: "playSoundOnCapture")
```

### 默认值
```swift
playSoundOnCapture = true  // 默认启用
volume = 0.4               // 固定音量（未暴露给用户）
```

## 扩展建议

如果您想扩展这个功能，考虑：

1. **音量控制**
   ```swift
   @Published var soundVolume: Float = 0.5
   ```

2. **多种音效**
   ```swift
   enum SoundEffect {
       case shutter
       case success
       case error
   }
   ```

3. **音效预览**
   ```swift
   func previewSound() {
       soundManager.playCapture()
   }
   ```

## 相关文件

- 完整文档：`docs/SOUND_FEEDBACK.md`
- 变更日志：`CHANGELOG_SOUND_FEEDBACK.md`
- 音效说明：`Sources/SwiftScreenShot/Resources/Sounds/README.md`

## 获取帮助

如果遇到问题：
1. 查看控制台日志
2. 运行单元测试
3. 查阅完整文档

---

**版本：** 1.0.0
**最后更新：** 2025-12-14
**状态：** ✓ 生产就绪
