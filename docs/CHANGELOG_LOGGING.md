# 日志系统更新日志

## 版本更新 - 2025-12-14

### 新增功能

#### 结构化日志系统
- 实现了基于 Apple os.Logger 的结构化日志系统
- 支持 5 个日志级别：Debug, Info, Warning, Error, Fault
- 定义了 12 个日志分类用于不同模块
- 添加了文件日志功能（可选）
- 实现了日志导出和清理功能

#### 设置界面增强
- 在设置中添加了"日志设置"部分
- 用户可以选择日志级别（Debug/Info/Warning/Error/Fault）
- 用户可以启用/禁用文件日志
- 添加了日志导出按钮
- 显示日志文件保存路径

### 改进

#### 代码质量
- 替换了所有 32 处 `print()` 语句为结构化日志
- 在关键路径添加了 40+ 个日志点
- 改进了错误处理和调试能力

#### 性能优化
- 日志文件异步写入，不影响主线程性能
- 实现了日志级别过滤，避免不必要的处理
- 自动清理旧日志文件（保留最近 7 天）

### 技术细节

#### 新增文件
- `Sources/SwiftScreenShot/Utilities/AppLogger.swift` - 日志系统核心实现（~350 行）
- `docs/LOGGING.md` - 日志系统使用文档
- `docs/LOGGING_IMPLEMENTATION.md` - 实施总结

#### 修改文件
- `Sources/SwiftScreenShot/Models/ScreenshotSettings.swift` - 添加日志配置
- `Sources/SwiftScreenShot/UI/Settings/SettingsView.swift` - 添加日志设置 UI
- `Sources/SwiftScreenShot/App/AppDelegate.swift` - 日志迁移
- `Sources/SwiftScreenShot/Core/HotKeyManager.swift` - 日志迁移
- `Sources/SwiftScreenShot/Core/OutputManager.swift` - 日志迁移
- `Sources/SwiftScreenShot/Core/SoundManager.swift` - 日志迁移
- `Sources/SwiftScreenShot/Core/ScreenshotHistory.swift` - 日志迁移
- `Sources/SwiftScreenShot/Core/WindowDetector.swift` - 添加日志
- `Sources/SwiftScreenShot/Core/DelayedScreenshotManager.swift` - 添加日志

### 使用示例

```swift
// 一般信息
AppLogger.shared.info("Screenshot completed", category: .screenshot)

// 错误信息（带 Error 对象）
AppLogger.shared.error("Failed to save file", category: .output, error: error)

// 调试信息（仅在 Debug 级别显示）
AppLogger.shared.debug("Processing \(count) windows", category: .window)

// 警告
AppLogger.shared.warning("Permission not granted", category: .permission)
```

### 日志分类

| 分类 | 用途 |
|------|------|
| screenshot | 截图捕获和处理 |
| hotkey | 热键注册和管理 |
| settings | 设置变更 |
| editor | 图片编辑 |
| history | 历史记录 |
| window | 窗口检测 |
| permission | 权限管理 |
| output | 文件保存和输出 |
| sound | 音效播放 |
| annotation | 标注功能 |
| delay | 延时截图 |
| app | 应用生命周期 |

### 日志文件

- **保存位置**: `~/Library/Application Support/SwiftScreenShot/Logs/`
- **文件格式**: `SwiftScreenShot_YYYY-MM-DD.log`
- **自动清理**: 启动时保留最近 7 天的日志
- **导出功能**: 可通过设置界面导出日志

### 查看日志

#### 使用 Console.app
```bash
subsystem:com.swiftscreenshot.app
```

#### 使用命令行
```bash
# 实时查看
log stream --predicate 'subsystem == "com.swiftscreenshot.app"'

# 查看特定分类
log stream --predicate 'subsystem == "com.swiftscreenshot.app" AND category == "screenshot"'
```

### 开发模式

- Debug 构建默认日志级别：Debug
- Release 构建默认日志级别：Info
- Debug 模式下包含文件名、行号信息

### 构建状态

- ✅ Debug 构建成功
- ✅ Release 构建成功
- ⚠️ 1 个 Swift 6 兼容性警告（非阻塞）

### 后续计划

- [ ] 添加应用内日志查看器
- [ ] 支持日志搜索和过滤
- [ ] 添加性能指标日志
- [ ] 支持日志远程上传（bug 报告）
- [ ] 日志统计和分析功能

### 文档

详细文档请参考：
- [日志系统使用文档](./LOGGING.md)
- [日志系统实施总结](./LOGGING_IMPLEMENTATION.md)
