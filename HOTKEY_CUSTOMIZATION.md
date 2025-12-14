# 自定义热键配置功能

## 功能概述

SwiftScreenShot 现在支持用户自定义截图热键。用户可以在设置界面中为区域截图和全屏截图配置自己喜欢的快捷键组合。

## 功能特性

### 1. 热键录制器 UI
- 类似系统偏好设置的快捷键录制界面
- 点击输入框即可开始录制新的快捷键
- 实时显示当前配置的快捷键（符号和文字两种格式）
- 提供重置按钮，可恢复默认设置

### 2. 热键验证
系统会自动验证新设置的快捷键，检查以下情况：
- **必须包含修饰键**：至少需要一个修饰键（⌃⌥⇧⌘）
- **有效按键组合**：确保按键代码有效
- **系统保留快捷键**：避免与系统快捷键冲突（如 ⌘Q、⌘Tab 等）
- **内部冲突检测**：区域截图和全屏截图不能使用相同的快捷键

### 3. 默认热键
- **区域截图**：⌃⌘A (Control + Command + A)
- **全屏截图**：⇧⌘3 (Shift + Command + 3)

### 4. 动态更新
- 修改热键后立即生效，无需重启应用
- 菜单栏自动更新显示新的快捷键标签
- 设置保存到 UserDefaults，重启后保持配置

### 5. 注册失败处理
当热键注册失败时（如被其他应用占用），系统会：
- 显示详细的错误提示对话框
- 说明可能的失败原因
- 提供快速打开设置的选项

## 文件结构

### 新增文件

#### Models
- **HotKeyConfig.swift**
  - `HotKeyConfig` 结构：表示热键配置（keyCode + modifiers）
  - `HotKeyType` 枚举：热键类型（区域截图/全屏截图）
  - `HotKeyValidationError` 枚举：验证错误类型
  - 提供显示字符串转换和验证逻辑

#### UI Components
- **HotKeyRecorder.swift**
  - SwiftUI 组件，用于录制和显示热键
  - 支持实时按键捕获
  - 显示当前热键（符号和文字格式）
  - 错误提示显示
  - 重置功能

#### Tests
- **HotKeyConfigTests.swift**
  - 27 个单元测试
  - 覆盖配置创建、验证、序列化等功能

### 修改的文件

1. **ScreenshotSettings.swift**
   - 添加 `regionScreenshotHotKey` 属性
   - 添加 `fullScreenshotHotKey` 属性
   - 实现 JSON 序列化和 UserDefaults 持久化
   - 添加 `resetHotKey()` 和 `resetAllHotKeys()` 方法
   - 热键修改时发送通知

2. **HotKeyManager.swift**
   - 支持使用 `HotKeyConfig` 注册热键
   - 添加注册失败处理器
   - 改进热键注销逻辑
   - 返回可选的热键 ID（注册失败时返回 nil）

3. **MenuBarController.swift**
   - 接收 `ScreenshotSettings` 参数
   - 监听热键变更通知
   - 动态更新菜单项标题
   - 显示当前配置的快捷键

4. **AppDelegate.swift**
   - 使用设置中的自定义热键
   - 监听热键变更通知并重新注册
   - 显示热键注册失败对话框
   - 跟踪热键 ID 以支持动态更新

5. **SettingsView.swift**
   - 添加"快捷键设置"部分
   - 集成 `HotKeyRecorder` 组件
   - 提供"全部重置"按钮
   - 显示选区操作快捷键说明

6. **Extensions.swift**
   - 添加 `.hotKeysDidChange` 通知名称

7. **ScreenshotSettingsTests.swift**
   - 添加热键配置相关的 8 个测试用例
   - 测试持久化、重置和通知功能

## 使用方法

### 用户操作流程

1. **打开设置**
   - 点击菜单栏图标
   - 选择"设置..."

2. **配置热键**
   - 滚动到"快捷键设置"部分
   - 点击要修改的热键输入框
   - 按下新的快捷键组合
   - 系统自动验证并保存

3. **重置热键**
   - 单个重置：点击热键右侧的"重置"按钮
   - 全部重置：点击部分标题右侧的"全部重置"按钮

### 开发者集成

```swift
// 创建热键配置
let hotKey = HotKeyConfig(
    keyCode: 0,  // A key
    modifiers: UInt32(cmdKey | controlKey)
)

// 显示热键
print(hotKey.displayString)  // "⌃⌘A"
print(hotKey.verboseDisplayString)  // "Control+Command+A"

// 验证热键
if hotKey.isValid {
    // 使用 HotKeyManager 注册
    let id = hotKeyManager.register(config: hotKey) {
        // 热键触发时的操作
        print("Hotkey pressed!")
    }
}

// 保存到设置
settings.regionScreenshotHotKey = hotKey

// 重置到默认
settings.resetHotKey(for: .regionScreenshot)
```

## 技术实现细节

### 热键存储格式
热键配置使用 JSON 格式存储在 UserDefaults 中：

```json
{
  "keyCode": 0,
  "modifiers": 4352
}
```

### 按键代码映射
系统使用 Carbon 框架的虚拟按键代码：
- 字母 A-Z：0, 1, 2, 3...
- 数字 1-9, 0：18, 19, 20, 21...
- 功能键 F1-F12：122, 120, 99, 118...
- 特殊键：Space(49), Return(36), Tab(48), Delete(51), Esc(53)

### 修饰键
- Control: `controlKey` (0x1000)
- Option: `optionKey` (0x0800)
- Shift: `shiftKey` (0x0200)
- Command: `cmdKey` (0x0100)

### 通知机制
当热键配置改变时：
1. `ScreenshotSettings` 发送 `.hotKeysDidChange` 通知
2. `AppDelegate` 接收通知并重新注册热键
3. `MenuBarController` 接收通知并更新菜单标题

## 测试覆盖

### HotKeyConfig 测试
- 默认配置验证
- 显示字符串生成
- 验证逻辑（修饰键、系统保留、有效性）
- 序列化和反序列化
- 相等性比较

### ScreenshotSettings 测试
- 默认热键加载
- 热键持久化
- 重置功能
- 通知发送

总共 71 个测试用例，全部通过。

## 错误处理

### 验证错误
- **无修饰键**："快捷键必须包含至少一个修饰键(⌃⌥⇧⌘)"
- **无效按键**："无效的按键组合"
- **系统保留**："此快捷键已被系统保留"
- **内部冲突**："与[类型]的快捷键冲突"

### 注册失败
当热键注册失败时，显示警告对话框：
```
快捷键注册失败

无法注册快捷键 [显示字符串]。

可能的原因：
• 快捷键已被其他应用占用
• 快捷键与系统功能冲突

错误代码: [OSStatus]

请在设置中更换其他快捷键。
```

## 未来改进建议

1. **热键冲突检测**
   - 检测与其他应用的热键冲突
   - 显示占用该热键的应用名称

2. **更多热键类型**
   - 窗口截图
   - 延迟截图
   - 录屏功能

3. **导入/导出配置**
   - 支持配置文件导出
   - 快速恢复配置

4. **热键组合建议**
   - 分析常用热键模式
   - 推荐不冲突的组合

## 相关资源

- [Carbon Event Manager Documentation](https://developer.apple.com/documentation/carbon/carbon_event_manager)
- [Virtual Key Codes](https://developer.apple.com/documentation/carbon/1390584-virtual_key_codes)
- [SwiftUI KeyPress](https://developer.apple.com/documentation/swiftui/keypress)
