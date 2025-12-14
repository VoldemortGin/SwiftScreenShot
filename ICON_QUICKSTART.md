# SwiftScreenShot 图标快速开始指南

## 图标已配置完成

SwiftScreenShot 应用现在已包含完整的应用图标系统，所有必要的文件都已创建和配置。

## 图标设计

应用图标采用现代简洁的设计风格：

- **背景**: 蓝色到紫色的渐变（#3380FF → #6633E6）
- **主元素**: 虚线选择框 + 角落控制点
- **辅助元素**: 相机快门图标（带光圈效果）
- **风格**: 符合 macOS Big Sur 及更高版本的设计规范

## 文件清单

### 已创建的资源文件

```
✓ Sources/SwiftScreenShot/Resources/Assets.xcassets/
  ✓ Contents.json
  ✓ AppIcon.appiconset/
    ✓ Contents.json
    ✓ icon_16x16.png (16x16)
    ✓ icon_16x16@2x.png (32x32)
    ✓ icon_32x32.png (32x32)
    ✓ icon_32x32@2x.png (64x64)
    ✓ icon_128x128.png (128x128)
    ✓ icon_128x128@2x.png (256x256)
    ✓ icon_256x256.png (256x256)
    ✓ icon_256x256@2x.png (512x512)
    ✓ icon_512x512.png (512x512)
    ✓ icon_512x512@2x.png (1024x1024)
```

### 已创建的脚本

```
✓ scripts/generate_icons.swift       - 图标生成脚本
✓ scripts/build_with_icon.sh         - 完整构建脚本
✓ scripts/preview_icon.sh            - 图标预览脚本
✓ scripts/README.md                  - 脚本使用说明
```

### 已创建的文档

```
✓ docs/ICON_GUIDE.md                 - 详细图标指南
✓ docs/ASSETS.md                     - 资源管理文档
✓ ICON_QUICKSTART.md                 - 本文档
```

### 已创建的 Hooks

```
✓ hooks/pre-commit                   - Git 提交前检查
```

### 已配置的文件

```
✓ Package.swift                      - 已添加资源配置
✓ Sources/SwiftScreenShot/Resources/Info.plist  - 已配置图标引用
```

## 快速使用

### 查看图标

```bash
# 预览图标（交互式）
./scripts/preview_icon.sh

# 或直接查看最大尺寸
open Sources/SwiftScreenShot/Resources/Assets.xcassets/AppIcon.appiconset/icon_512x512@2x.png
```

### 构建应用

```bash
# 快速构建（Debug）
swift build

# 完整构建（包含 .app 包）
./scripts/build_with_icon.sh

# 运行应用
.build/debug/SwiftScreenShot

# 或运行 .app 包
open SwiftScreenShot.app
```

### 重新生成图标

如果需要修改图标设计：

```bash
# 1. 编辑图标生成脚本
vim scripts/generate_icons.swift

# 2. 重新生成
./scripts/generate_icons.swift

# 3. 清理并重新构建
swift package clean
swift build
```

## 图标显示位置

### 1. 应用图标

图标会自动显示在：

- ✓ **Dock 栏**: 当应用运行时
- ✓ **应用切换器**: 按 ⌘+Tab 时
- ✓ **Finder**: 应用程序文件夹和搜索结果
- ✓ **启动台**: Launchpad 中
- ✓ **活动监视器**: 进程列表中

### 2. 菜单栏图标

当前使用 SF Symbol `camera.viewfinder`：

- ✓ 自动适配亮色/暗色模式
- ✓ 更小更清晰
- ✓ 符合 macOS 设计规范

位置：`MenuBarController.swift` 第 26 行

## 验证清单

在发布应用前，请确认：

- [ ] 所有 10 个 PNG 图标文件都已生成
- [ ] 构建成功（无错误和警告）
- [ ] 在 Dock 中可以看到正确的图标
- [ ] 在不同主题下图标显示正常
- [ ] .app 包包含图标资源
- [ ] Info.plist 正确配置了图标引用

验证命令：

```bash
# 检查图标文件
ls -lh Sources/SwiftScreenShot/Resources/Assets.xcassets/AppIcon.appiconset/*.png

# 检查构建
swift build

# 验证 Info.plist
grep -A1 "CFBundleIconFile" Sources/SwiftScreenShot/Resources/Info.plist
```

## 下一步

### 可选的增强功能

1. **创建 .icns 文件** (macOS 传统格式):
   ```bash
   # 创建临时目录
   mkdir AppIcon.iconset

   # 复制并重命名文件
   cp Sources/SwiftScreenShot/Resources/Assets.xcassets/AppIcon.appiconset/icon_*.png AppIcon.iconset/

   # 生成 .icns
   iconutil -c icns AppIcon.iconset -o AppIcon.icns

   # 清理
   rm -rf AppIcon.iconset
   ```

2. **添加暗色模式变体**:
   - 在 Assets.xcassets 中创建 Dark Appearance 变体
   - 为暗色模式优化颜色

3. **创建营销素材**:
   - 使用 512x512 图标创建 App Store 截图
   - 制作网站和社交媒体图片

4. **国际化图标** (如果需要):
   - 为不同语言创建本地化版本
   - 添加地区特定的变体

### 启用 Git Hooks

```bash
# 安装 pre-commit hook
ln -sf ../../hooks/pre-commit .git/hooks/pre-commit

# 测试 hook
git add .
git commit -m "test"  # 会自动检查图标
```

## 常见问题

### Q: 构建后看不到图标？

**A**: 尝试以下步骤：
```bash
# 1. 清理构建
swift package clean

# 2. 重新生成图标
./scripts/generate_icons.swift

# 3. 完整构建
./scripts/build_with_icon.sh

# 4. 运行 .app 包（而不是直接运行可执行文件）
open SwiftScreenShot.app
```

### Q: 图标在 Dock 中显示为通用图标？

**A**: 这通常是因为：
1. 直接运行可执行文件而不是 .app 包
2. 需要创建应用包

解决方法：
```bash
./scripts/build_with_icon.sh
open SwiftScreenShot.app
```

### Q: 如何在 Xcode 中查看？

**A**:
```bash
# 生成 Xcode 项目
swift package generate-xcodeproj

# 在 Xcode 中打开
open SwiftScreenShot.xcodeproj
```

然后在项目导航器中找到 `Assets.xcassets`。

## 技术细节

### 资源处理流程

1. **开发时**:
   - 图标存储在 `Assets.xcassets/AppIcon.appiconset/`
   - Swift Package Manager 识别为资源

2. **构建时**:
   - SPM 复制 Assets.xcassets 到构建目录
   - `actool` 编译资源（如果可用）
   - 生成优化的资源 bundle

3. **运行时**:
   - 通过 `Bundle.main` 访问资源
   - `NSImage(named:)` 自动查找正确尺寸
   - macOS 根据需要选择合适的分辨率

### 配置关键点

**Package.swift**:
```swift
resources: [
    .process("SwiftScreenShot/Resources/Assets.xcassets")
]
```
- `.process()` 触发 Assets.xcassets 编译
- 自动处理不同尺寸和分辨率

**Info.plist**:
```xml
<key>CFBundleIconFile</key>
<string>AppIcon</string>
```
- 指向 Assets 中的图标集名称
- 不需要文件扩展名

## 支持与反馈

如果遇到问题或有改进建议：

1. 检查文档：
   - `docs/ICON_GUIDE.md` - 详细指南
   - `docs/ASSETS.md` - 资源管理
   - `scripts/README.md` - 脚本说明

2. 查看示例：
   - 所有图标已生成并可预览
   - 构建脚本提供完整流程示例

3. 调试构建：
   ```bash
   # 详细构建日志
   swift build --verbose

   # 查看资源复制
   swift build -v 2>&1 | grep Assets
   ```

## 完成状态

| 任务 | 状态 | 文件 |
|------|------|------|
| 设计应用图标 | ✅ | generate_icons.swift |
| 创建所有尺寸 | ✅ | AppIcon.appiconset/*.png |
| 配置 Assets.xcassets | ✅ | Contents.json |
| 更新 Package.swift | ✅ | 添加 resources 配置 |
| 更新 Info.plist | ✅ | 添加 CFBundleIconFile |
| 创建生成脚本 | ✅ | generate_icons.swift |
| 创建构建脚本 | ✅ | build_with_icon.sh |
| 创建预览脚本 | ✅ | preview_icon.sh |
| 编写文档 | ✅ | ICON_GUIDE.md, ASSETS.md |
| 添加 Git Hooks | ✅ | hooks/pre-commit |

**所有任务已完成！** 应用图标系统已完全配置并可以使用。

---

**创建日期**: 2024-12-13
**版本**: 1.0
**作者**: SwiftScreenShot 项目
