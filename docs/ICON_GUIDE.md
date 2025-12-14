# SwiftScreenShot 图标使用指南

## 概述

SwiftScreenShot 应用现在包含完整的应用图标资源，设计简洁专业，符合 macOS 设计规范。

## 图标设计

### 视觉元素

图标由以下元素组成：

1. **渐变背景**：蓝色 (#3380FF) 到紫色 (#6633E6) 的对角渐变
2. **虚线选择框**：白色半透明虚线矩形，代表截图选择区域
3. **角落控制点**：四个白色圆点，表示可调整的选择区域
4. **相机快门**：右下角的快门图标，包含光圈效果

### 颜色方案

```swift
背景渐变:
  - 起始色: RGB(51, 128, 255) - 蓝色
  - 结束色: RGB(102, 51, 230) - 紫色

前景元素:
  - 选择框: 白色 90% 不透明度
  - 控制点: 纯白色
  - 快门外圈: 纯白色
  - 快门内圈: 蓝色 (与背景一致)
```

## 文件结构

```
Sources/SwiftScreenShot/Resources/
└── Assets.xcassets/
    ├── Contents.json
    └── AppIcon.appiconset/
        ├── Contents.json
        ├── icon_16x16.png         (16x16)
        ├── icon_16x16@2x.png      (32x32)
        ├── icon_32x32.png         (32x32)
        ├── icon_32x32@2x.png      (64x64)
        ├── icon_128x128.png       (128x128)
        ├── icon_128x128@2x.png    (256x256)
        ├── icon_256x256.png       (256x256)
        ├── icon_256x256@2x.png    (512x512)
        ├── icon_512x512.png       (512x512)
        └── icon_512x512@2x.png    (1024x1024)
```

## 使用场景

### 1. 应用图标（已配置）

应用图标会自动显示在：
- Dock 栏
- 应用切换器 (⌘+Tab)
- Finder 中的应用程序文件夹
- 启动台 (Launchpad)

**配置位置**：`Sources/SwiftScreenShot/Resources/Info.plist`

```xml
<key>CFBundleIconFile</key>
<string>AppIcon</string>
<key>CFBundleIconName</key>
<string>AppIcon</string>
```

### 2. 菜单栏图标

当前菜单栏使用 SF Symbol `camera.viewfinder`，这是推荐的做法，因为：
- 自动适配亮色/暗色模式
- 尺寸更小，更适合菜单栏
- 符合 macOS 设计规范

如果想使用应用图标作为菜单栏图标，可以修改 `MenuBarController.swift`：

```swift
// 当前代码（推荐）
button.image = NSImage(
    systemSymbolName: "camera.viewfinder",
    accessibilityDescription: "截图"
)

// 使用应用图标（可选）
if let appIcon = NSImage(named: "AppIcon") {
    button.image = appIcon
    button.image?.size = NSSize(width: 18, height: 18)
}
```

### 3. 关于窗口图标

可以在设置窗口或关于窗口中显示应用图标：

```swift
// 在任何 NSWindow 或 SwiftUI View 中
if let appIcon = NSImage(named: "AppIcon") {
    // 用于 NSWindow
    window.icon = appIcon

    // 用于 SwiftUI
    Image(nsImage: appIcon)
        .resizable()
        .frame(width: 64, height: 64)
}
```

## 重新生成图标

### 方法 1: 使用生成脚本

```bash
# 从项目根目录运行
./scripts/generate_icons.swift
```

### 方法 2: 使用完整构建脚本

```bash
# 从项目根目录运行
./scripts/build_with_icon.sh
```

这会：
1. 清理旧构建
2. 生成图标（如果不存在）
3. 构建 Release 版本
4. 创建应用包（.app）

## 自定义图标

### 修改颜色

编辑 `scripts/generate_icons.swift`，找到渐变颜色定义：

```swift
let gradient = NSGradient(colors: [
    NSColor(red: 0.2, green: 0.5, blue: 1.0, alpha: 1.0),  // 修改这里
    NSColor(red: 0.4, green: 0.3, blue: 0.9, alpha: 1.0)   // 和这里
])
```

### 修改设计元素

在 `drawScreenshotIcon` 函数中修改：

```swift
// 修改选择框大小
let selectionRect = NSRect(x: padding + contentSize * 0.15,  // 调整这些值
                          y: padding + contentSize * 0.15,
                          width: contentSize * 0.7,
                          height: contentSize * 0.7)

// 修改快门位置和大小
let shutterRadius = size * 0.12  // 调整半径
let shutterCenter = CGPoint(x: centerX + contentSize * 0.25,  // 调整位置
                           y: centerY - contentSize * 0.25)
```

### 使用自定义图片

如果你有设计师制作的图标，可以：

1. 准备所有需要的尺寸（16x16 到 1024x1024）
2. 将文件放入 `AppIcon.appiconset/` 目录
3. 确保文件名与 `Contents.json` 中的定义匹配
4. 重新构建项目

## 构建配置

### Package.swift

图标资源在 `Package.swift` 中配置为处理资源：

```swift
.executableTarget(
    name: "SwiftScreenShot",
    dependencies: [],
    path: "Sources",
    exclude: [
        "SwiftScreenShot/Resources/Info.plist",
        "SwiftScreenShot/Resources/SwiftScreenShot-Bridging-Header.h"
    ],
    resources: [
        .process("SwiftScreenShot/Resources/Assets.xcassets")
    ]
)
```

### Info.plist

必需的键值对：

```xml
<key>CFBundleIconFile</key>
<string>AppIcon</string>
<key>CFBundleIconName</key>
<string>AppIcon</string>
```

## 验证图标

### 查看图标文件

```bash
# 列出所有生成的图标
ls -lh Sources/SwiftScreenShot/Resources/Assets.xcassets/AppIcon.appiconset/

# 使用 Quick Look 预览图标
qlmanage -p Sources/SwiftScreenShot/Resources/Assets.xcassets/AppIcon.appiconset/icon_512x512.png
```

### 测试应用图标

1. 构建应用包：
   ```bash
   ./scripts/build_with_icon.sh
   ```

2. 在 Finder 中查看 `SwiftScreenShot.app` 的图标

3. 将应用拖到 Dock 栏查看图标效果

## 常见问题

### Q: 图标没有显示？

A: 尝试以下步骤：
1. 清理构建：`swift package clean`
2. 重新生成图标：`./scripts/generate_icons.swift`
3. 重新构建：`swift build`
4. 如果使用 .app 包，删除旧的并重新创建

### Q: 图标模糊或失真？

A: 确保：
1. 所有尺寸的图标都已正确生成
2. 使用的是 @2x 版本用于 Retina 显示屏
3. 图标是 PNG 格式，非压缩

### Q: 如何创建 .icns 文件？

A: 可以使用以下命令从 PNG 图标创建 .icns：

```bash
# 创建临时图标集目录
mkdir AppIcon.iconset

# 复制并重命名图标文件
cp Sources/SwiftScreenShot/Resources/Assets.xcassets/AppIcon.appiconset/icon_16x16.png AppIcon.iconset/icon_16x16.png
cp Sources/SwiftScreenShot/Resources/Assets.xcassets/AppIcon.appiconset/icon_16x16@2x.png AppIcon.iconset/icon_16x16@2x.png
# ... 复制所有其他尺寸

# 使用 iconutil 创建 .icns
iconutil -c icns AppIcon.iconset -o AppIcon.icns

# 清理临时文件
rm -rf AppIcon.iconset
```

### Q: 菜单栏图标太大？

A: 菜单栏图标应保持小尺寸（通常 16-22px）。建议使用 SF Symbol 而不是应用图标。

## 设计建议

### 遵循 macOS 图标设计规范

1. **使用圆角矩形**：macOS 应用图标使用 22% 的圆角半径
2. **添加阴影和高光**：增加立体感（可选）
3. **保持简洁**：避免过多细节，特别是小尺寸图标
4. **测试所有尺寸**：确保在 16x16 和 1024x1024 都清晰可辨

### 颜色建议

- 使用鲜明但不刺眼的颜色
- 考虑在亮色和暗色模式下的显示效果
- 使用渐变增加视觉吸引力

### 工具推荐

- **设计**：Sketch, Figma, Adobe Illustrator
- **导出**：Image2Icon, IconFly
- **预览**：macOS Preview, Quick Look

## 参考资源

- [Apple Human Interface Guidelines - App Icons](https://developer.apple.com/design/human-interface-guidelines/app-icons)
- [macOS Icon Template](https://developer.apple.com/design/resources/)
- [SF Symbols](https://developer.apple.com/sf-symbols/)

## 更新日志

- **2024-12-13**：初始图标设计和生成脚本创建
  - 实现蓝紫渐变背景
  - 添加选择框和快门图标元素
  - 支持所有 macOS 所需尺寸
