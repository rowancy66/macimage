# macimage 重构与美化规格说明书

**日期**: 2026-06-01
**状态**: 待实现
**范围**: 架构拆分、性能优化、偏好设置生效、界面美化

---

## 1. 现状分析

macimage 是一款基于 Swift + AppKit/SwiftUI 的 macOS 轻量级图片查看器。当前代码存在以下问题：

1. **AppDelegate 职责过重**（321 行）：包揽了 app 生命周期、窗口布局、工具栏、菜单、键盘监听、状态更新、回调等全部职责。
2. **死代码存在**：`ToolbarView.swift` 定义了 SwiftUI 工具栏视图，但实际运行使用原生 `NSToolbar`。
3. **偏好设置未生效**：`PreferencesView.swift` 中三个 `@AppStorage` 开关仅存储了值，代码中从未读取和使用。
4. **缩略图加载无并发控制**：`ThumbnailCell.onAppear` 直接 `DispatchQueue.global().async`，打开大目录时会同时启动数百个后台线程。
5. **错误处理薄弱**：`ImageLoader.loadImage()` 中多处 `try?` 静默失败，用户无法感知加载失败的原因。
6. **图片旋转性能差**：使用 `lockFocus`/`unlockFocus` 纯 CPU 内存绘制，大图片（如 RAW、TIFF）旋转时显著卡顿。
7. **历史记录 key 冲突**：`HistoryManager` 使用 `URL.path` 做字典键，相同路径不同挂载方式会导致冲突。

---

## 2. 架构重构

### 2.1 核心拆分

#### AppDelegate（精简版）

职责范围：
- App 生命周期（`applicationDidFinishLaunching`、`open urls`）
- 菜单设置（保持现有的 5 个菜单结构）
- 全局键盘快捷键注册（保持现有的 keyDown monitor）
- 偏好设置读取与传递
- 创建并持有 `MainWindowController`
- `applicationShouldTerminateAfterLastWindowClosed`（读取 `quitOnClose` 偏好）

目标行数：~100 行

#### MainWindowController（新建）

职责范围：
- 窗口创建与布局（`buildWindow`）
- 视图层级管理（`statusHost`、`sidebarHost`、`imageView`、`infoHost`）
- `NSToolbar` 设置与代理实现
- 状态栏更新逻辑（从原 AppDelegate 移过来的 `updateStatusBar`）
- 键盘事件分发（从原 AppDelegate 移过来的 `setupKeyboardMonitor`）
- 工具栏按钮响应（`tbPrev`、`tbNext`、`tbZoomIn` 等）
- 响应偏好设置变化（如 `showSidebarByDefault`）
- 错误/Toast 展示
- 空状态视图管理

目标行数：~250 行

### 2.2 文件变更清单

| 文件 | 操作 | 说明 |
|------|------|------|
| `macimage/AppDelegate.swift` | 修改 | 精简为生命周期 + 菜单 + 偏好读取 |
| `macimage/MainWindowController.swift` | 新建 | 窗口、工具栏、状态栏、键盘、Toast |
| `macimage/ImageLoader.swift` | 修改 | 剥离缩略图逻辑，增强错误处理，优化旋转 |
| `macimage/ThumbnailLoader.swift` | 新建 | 缩略图并发加载 + 缓存 |
| `macimage/SidebarView.swift` | 修改 | 接入 ThumbnailLoader，优化选中态 |
| `macimage/ToolbarView.swift` | 删除 | 死代码 |
| `macimage/StatusBarView.swift` | 修改 | 精简布局，移除键盘提示 |
| `macimage/ImageView.swift` | 修改 | 加载指示器、空状态重设计、淡入淡出动画 |
| `macimage/InfoOverlay.swift` | 修改 | 显示/隐藏动画 |

### 2.3 ThumbnailLoader（新建）

接口设计：

```swift
final class ThumbnailLoader {
    static let shared = ThumbnailLoader()
    
    /// 异步加载缩略图，自动缓存
    func loadThumbnail(for url: URL, size: CGSize, completion: @escaping (NSImage?) -> Void)
    
    /// 预取消指定 URL 的加载任务
    func cancelLoading(for url: URL)
    
    /// 清空缓存
    func clearCache()
}
```

实现要点：
- 使用 `OperationQueue` 限制最大并发数为 4
- 使用 `NSCache<NSString, NSImage>` 缓存缩略图，键为 `url.path + "_\(size.width)x\(size.height)"`
- 加载前检查缓存，命中则直接回调
- `ThumbnailCell.onDisappear` 时调用 `cancelLoading` 避免滚动时浪费资源
- 缩略图生成使用 `CGImageSourceCreateThumbnailAtIndex`（硬件加速，比 `lockFocus` 快 3-5 倍）

### 2.4 ImageLoader 优化

#### 错误处理增强

当前 `loadImage` 的签名：
```swift
func loadImage(_ url: URL)
```

优化后：
```swift
enum ImageLoadError: Error {
    case directoryNotReadable
    case noSupportedImages
    case imageDecodeFailed
}

func loadImage(_ url: URL) -> Result<Void, ImageLoadError>
```

`MainWindowController` 根据错误类型显示不同的 Toast：
- `directoryNotReadable` → "无法读取目录权限"
- `noSupportedImages` → "目录中无支持的图片格式"
- `imageDecodeFailed` → "图片解码失败"

#### 旋转性能优化

当前实现（CPU 绘制）：
```swift
img.lockFocus()
// 手动 affine transform 绘制
img.unlockFocus()
```

优化后（CoreImage 硬件加速）：
```swift
func rotated(byDegrees degrees: CGFloat) -> NSImage? {
    guard let cgImage = self.cgImage(forProposedRect: nil, context: nil, hints: nil) else { return nil }
    let ciImage = CIImage(cgImage: cgImage)
    let filter = CIFilter(name: "CIAffineTransform")
    filter?.setValue(ciImage, forKey: kCIInputImageKey)
    let transform = CGAffineTransform(translationX: ciImage.extent.midX, y: ciImage.extent.midY)
        .rotated(by: degrees * .pi / 180)
        .translatedBy(x: -ciImage.extent.midX, y: -ciImage.extent.midY)
    filter?.setValue(NSValue(cgAffineTransform: transform), forKey: kCIInputTransformKey)
    guard let output = filter?.outputImage else { return nil }
    let rep = NSCIImageRep(ciImage: output)
    let newImage = NSImage(size: rep.size)
    newImage.addRepresentation(rep)
    return newImage
}
```

> 注：如果 `CIAffineTransform` 在特定 macOS 版本下行为异常，回退到 `CGImage` + `CGContext` 方案（仍比 `lockFocus` 快）。

### 2.5 HistoryManager 修复

将 key 从 `URL.path` 改为 `URL.resolvingSymlinksInPath().path`，减少重复 key 冲突。

---

## 3. 偏好设置集成

### 3.1 读取时机与行为

| 偏好项 | 读取位置 | 行为 |
|--------|---------|------|
| `launchWithLastImage` | AppDelegate `applicationDidFinishLaunching` | 若开启，启动时自动加载上次目录和图片。无历史记录时保持空状态。 |
| `showSidebarByDefault` | MainWindowController `buildWindow` | 若关闭，窗口初始状态隐藏侧边栏。 |
| `quitOnClose` | AppDelegate `applicationShouldTerminateAfterLastWindowClosed` | 若关闭，关闭窗口后不退出 app（保持后台运行，支持 Dock 再次打开）。 |

### 3.2 历史记录恢复

`HistoryManager` 新增方法：
```swift
func getLastDirectory() -> URL?  // 返回最近访问的目录
```

启动时：
1. 检查 `launchWithLastImage`
2. 若为 true，读取 `getLastDirectory()` 和对应位置
3. 调用 `imageLoader.loadImage(url)` 恢复状态

---

## 4. 界面美化

### 4.1 图片切换淡入淡出动画

在 `ImageView.updateDisplay()` 中，切换图片时：
- 旧图片淡出（0.15s）
- 新图片淡入（0.15s）
- 使用 `NSView` 的 `animator()` API 或 `CATransition`

实现方式：给 `imageView` 的 `layer` 添加 `CATransition`（type = fade, duration = 0.2）

### 4.2 空状态重设计

当前空状态：
```swift
emptyLabel = NSTextField(labelWithString: "拖拽图片到此处\n或双击图片文件用 macimage 打开")
```

优化后：
- 使用自定义 `NSView` 子类 `EmptyStateView`
- 居中放置一个较大的 SF Symbol 图标（`photo.on.rectangle.angled`，48pt，secondary color）
- 主文案："拖拽图片到此处"（16pt，primary color）
- 副文案："或点击工具栏打开按钮选择图片"（12pt，secondary color）
- 整体垂直居中，间距 12pt
- 暗色模式下自动适配颜色

### 4.3 加载指示器

在 `ImageView` 中新增 `NSProgressIndicator`（spinner 样式）：
- `loadImage` 开始时显示 spinner，居中覆盖在图片区域
- 图片加载完成后隐藏 spinner，触发淡入动画
- 如果加载失败（如解码失败），spinner 隐藏，显示 Toast

### 4.4 统一 Toast 反馈

新建 `ToastView.swift`（SwiftUI）：
- 位置：右下角，距离边缘 16pt
- 样式：圆角 10，背景 `ultraThinMaterial`，边框 1pt primary opacity 0.1
- 动画：slide-up + fade-in（0.3s），自动隐藏（2.5s）
- 类型：成功（绿色图标）、错误（红色图标）、信息（蓝色图标）

使用场景：
- 复制成功 → "已复制到剪贴板"
- 目录读取失败 → "无法读取目录"
- 无支持图片 → "目录中无图片"
- 图片解码失败 → "无法加载图片"

### 4.5 暗色模式微调

当前暗色模式下 `ultraThinMaterial` 对比度偏弱，调整：
- 状态栏和侧边栏背景保持 `ultraThinMaterial`
- accent color（珊瑚红 `#FF6B6B`）在暗色模式下自动调亮 10%
- 分割线从 `opacity(0.06)` 提升到 `opacity(0.12)`，确保暗色下可见
- 空状态图标在暗色模式下从 `opacity(0.4)` 提升到 `opacity(0.6)`

### 4.6 缩略图选中态优化

当前选中态：浅红背景 + 1.5pt 红边框

优化后：
- 选中背景色加深（`accent.opacity(0.12)`）
- 增加轻微阴影（`shadow(color: accent.opacity(0.3), radius: 4, y: 2)`）
- 轻微放大（`scaleEffect(isSelected ? 1.02 : 1.0)`）
- 动画过渡（0.2s easeInOut）
- 选中项文件名从 `.primary` 改为 `accent` 色，更醒目

### 4.7 状态栏精简

移除右下角键盘提示（`Hint("← →", "翻页")` 等），状态栏只保留：
- 文件名
- 尺寸
- 文件大小
- 格式 Badge

理由：键盘提示占用空间且对老用户无价值，功能已在 README 和菜单中说明。

### 4.8 信息浮层动画

当前 `infoHost.isHidden = !showInfo` 是瞬间切换。

优化后：
- 使用 `NSView` 的 `animator()` 做 translate + opacity 动画
- 显示：从下方 20pt 处 slide-up + fade-in（0.25s）
- 隐藏：slide-down + fade-out（0.2s）
- 使用 `CATransaction` 确保动画流畅

---

## 5. 边界情况处理

| 场景 | 处理方案 |
|------|---------|
| 打开不存在的文件 | `ImageLoader` 返回 `imageDecodeFailed`，`MainWindowController` 显示 Toast "图片不存在或无法访问" |
| 目录扫描结果为空 | `ImageLoader` 返回 `noSupportedImages`，状态栏显示 "0 张"，空状态保持可见 |
| 外接硬盘路径变化 | `HistoryManager` 使用 `resolvingSymlinksInPath().path` 标准化 key |
| 偏好设置窗口重复打开 | `PreferencesWindowController` 已是单例，直接 `makeKeyAndOrderFront` |
| 大量缩略图快速滚动 | `ThumbnailLoader` 的 `cancelLoading` 机制确保只有可见 cell 加载 |
| 大图片旋转时卡死 | `CoreImage` 硬件加速 + 在主线程异步执行，避免阻塞 UI |
| 内存压力 | `NSCache` 自动释放缩略图，`ImageLoader` 缓存单张图片，占用可控 |

---

## 6. 验证标准

重构完成后，以下行为必须保持不变：

1. 拖拽/双击打开图片正常工作
2. ← → 翻页、Space 下一张、F 全屏、Esc 退出全屏
3. +/- 缩放、0 适配窗口、[ / ] 旋转
4. T 切换侧边栏、I 切换信息浮层、⌘C 复制
5. 同目录自动扫描、按文件名排序
6. 菜单栏所有功能正常
7. 偏好设置窗口正常打开
8. 构建通过 `swift build -c release`

---

## 7. 反范围（不做的）

以下功能明确排除在本次重构之外：

- 多窗口支持（当前单窗口）
- 图片编辑（裁剪、滤镜、标注）
- 幻灯片播放模式
- 网络图片支持（HTTP/URL Scheme）
- 插件系统
- 国际化（仅保留中文）
- 测试用例编写（本次专注代码结构和体验）

---

## 8. 实现顺序建议

1. **清理死代码**：删除 `ToolbarView.swift`
2. **新建 ThumbnailLoader**：确保 SidebarView 能正常加载缩略图
3. **优化 ImageLoader**：增强错误处理 + CoreImage 旋转
4. **新建 MainWindowController**：从 AppDelegate 迁移窗口逻辑
5. **精简 AppDelegate**：剥离职责到 MainWindowController
6. **集成偏好设置**：读取三个开关
7. **界面美化**：动画、空状态、加载指示、Toast
8. **验证**：构建通过 + 功能回归测试
