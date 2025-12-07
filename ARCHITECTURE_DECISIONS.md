# 架构决策记录 (ADR)

## ADR-001: 截图技术选择

### 背景
macOS 提供多种截图 API，需要选择最适合的方案。

### 候选方案

#### 方案A: ScreenCaptureKit ⭐ 推荐
- **描述**: Apple 现代化的屏幕捕获框架
- **最低系统**: macOS 12.3+
- **优点**:
  - 官方推荐的现代 API
  - 性能优秀，异步设计
  - 权限管理清晰
  - 支持高 DPI 屏幕
  - 纯 Swift API
- **缺点**:
  - 仅支持较新系统
  - 需要屏幕录制权限
- **适用场景**: 目标用户使用 macOS 12.3+ (2022年3月发布)

#### 方案B: CGWindowListCreateImage
- **描述**: Core Graphics 传统截图 API
- **最低系统**: macOS 10.5+
- **优点**:
  - 兼容性极好
  - 不需要特殊权限（旧系统）
  - API 稳定
- **缺点**:
  - C API，不够 Swift 友好
  - 坐标系统复杂
  - 高 DPI 处理麻烦
- **适用场景**: 需要支持旧系统

#### 方案C: NSScreen + CGDisplayCreateImage
- **描述**: 结合 NSScreen 和 Core Graphics
- **最低系统**: macOS 10.0+
- **优点**:
  - 简单直接
  - 兼容性好
- **缺点**:
  - 同样是 C API
  - macOS 10.15+ 也需要权限
- **适用场景**: 全屏截图

### 决策
**选择方案A: ScreenCaptureKit**

### 理由
1. macOS 12.3 (2022年3月) 已经发布近3年，市场占有率高
2. Apple 官方推荐，长期支持保障
3. 性能和开发体验最佳
4. 微信等主流应用也已采用类似最低系统要求
5. 纯 Swift API，符合项目"尽量使用纯 Swift"的要求

### 影响
- 最低系统要求: macOS 12.3+
- 需要在 Info.plist 中添加屏幕录制权限说明
- 首次运行需要引导用户授权

---

## ADR-002: 全局快捷键实现

### 背景
需要注册系统级快捷键 Ctrl+Cmd+A。

### 候选方案

#### 方案A: Carbon Event Manager ⭐ 推荐
- **描述**: 使用 Carbon 框架的 RegisterEventHotKey
- **优点**:
  - 专门用于全局快捷键
  - 不需要辅助功能权限
  - 系统级别注册，可靠性高
  - 微信、QQ 等应用的成熟方案
- **缺点**:
  - C API，需要 Bridging Header
  - 代码稍显复杂
  - Carbon 框架已过时（但此 API 仍被支持）

#### 方案B: NSEvent.addGlobalMonitorForEvents
- **描述**: 监听所有键盘事件
- **优点**:
  - 纯 Swift API
  - 代码简洁
- **缺点**:
  - **需要辅助功能权限**（用户体验差）
  - 权限要求比屏幕录制更高
  - 性能开销大（监听所有事件）

#### 方案C: 第三方库 (MASShortcut, HotKey 等)
- **优点**:
  - 封装好的 API
  - 使用简单
- **缺点**:
  - 引入第三方依赖
  - 违背"纯 Swift"原则
  - 底层仍是 Carbon

### 决策
**选择方案A: Carbon Event Manager**

### 理由
1. 不需要额外权限，用户体验最佳
2. 业界成熟方案，稳定可靠
3. 虽然需要 Bridging Header，但可以封装为 Swift 友好的接口
4. Carbon 此部分 API 仍被 Apple 支持，不会废弃

### 实现要点
```swift
// 创建 Bridging Header
// SwiftScreenShot-Bridging-Header.h
#import <Carbon/Carbon.h>

// Swift 封装
class HotKeyManager {
    func register(key: UInt32, modifiers: UInt32) { ... }
}
```

---

## ADR-003: UI 框架选择

### 背景
应用需要菜单栏界面和设置窗口。

### 候选方案

#### 方案A: SwiftUI + AppKit 混合 ⭐ 推荐
- **描述**: 设置界面用 SwiftUI，菜单栏和选区用 AppKit
- **优点**:
  - 设置界面开发快速（SwiftUI）
  - 菜单栏和选区控制精确（AppKit）
  - 充分利用两者优势
- **缺点**:
  - 需要混合开发
  - 需要理解两套框架

#### 方案B: 纯 AppKit
- **优点**:
  - 单一框架，简单
  - 对系统控制力强
- **缺点**:
  - 设置界面开发繁琐
  - 代码量大

#### 方案C: 纯 SwiftUI
- **优点**:
  - 现代化开发体验
- **缺点**:
  - 菜单栏和全局窗口控制困难
  - 不适合系统级应用

### 决策
**选择方案A: SwiftUI + AppKit 混合**

### 理由
1. 设置界面使用 SwiftUI 可以快速开发出现代化 UI
2. 菜单栏和选区界面需要 AppKit 的精确控制
3. 混合使用是 macOS 应用的最佳实践
4. 微信等应用也采用类似混合方案

### 模块分配
- **AppKit**:
  - MenuBarController (菜单栏)
  - SelectionWindow (选区窗口)
  - SelectionView (选区视图)
- **SwiftUI**:
  - SettingsView (设置界面)
  - 未来的编辑工具界面

---

## ADR-004: 设置存储方案

### 背景
需要持久化用户设置。

### 候选方案

#### 方案A: UserDefaults ⭐ 推荐
- **优点**:
  - 系统原生，零依赖
  - API 简单
  - 适合简单键值对存储
- **缺点**:
  - 不适合复杂数据结构
  - 性能有限（但对设置足够）

#### 方案B: Core Data
- **优点**:
  - 功能强大
- **缺点**:
  - 过于复杂
  - 设置数据不需要关系型数据库

#### 方案C: JSON 文件
- **优点**:
  - 灵活
- **缺点**:
  - 需要手动处理文件读写
  - 没有类型安全

### 决策
**选择方案A: UserDefaults**

### 理由
1. 设置项简单（保存路径、格式、开机启动等）
2. UserDefaults 完全满足需求
3. 系统原生，稳定可靠
4. 与 @AppStorage 无缝集成（SwiftUI）

### 存储项
```swift
- shouldSaveToFile: Bool
- savePath: String
- imageFormat: String
- launchAtLogin: Bool
```

---

## ADR-005: 项目结构组织

### 背景
需要清晰的代码组织结构。

### 决策
采用**分层模块化架构**：

```
SwiftScreenShot/
├── App/                    # 应用层
│   ├── SwiftScreenShotApp.swift
│   └── AppDelegate.swift
├── Core/                   # 核心业务层
│   ├── HotKeyManager.swift
│   ├── ScreenshotEngine.swift
│   ├── ImageProcessor.swift
│   └── OutputManager.swift
├── UI/                     # 界面层
│   ├── MenuBar/
│   ├── Selection/
│   └── Settings/
├── Models/                 # 数据模型层
│   ├── ScreenshotSettings.swift
│   └── SelectionRegion.swift
└── Utilities/              # 工具层
    ├── PermissionManager.swift
    └── Extensions.swift
```

### 理由
1. **职责分离**: 每层负责明确的功能
2. **可测试性**: 核心逻辑与 UI 分离
3. **可维护性**: 模块化便于修改和扩展
4. **可扩展性**: 未来添加编辑工具等功能容易集成

---

## ADR-006: 多显示器支持策略

### 背景
用户可能有多个显示器。

### 决策
**每个显示器独立处理**

### 方案
1. 使用 `NSScreen.screens` 获取所有显示器
2. 按下快捷键时，检测鼠标所在的显示器
3. 仅在当前显示器显示选区界面
4. 坐标系统以该显示器为基准

### 理由
1. 用户通常只在当前显示器截图
2. 单显示器选区界面更直观
3. 避免跨显示器的坐标转换复杂性
4. 与微信截图行为一致

### 未来扩展
如需跨显示器截图，可以：
- 检测选区是否跨越多个显示器
- 分别捕获每个显示器的部分
- 拼接为完整图像

---

## 关键技术决策总结

| 决策点 | 选择方案 | 主要原因 |
|--------|---------|---------|
| 截图技术 | ScreenCaptureKit | 现代化、性能好、纯 Swift |
| 快捷键 | Carbon Event Manager | 无需额外权限、稳定 |
| UI 框架 | SwiftUI + AppKit | 各取所长、开发效率高 |
| 设置存储 | UserDefaults | 简单够用、系统原生 |
| 最低系统 | macOS 12.3+ | 市场占有率高、技术先进 |
| 项目结构 | 分层模块化 | 可维护、可扩展 |

## 风险与应对

### 风险1: 权限问题
- **风险**: 用户拒绝屏幕录制权限
- **应对**:
  - 首次运行清晰说明
  - 提供"打开系统偏好设置"按钮
  - 菜单栏显示权限状态

### 风险2: 快捷键冲突
- **风险**: Ctrl+Cmd+A 与其他应用冲突
- **应对**:
  - 在设置中允许自定义快捷键（v2.0）
  - 提供快捷键冲突检测和提示

### 风险3: 多显示器兼容性
- **风险**: 不同显示器配置可能有问题
- **应对**:
  - 充分测试各种配置
  - 提供日志记录功能
  - 社区反馈快速修复

## 下一步行动

1. ✅ **规划完成** - 技术方案已确定
2. ⏭️ **创建项目** - 使用 Xcode 创建 macOS App 项目
3. ⏭️ **实现核心功能** - 按照 IMPLEMENTATION_PLAN.md 的步骤执行
4. ⏭️ **测试与优化** - 多场景测试
5. ⏭️ **打包发布** - 准备分发

## 参考资料

- [ScreenCaptureKit 官方文档](https://developer.apple.com/documentation/screencapturekit)
- [Carbon Event Manager](https://developer.apple.com/documentation/carbon/event_manager)
- [macOS 人机界面指南](https://developer.apple.com/design/human-interface-guidelines/macos)
