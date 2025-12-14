# 全屏截图功能 - 快速入门

## 快速使用

### 方式一：使用快捷键
- **区域截图**: 按 `⌃⌘A` (Control + Command + A)
- **全屏截图**: 按 `⇧⌘3` (Shift + Command + 3)

### 方式二：使用菜单栏
1. 点击菜单栏的相机图标
2. 选择"区域截图"或"全屏截图"

## 配置全屏截图模式

1. 点击菜单栏图标 → "设置..."
2. 找到"全屏截图设置"部分
3. 选择以下模式之一：
   - **主显示器**: 只截取主屏幕
   - **当前屏幕**: 截取鼠标所在的屏幕（默认）
   - **所有屏幕**: 截取所有显示器并拼接

## 新增功能一览

### ✅ 核心功能
- [x] 全屏截图模式（无需选择区域）
- [x] 三种捕获模式（主显示器/当前屏幕/所有屏幕）
- [x] 多显示器支持
- [x] 屏幕拼接（所有屏幕模式）
- [x] 独立快捷键（⇧⌘3）

### ✅ 用户界面
- [x] 菜单栏新增"全屏截图"选项
- [x] 设置界面新增全屏截图配置
- [x] 快捷键说明更新

### ✅ 技术实现
- [x] 重构 HotKeyManager 支持多热键
- [x] 扩展 ScreenshotEngine 新增全屏捕获方法
- [x] 设置持久化
- [x] 单元测试

## 文件变更总结

### 新增文件
- `Sources/SwiftScreenShot/Models/ScreenshotMode.swift` - 截图模式枚举定义
- `Tests/SwiftScreenShotTests/ScreenshotModeTests.swift` - 单元测试
- `FULLSCREEN_FEATURE.md` - 详细功能说明文档

### 修改文件
- `Sources/SwiftScreenShot/App/AppDelegate.swift` - 新增全屏截图处理逻辑
- `Sources/SwiftScreenShot/Core/HotKeyManager.swift` - 重构支持多热键
- `Sources/SwiftScreenShot/Core/ScreenshotEngine.swift` - 新增全屏捕获方法
- `Sources/SwiftScreenShot/Models/ScreenshotSettings.swift` - 新增全屏模式设置
- `Sources/SwiftScreenShot/UI/MenuBar/MenuBarController.swift` - 新增菜单项
- `Sources/SwiftScreenShot/UI/Settings/SettingsView.swift` - 新增设置界面
- `Sources/SwiftScreenShot/Utilities/Extensions.swift` - 新增通知名称

## 测试验证

### 构建测试
```bash
swift build
# Build complete! (0.15s)
```

### 单元测试
```bash
swift test
# Executed 34 tests, with 0 failures ✅
```

## 下一步

1. **运行应用**
   ```bash
   swift run
   ```

2. **授予权限**
   - 首次运行会提示授予屏幕录制权限
   - 在"系统设置" → "隐私与安全性" → "屏幕录制"中启用

3. **体验功能**
   - 尝试使用 `⇧⌘3` 进行全屏截图
   - 在设置中切换不同的捕获模式
   - 测试多显示器环境（如有）

## 常见问题

**Q: 全屏截图没有反应？**
A: 检查是否已授予屏幕录制权限。

**Q: 如何更改全屏截图的快捷键？**
A: 当前快捷键是硬编码的，未来版本将支持自定义。

**Q: 所有屏幕模式生成的图片太大？**
A: 可以在设置中调整图片格式为 JPEG 以减小文件大小。

**Q: 截图后在哪里找到？**
A: 默认复制到剪贴板，可在设置中启用"同时保存到文件"。

## 反馈与建议

如有问题或建议，欢迎提交 Issue 或 Pull Request。
