# SwiftScreenShot 资源管理

## 概述

本文档说明 SwiftScreenShot 项目中的所有资源文件，包括图标、图片和其他媒体资源的管理方式。

## 目录结构

```
Sources/SwiftScreenShot/Resources/
├── Assets.xcassets/              # Xcode 资源目录
│   ├── Contents.json             # 资源目录元数据
│   └── AppIcon.appiconset/       # 应用图标集
│       ├── Contents.json         # 图标集配置
│       ├── icon_16x16.png        # 16x16 图标
│       ├── icon_16x16@2x.png     # 16x16@2x 图标
│       ├── icon_32x32.png        # 32x32 图标
│       ├── icon_32x32@2x.png     # 32x32@2x 图标
│       ├── icon_128x128.png      # 128x128 图标
│       ├── icon_128x128@2x.png   # 128x128@2x 图标
│       ├── icon_256x256.png      # 256x256 图标
│       ├── icon_256x256@2x.png   # 256x256@2x 图标
│       ├── icon_512x512.png      # 512x512 图标
│       └── icon_512x512@2x.png   # 512x512@2x (1024x1024) 图标
└── Info.plist                    # 应用配置文件
```

## 资源类型

### 1. 应用图标 (AppIcon)

**位置**: `Sources/SwiftScreenShot/Resources/Assets.xcassets/AppIcon.appiconset/`

**用途**:
- macOS 应用主图标
- 显示在 Dock、应用切换器、Finder 等位置
- 支持所有标准 macOS 图标尺寸

**生成方式**:
```bash
# 自动生成所有尺寸
./scripts/generate_icons.swift

# 或使用完整构建脚本
./scripts/build_with_icon.sh
```

**配置**:
- `Package.swift`: 声明为处理资源
- `Info.plist`: 引用图标名称 "AppIcon"

### 2. 菜单栏图标

**当前实现**: 使用 SF Symbol `camera.viewfinder`

**优势**:
- 自动适配系统主题（亮色/暗色）
- 更小的文件体积
- 符合 macOS 设计规范
- 无需额外资源文件

**位置**: 在代码中直接引用
```swift
// MenuBarController.swift
button.image = NSImage(
    systemSymbolName: "camera.viewfinder",
    accessibilityDescription: "截图"
)
```

## 资源配置

### Package.swift 配置

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

**说明**:
- `.process()` 会自动处理 `.xcassets` 资源
- 编译时会生成优化的资源包
- 运行时可通过 Bundle 访问

### Info.plist 配置

```xml
<key>CFBundleIconFile</key>
<string>AppIcon</string>
<key>CFBundleIconName</key>
<string>AppIcon</string>
```

**说明**:
- `CFBundleIconFile`: 图标文件名（不含扩展名）
- `CFBundleIconName`: Assets 中的图标集名称

## 访问资源

### 在代码中访问图标

```swift
// 方法 1: 通过 Assets 名称访问
if let appIcon = NSImage(named: "AppIcon") {
    // 使用图标
}

// 方法 2: 使用 SF Symbols (推荐用于 UI 元素)
let icon = NSImage(
    systemSymbolName: "camera.viewfinder",
    accessibilityDescription: "描述"
)

// 方法 3: 访问 Bundle 资源
if let iconURL = Bundle.main.url(
    forResource: "icon_512x512",
    withExtension: "png",
    subdirectory: "Assets.xcassets/AppIcon.appiconset"
) {
    let icon = NSImage(contentsOf: iconURL)
}
```

### 在 SwiftUI 中使用

```swift
import SwiftUI

struct AboutView: View {
    var body: some View {
        VStack {
            // 使用 Assets 图标
            Image("AppIcon")
                .resizable()
                .frame(width: 128, height: 128)

            // 使用 SF Symbol
            Image(systemName: "camera.viewfinder")
                .font(.system(size: 64))
        }
    }
}
```

## 添加新资源

### 添加新图片资源

1. 在 Assets.xcassets 中创建新的图片集：

```bash
mkdir -p Sources/SwiftScreenShot/Resources/Assets.xcassets/MyImage.imageset
```

2. 创建 Contents.json：

```json
{
  "images" : [
    {
      "filename" : "image.png",
      "idiom" : "universal",
      "scale" : "1x"
    },
    {
      "filename" : "image@2x.png",
      "idiom" : "universal",
      "scale" : "2x"
    }
  ],
  "info" : {
    "author" : "xcode",
    "version" : 1
  }
}
```

3. 添加图片文件并在代码中使用：

```swift
let image = NSImage(named: "MyImage")
```

### 添加颜色资源

1. 创建颜色集：

```bash
mkdir -p Sources/SwiftScreenShot/Resources/Assets.xcassets/BrandColor.colorset
```

2. 创建 Contents.json：

```json
{
  "colors" : [
    {
      "color" : {
        "color-space" : "srgb",
        "components" : {
          "red" : "0.200",
          "green" : "0.500",
          "blue" : "1.000",
          "alpha" : "1.000"
        }
      },
      "idiom" : "universal"
    }
  ],
  "info" : {
    "author" : "xcode",
    "version" : 1
  }
}
```

3. 在代码中使用：

```swift
// AppKit
let color = NSColor(named: "BrandColor")

// SwiftUI
Color("BrandColor")
```

## 资源优化

### 图标优化建议

1. **使用合适的格式**:
   - PNG: 适合带透明度的图标
   - PDF: 矢量图标（自动缩放）
   - JPEG: 不适合图标（无透明度）

2. **压缩图片**:
   ```bash
   # 使用 ImageOptim 或命令行工具
   pngquant icon.png --output icon-optimized.png
   ```

3. **避免过大的文件**:
   - 1024x1024 图标应小于 1MB
   - 小尺寸图标应在 50KB 以内

### 构建优化

```swift
// 使用 .copy() 而不是 .process() 可以避免处理
.executableTarget(
    resources: [
        .copy("path/to/file.ext")  // 直接复制，不处理
    ]
)
```

## 常见问题

### Q: 为什么看不到图标？

**A**: 检查以下几点：
1. 图标文件是否存在于正确位置
2. Info.plist 是否正确配置
3. Package.swift 是否包含资源配置
4. 是否清理并重新构建了项目

```bash
swift package clean
swift build
```

### Q: 图标在不同尺寸下看起来不一样？

**A**: 这是正常的，因为：
1. 不同尺寸使用不同的 PNG 文件
2. 小尺寸图标可能需要简化细节
3. 可以为不同尺寸创建优化版本

### Q: 如何在 Xcode 中查看 Assets？

**A**:
1. 在 Xcode 中打开项目
2. 导航到 `Sources/SwiftScreenShot/Resources/Assets.xcassets`
3. 双击 `.xcassets` 文件夹查看所有资源

### Q: 资源文件会被包含在可执行文件中吗？

**A**:
- 使用 `.process()` 时，资源会被打包到 Bundle 中
- 可执行文件本身不包含资源
- 需要创建 .app 包才能正确分发资源

## 工具和脚本

### 可用脚本

1. **generate_icons.swift**: 生成所有图标尺寸
   ```bash
   ./scripts/generate_icons.swift
   ```

2. **build_with_icon.sh**: 构建包含图标的应用
   ```bash
   ./scripts/build_with_icon.sh
   ```

3. **preview_icon.sh**: 预览生成的图标
   ```bash
   ./scripts/preview_icon.sh
   ```

### Git Hooks

**pre-commit**: 提交前检查图标是否存在
- 位置: `hooks/pre-commit`
- 自动检查图标文件
- 验证配置文件

启用方法:
```bash
# 将 hook 链接到 .git/hooks
ln -sf ../../hooks/pre-commit .git/hooks/pre-commit
```

## 最佳实践

### 1. 版本控制

**应该提交**:
- ✓ Assets.xcassets 目录结构
- ✓ Contents.json 文件
- ✓ 生成的图标 PNG 文件
- ✓ 图标生成脚本

**不应提交**:
- ✗ 临时图片文件
- ✗ 未优化的大文件
- ✗ 编辑器临时文件

### 2. 命名规范

- 使用描述性名称: `AppIcon`, `BrandColor`
- 避免空格和特殊字符
- 保持大小写一致性

### 3. 文档

- 记录每个资源的用途
- 说明资源的来源和版权
- 更新变更日志

### 4. 测试

- 在不同主题下测试图标显示
- 验证所有尺寸都正确生成
- 检查 Retina 和非 Retina 显示

## 参考资源

- [Apple Asset Catalog Format](https://developer.apple.com/library/archive/documentation/Xcode/Reference/xcode_ref-Asset_Catalog_Format/)
- [macOS Human Interface Guidelines](https://developer.apple.com/design/human-interface-guidelines/macos/overview/themes/)
- [SF Symbols](https://developer.apple.com/sf-symbols/)
- [Swift Package Manager Resources](https://github.com/apple/swift-evolution/blob/main/proposals/0271-package-manager-resources.md)

## 更新日志

### 2024-12-13
- 创建 Assets.xcassets 资源目录
- 实现应用图标自动生成
- 配置 Package.swift 资源处理
- 添加图标预览和构建脚本
- 创建 Git pre-commit hook
