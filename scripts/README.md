# SwiftScreenShot 脚本工具

## 图标生成脚本

### generate_icons.swift

用于生成 SwiftScreenShot 应用的所有必需图标尺寸。

#### 功能特性

- 自动生成所有 macOS 应用所需的图标尺寸（16x16 到 1024x1024）
- 使用蓝紫渐变背景，符合现代 macOS 设计风格
- 包含截图工具相关的视觉元素：
  - 虚线选择框
  - 四个角的控制点
  - 相机快门图标

#### 使用方法

```bash
# 直接运行脚本
./scripts/generate_icons.swift

# 或使用 Swift 命令
swift scripts/generate_icons.swift
```

#### 生成的图标尺寸

| 尺寸 | 文件名 | 用途 |
|------|--------|------|
| 16x16 | icon_16x16.png | 小图标 |
| 32x32 | icon_16x16@2x.png | 小图标 @2x |
| 32x32 | icon_32x32.png | 中等图标 |
| 64x64 | icon_32x32@2x.png | 中等图标 @2x |
| 128x128 | icon_128x128.png | 大图标 |
| 256x256 | icon_128x128@2x.png | 大图标 @2x |
| 256x256 | icon_256x256.png | 超大图标 |
| 512x512 | icon_256x256@2x.png | 超大图标 @2x |
| 512x512 | icon_512x512.png | Retina 图标 |
| 1024x1024 | icon_512x512@2x.png | Retina 图标 @2x |

#### 输出位置

生成的图标文件将保存在：
```
Sources/SwiftScreenShot/Resources/Assets.xcassets/AppIcon.appiconset/
```

#### 图标设计说明

图标设计灵感来源于截图工具的核心功能：

1. **渐变背景**：蓝色到紫色的渐变，代表现代专业的工具
2. **虚线选择框**：表示截图时的区域选择功能
3. **角落控制点**：代表可调整的选择区域
4. **相机快门**：象征截图/拍照功能

#### 修改图标设计

如需修改图标设计，可以编辑 `generate_icons.swift` 中的 `drawScreenshotIcon` 函数：

- 修改颜色：调整 `NSColor` 的 RGB 值
- 修改形状：调整 `NSBezierPath` 的绘制代码
- 添加元素：在 `lockFocus()` 和 `unlockFocus()` 之间添加绘制代码

#### 注意事项

- 脚本需要在 macOS 上运行（需要 AppKit 框架）
- 重新生成图标后，需要清理构建缓存并重新编译应用
- 修改图标后建议重启应用以查看效果

## 构建和测试

```bash
# 清理构建
swift package clean

# 重新构建
swift build

# 运行应用
.build/debug/SwiftScreenShot
```
