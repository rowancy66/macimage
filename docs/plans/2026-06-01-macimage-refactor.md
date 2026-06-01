# macimage 重构与美化实现计划

> **For Claude:** Use executing-plans skill to implement this plan task-by-task.

## Remember
- Exact file paths always
- Complete code in plan (not "add validation")
- Exact commands with expected output
- DRY, YAGNI, TDD, frequent commits

---

## Overview

对 macimage 进行架构重构与界面美化：拆分 AppDelegate 职责、删除死代码、优化缩略图并发加载、增强错误处理、集成偏好设置、添加动画与 UI  polish。

## Prerequisites

- [x] macOS 13+ 开发环境
- [x] Swift 5.9+ 工具链
- [x] 当前工作目录：`/Users/cy/Documents/cola输出文件/mac看图小工具/macimage`
- [ ] `git status` 确认工作区干净（无未提交更改）

---

## Tasks

### Task 1: 删除死代码 ToolbarView.swift

**File:** `macimage/ToolbarView.swift` → 删除

#### Implementation
```bash
rm macimage/ToolbarView.swift
```

#### Verification
```bash
swift build
```
**Expected:** 编译通过（ToolbarView 未被任何其他文件引用）

---

### Task 2: 新建 ThumbnailLoader.swift

**File:** `macimage/ThumbnailLoader.swift` → 新建

#### Implementation
```swift
import AppKit
import Foundation

/// Manages concurrent thumbnail loading with caching.
final class ThumbnailLoader {
    static let shared = ThumbnailLoader()
    
    private let operationQueue: OperationQueue
    private let cache = NSCache<NSString, NSImage>()
    private var pendingOperations: [URL: Operation] = [:]
    private let lock = NSLock()
    
    private init() {
        operationQueue = OperationQueue()
        operationQueue.maxConcurrentOperationCount = 4
        operationQueue.qualityOfService = .userInitiated
        cache.countLimit = 200
    }
    
    func loadThumbnail(for url: URL, size: CGSize, completion: @escaping (NSImage?) -> Void) {
        let cacheKey = "\(url.resolvingSymlinksInPath().path)_\(Int(size.width))x\(Int(size.height))" as NSString
        
        if let cached = cache.object(forKey: cacheKey) {
            DispatchQueue.main.async { completion(cached) }
            return
        }
        
        let operation = BlockOperation { [weak self] in
            guard let self = self else { return }
            let thumb = self.generateThumbnail(for: url, size: size)
            if let thumb = thumb {
                self.cache.setObject(thumb, forKey: cacheKey)
            }
            DispatchQueue.main.async { completion(thumb) }
        }
        
        lock.lock()
        pendingOperations[url] = operation
        lock.unlock()
        
        operationQueue.addOperation(operation)
    }
    
    func cancelLoading(for url: URL) {
        lock.lock()
        if let op = pendingOperations[url], !op.isFinished {
            op.cancel()
        }
        pendingOperations.removeValue(forKey: url)
        lock.unlock()
    }
    
    func clearCache() {
        cache.removeAllObjects()
        lock.lock()
        pendingOperations.values.forEach { $0.cancel() }
        pendingOperations.removeAll()
        lock.unlock()
    }
    
    private func generateThumbnail(for url: URL, size: CGSize) -> NSImage? {
        guard let source = CGImageSourceCreateWithURL(url as CFURL, nil) else { return nil }
        let options: [NSString: Any] = [
            kCGImageSourceThumbnailMaxPixelSize: max(size.width, size.height) * 2,
            kCGImageSourceCreateThumbnailFromImageAlways: true
        ]
        guard let cgThumb = CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary) else { return nil }
        return NSImage(cgImage: cgThumb, size: size)
    }
}
```

#### Verification
```bash
swift build
```
**Expected:** 编译通过

---

### Task 3: 更新 SidebarView.swift 接入 ThumbnailLoader

**File:** `macimage/SidebarView.swift` → 修改

#### Implementation
- 替换 `ThumbnailCell` 的 `loadThumb()` 方法，使用 `ThumbnailLoader.shared.loadThumbnail()`
- 在 `onDisappear` 时调用 `cancelLoading`
- 优化选中态（增加阴影、scale 效果）

关键改动：
```swift
// ThumbnailCell 中替换 loadThumb()
.onDisappear {
    ThumbnailLoader.shared.cancelLoading(for: url)
}

// 选中态优化
.padding(5)
.background(
    RoundedRectangle(cornerRadius: 8)
        .fill(isSelected ? accent.opacity(0.12) : Color.clear)
)
.overlay(
    RoundedRectangle(cornerRadius: 8)
        .stroke(isSelected ? accent.opacity(0.4) : Color.clear, lineWidth: 1.5)
)
.shadow(color: isSelected ? accent.opacity(0.2) : .clear, radius: 4, y: 2)
.scaleEffect(isSelected ? 1.02 : 1.0)
.animation(.easeInOut(duration: 0.2), value: isSelected)

// 文件名颜色
Text(url.lastPathComponent)
    .font(.system(size: 9.5))
    .foregroundColor(isSelected ? accent : .secondary)
```

#### Verification
```bash
swift build
```
**Expected:** 编译通过

---

### Task 4: 优化 ImageLoader.swift（错误处理 + CoreImage 旋转）

**File:** `macimage/ImageLoader.swift` → 修改

#### Implementation

1. **增加错误枚举：**
```swift
enum ImageLoadError: Error {
    case directoryNotReadable
    case noSupportedImages
    case imageDecodeFailed
}
```

2. **修改 `loadImage` 返回结果：**
```swift
func loadImage(_ url: URL) -> Result<Void, ImageLoadError> {
    let directory = url.deletingLastPathComponent()
    currentDirectory = directory
    
    let fm = FileManager.default
    guard let contents = try? fm.contentsOfDirectory(
        at: directory, includingPropertiesForKeys: nil, options: [.skipsHiddenFiles]
    ) else {
        return .failure(.directoryNotReadable)
    }
    
    let exts = ImageLoader.supportedExtensions
    let imageFiles = contents
        .filter { exts.contains($0.pathExtension.lowercased()) }
        .sorted { $0.lastPathComponent.localizedStandardCompare($1.lastPathComponent) == .orderedAscending }
    
    guard !imageFiles.isEmpty else {
        return .failure(.noSupportedImages)
    }
    
    // ... 原有逻辑 ...
    
    images = imageFiles
    currentIndex = finalIndex
    rotation = 0
    invalidateCache()
    
    onImagesLoaded?()
    onDisplayUpdate?()
    onStatusUpdate?()
    
    return .success(())
}
```

3. **新增错误回调：**
```swift
var onError: ((ImageLoadError) -> Void)?
```

4. **替换旋转实现（CoreImage）：**
```swift
extension NSImage {
    func rotated(byDegrees degrees: CGFloat) -> NSImage? {
        guard let cgImage = self.cgImage(forProposedRect: nil, context: nil, hints: nil) else { return nil }
        
        let ciImage = CIImage(cgImage: cgImage)
        let filter = CIFilter(name: "CIAffineTransform")
        filter?.setValue(ciImage, forKey: kCIInputImageKey)
        
        let rad = degrees * .pi / 180
        let transform = CGAffineTransform(translationX: ciImage.extent.midX, y: ciImage.extent.midY)
            .rotated(by: rad)
            .translatedBy(x: -ciImage.extent.midX, y: -ciImage.extent.midY)
        filter?.setValue(NSValue(cgAffineTransform: transform), forKey: kCIInputTransformKey)
        
        guard let output = filter?.outputImage else { return nil }
        let rep = NSCIImageRep(ciImage: output)
        let newImage = NSImage(size: rep.size)
        newImage.addRepresentation(rep)
        return newImage
    }
}
```

5. **处理 `displayImage` 中的可选：**
```swift
var displayImage: NSImage? {
    guard let img = originalImage else { _cachedDisplay = nil; return nil }
    if _cachedRotation == rotation, let cached = _cachedDisplay { return cached }
    _cachedRotation = rotation
    _cachedDisplay = (rotation == 0) ? img : img.rotated(byDegrees: rotation)
    return _cachedDisplay
}
```

#### Verification
```bash
swift build
```
**Expected:** 编译通过

---

### Task 5: 新建 ToastView.swift

**File:** `macimage/ToastView.swift` → 新建

#### Implementation
```swift
import SwiftUI

enum ToastType {
    case success, error, info
    
    var icon: String {
        switch self {
        case .success: return "checkmark.circle.fill"
        case .error: return "xmark.circle.fill"
        case .info: return "info.circle.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .success: return Color.green
        case .error: return Color.red
        case .info: return Color.blue
        }
    }
}

struct ToastView: View {
    let message: String
    let type: ToastType
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: type.icon)
                .font(.system(size: 14))
                .foregroundColor(type.color)
            Text(message)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.primary)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(.ultraThinMaterial)
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.primary.opacity(0.1), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.08), radius: 12, y: 4)
    }
}
```

#### Verification
```bash
swift build
```
**Expected:** 编译通过

---

### Task 6: 新建 MainWindowController.swift

**File:** `macimage/MainWindowController.swift` → 新建

#### Implementation

从 AppDelegate 迁移以下逻辑到 MainWindowController：
- `buildWindow()`（窗口创建、视图布局）
- `NSToolbarDelegate` 实现
- `updateStatusBar()`
- `setupKeyboardMonitor()`
- 工具栏按钮响应（`tbPrev`、`tbNext` 等）
- `tbSidebar()` 和 `tbInfo()` 的动画逻辑
- 偏好设置读取（`showSidebarByDefault`）
- Toast 展示逻辑

关键结构：
```swift
import AppKit
import SwiftUI

final class MainWindowController: NSWindowController, NSToolbarDelegate {
    
    private var imageView: ImageView!
    private var statusHost: NSHostingView<StatusBarView>!
    private var infoHost: NSHostingView<InfoOverlay>!
    private var sidebarHost: NSHostingView<SidebarView>!
    private var toastHost: NSHostingView<ToastView>?
    
    let imageLoader = ImageLoader()
    
    private var showInfo = false
    private var showSidebar: Bool
    private var infoData = InfoData()
    private var imageLeadingConstraint: NSLayoutConstraint?
    
    private let toolbarItems: [(NSToolbarItem.Identifier, String, String, Selector)] = [
        // ... 保持原有定义 ...
    ]
    
    init() {
        self.showSidebar = UserDefaults.standard.bool(forKey: "showSidebarByDefault")
        super.init(window: nil)
        buildWindow()
        setupCallbacks()
        setupKeyboardMonitor()
    }
    
    required init?(coder: NSCoder) { fatalError("init(coder:) not implemented") }
    
    // ... buildWindow, toolbar delegate, status update, keyboard monitor, toast ...
}
```

Toast 展示方法：
```swift
func showToast(message: String, type: ToastType) {
    guard let window = window, let contentView = window.contentView else { return }
    
    toastHost?.removeFromSuperview()
    
    let toast = NSHostingView(rootView: ToastView(message: message, type: type))
    toast.translatesAutoresizingMaskIntoConstraints = false
    toast.alphaValue = 0
    contentView.addSubview(toast)
    
    NSLayoutConstraint.activate([
        toast.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
        toast.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -40)
    ])
    
    NSAnimationContext.runAnimationGroup({ context in
        context.duration = 0.3
        toast.animator().alphaValue = 1.0
    })
    
    DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) { [weak self] in
        NSAnimationContext.runAnimationGroup({ context in
            context.duration = 0.2
            toast.animator().alphaValue = 0.0
        }, completionHandler: {
            toast.removeFromSuperview()
            if self?.toastHost == toast { self?.toastHost = nil }
        })
    }
    
    toastHost = toast
}
```

`tbSidebar` 带动画：
```swift
@objc private func tbSidebar() {
    showSidebar.toggle()
    NSAnimationContext.runAnimationGroup({ context in
        context.duration = 0.25
        sidebarHost.animator().isHidden = !showSidebar
        if let oldConstraint = imageLeadingConstraint {
            oldConstraint.isActive = false
        }
        let newConstraint = showSidebar
            ? imageView.leadingAnchor.constraint(equalTo: sidebarHost.trailingAnchor)
            : imageView.leadingAnchor.constraint(equalTo: window!.contentView!.leadingAnchor)
        newConstraint.isActive = true
        imageLeadingConstraint = newConstraint
        window?.contentView?.layoutSubtreeIfNeeded()
    })
}
```

#### Verification
```bash
swift build
```
**Expected:** 编译通过

---

### Task 7: 精简 AppDelegate.swift

**File:** `macimage/AppDelegate.swift` → 修改

#### Implementation

保留：
- `applicationDidFinishLaunching`：设置菜单、创建 `MainWindowController`、读取 `launchWithLastImage`
- `application(_:open:)`：接收文件打开
- `applicationShouldTerminateAfterLastWindowClosed`：读取 `quitOnClose`
- 菜单设置（`setupMenus`）
- `NSWindowDelegate` 扩展（`windowWillClose`）
- `NSMenuItem` 扩展

移除：
- `buildWindow`
- `updateStatusBar`
- `setupKeyboardMonitor`
- `NSToolbarDelegate` 实现
- 所有 `tb*` 工具栏响应方法（移到 MainWindowController）
- `showInfo`、`showSidebar`、`infoData` 等状态属性
- `imageLeadingConstraint`
- `imageView`、`statusHost`、`infoHost`、`sidebarHost` 属性

AppDelegate 精简后约 ~120 行。

`applicationDidFinishLaunching` 中增加 `launchWithLastImage` 逻辑：
```swift
func applicationDidFinishLaunching(_ notification: Notification) {
    setupMenus()
    
    let controller = MainWindowController()
    self.mainWindowController = controller
    
    if UserDefaults.standard.bool(forKey: "launchWithLastImage") {
        if let lastDir = HistoryManager.shared.getLastDirectory(),
           let lastIndex = HistoryManager.shared.getPosition(directory: lastDir),
           lastIndex >= 0 {
            let urls = try? FileManager.default.contentsOfDirectory(
                at: lastDir, includingPropertiesForKeys: nil, options: [.skipsHiddenFiles]
            )
            let imageFiles = urls?.filter { ImageLoader.supportedExtensions.contains($0.pathExtension.lowercased()) }
                .sorted { $0.lastPathComponent.localizedStandardCompare($1.lastPathComponent) == .orderedAscending }
            if let target = imageFiles?[safe: lastIndex] {
                controller.imageLoader.loadImage(target)
            }
        }
    }
}
```

> 注：`[safe:]` 需要给 `Array` 添加一个安全下标扩展。

#### Verification
```bash
swift build
```
**Expected:** 编译通过

---

### Task 8: 更新 HistoryManager.swift（标准化 key + 新增方法）

**File:** `macimage/HistoryManager.swift` → 修改

#### Implementation
```swift
import Foundation

final class HistoryManager {
    static let shared = HistoryManager()
    
    private let defaults = UserDefaults.standard
    private let key = "com.macimage.browsing-history"
    private let lastDirKey = "com.macimage.last-directory"
    
    private init() {}
    
    func savePosition(directory: URL, index: Int) {
        var history = loadHistory()
        let normalizedPath = directory.resolvingSymlinksInPath().path
        history[normalizedPath] = index
        if history.count > 500, let oldest = history.keys.sorted().first {
            history.removeValue(forKey: oldest)
        }
        defaults.set(history, forKey: key)
        defaults.set(normalizedPath, forKey: lastDirKey)
    }
    
    func getPosition(directory: URL) -> Int? {
        loadHistory()[directory.resolvingSymlinksInPath().path]
    }
    
    func getLastDirectory() -> URL? {
        guard let path = defaults.string(forKey: lastDirKey) else { return nil }
        return URL(fileURLWithPath: path)
    }
    
    private func loadHistory() -> [String: Int] {
        defaults.dictionary(forKey: key) as? [String: Int] ?? [:]
    }
}

extension Array {
    subscript(safe index: Int) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}
```

#### Verification
```bash
swift build
```
**Expected:** 编译通过

---

### Task 9: 更新 StatusBarView.swift（精简布局）

**File:** `macimage/StatusBarView.swift` → 修改

#### Implementation

移除右下角键盘提示区域，只保留左侧文件信息。

```swift
var body: some View {
    HStack(spacing: 0) {
        if !filename.isEmpty {
            HStack(spacing: 8) {
                Text(filename)
                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                    .foregroundColor(.primary)
                    .lineLimit(1)
                
                dot
                Text(dimensions).font(.system(size: 11, design: .monospaced)).foregroundColor(.secondary)
                dot
                Text(fileSize).font(.system(size: 11, design: .monospaced)).foregroundColor(.secondary)
                dot
                Badge(format)
                
                if totalCount > 0 {
                    dot
                    Text("\(currentIndex) / \(totalCount)")
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundColor(.secondary)
                }
            }
        }
        
        Spacer()
    }
    .padding(.horizontal, 12)
    .padding(.vertical, 6)
    .background(.ultraThinMaterial)
    .overlay(
        Rectangle().fill(Color.primary.opacity(0.12)).frame(height: 1),
        alignment: .top
    )
}
```

#### Verification
```bash
swift build
```
**Expected:** 编译通过

---

### Task 10: 更新 ImageView.swift（加载指示器 + 空状态 + 淡入动画）

**File:** `macimage/ImageView.swift` → 修改

#### Implementation

1. **新增加载指示器：**
```swift
private let spinner: NSProgressIndicator

// init 中
spinner = NSProgressIndicator()
spinner.style = .spinning
spinner.isHidden = true
addSubview(spinner)
```

2. **空状态重设计：**
替换 `emptyLabel` 为自定义 `EmptyStateView`（或直接在 layout 中绘制）：
```swift
private let emptyIcon = NSImageView()
private let emptyTitle = NSTextField(labelWithString: "拖拽图片到此处")
private let emptySubtitle = NSTextField(labelWithString: "或点击工具栏打开按钮选择图片")
```

3. **淡入淡出动画：**
```swift
private func updateDisplay() {
    let hasImages = !imageLoader.images.isEmpty
    onImageCountChanged?(imageLoader.currentIndex + 1, imageLoader.images.count)
    
    if hasImages {
        emptyLabel.isHidden = true
        scrollView.isHidden = false
        spinner.isHidden = true
        spinner.stopAnimation(nil)
        
        if let img = imageLoader.displayImage {
            CATransaction.begin()
            CATransaction.setAnimationDuration(0.2)
            let transition = CATransition()
            transition.type = .fade
            transition.duration = 0.2
            imageView.layer?.add(transition, forKey: "fade")
            imageView.image = img
            imageView.frame.size = img.size
            imageView.needsDisplay = true
            CATransaction.commit()
            
            scrollView.documentView?.scroll(NSPoint.zero)
            fitToWindow()
        }
    } else {
        emptyLabel.isHidden = false
        scrollView.isHidden = true
        imageView.image = nil
        spinner.isHidden = true
        spinner.stopAnimation(nil)
    }
}
```

4. **暴露加载开始/结束方法给 MainWindowController：**
```swift
func startLoading() {
    spinner.isHidden = false
    spinner.startAnimation(nil)
    spinner.frame = NSRect(x: (bounds.width - 32) / 2, y: (bounds.height - 32) / 2, width: 32, height: 32)
}

func stopLoading() {
    spinner.isHidden = true
    spinner.stopAnimation(nil)
}
```

#### Verification
```bash
swift build
```
**Expected:** 编译通过

---

### Task 11: 更新 InfoOverlay.swift（显示/隐藏动画）

**File:** `macimage/InfoOverlay.swift` → 修改

#### Implementation

动画通过 MainWindowController 的 `tbInfo()` 控制，使用 `NSAnimationContext`。

`InfoOverlay` 本身保持 SwiftUI 视图不变，动画由 `MainWindowController` 的 `NSHostingView` 宿主处理：
```swift
@objc private func tbInfo() {
    showInfo.toggle()
    NSAnimationContext.runAnimationGroup({ context in
        context.duration = 0.25
        infoHost.animator().alphaValue = showInfo ? 1.0 : 0.0
        var frame = infoHost.frame
        frame.origin.y = showInfo ? frame.origin.y : frame.origin.y - 20
        infoHost.animator().frame = frame
    })
}
```

#### Verification
```bash
swift build
```
**Expected:** 编译通过

---

### Task 12: 更新 PreferencesView.swift（暗色模式微调）

**File:** `macimage/PreferencesView.swift` → 修改

#### Implementation

微调 `AboutTab` 中图标颜色适配：
```swift
if let icon = NSImage(named: NSImage.applicationIconName) {
    Image(nsImage: icon)
        .resizable()
        .frame(width: 64, height: 64)
        .shadow(color: .black.opacity(0.1), radius: 8, y: 4)
}
```

微调分割线颜色：
所有 `Divider()` 增加 `.opacity(0.5)` 确保暗色模式下可见。

#### Verification
```bash
swift build
```
**Expected:** 编译通过

---

### Task 13: 验证主流程功能

#### Integration Verification

1. **编译检查：**
```bash
swift build -c release
```
**Expected:** 编译通过，0 errors，0 warnings。

2. **运行测试：**
```bash
.build/release/macimage
```
**Manual checks:**
- [ ] 拖拽图片打开正常
- [ ] ← → 翻页正常
- [ ] Space 下一张正常
- [ ] +/- 缩放正常，0 适配窗口正常
- [ ] [ / ] 旋转正常
- [ ] F 全屏 / Esc 退出全屏正常
- [ ] T 切换侧边栏（带动画）正常
- [ ] I 切换信息浮层（带动画）正常
- [ ] ⌘C 复制正常（显示 Toast）
- [ ] 偏好设置三个开关生效
- [ ] 空状态显示美观
- [ ] 大图片加载时有 spinner
- [ ] 缩略图选中态明显
- [ ] 状态栏只显示文件信息

---

## Rollback Plan

如果实现过程中出现严重问题：

1. 保留当前 git commit：`git add . && git commit -m "before refactor"`
2. 如需要回滚：`git reset --hard HEAD~1`
3. 或者使用 git stash：`git stash push -m "refactor WIP"`
4. 重新从原始代码开始

---

## 实现顺序总结

| 顺序 | 任务 | 预估时间 |
|------|------|---------|
| 1 | 删除 ToolbarView.swift | 1 min |
| 2 | 新建 ThumbnailLoader.swift | 15 min |
| 3 | 更新 SidebarView.swift | 10 min |
| 4 | 优化 ImageLoader.swift | 20 min |
| 5 | 新建 ToastView.swift | 10 min |
| 6 | 新建 MainWindowController.swift | 40 min |
| 7 | 精简 AppDelegate.swift | 20 min |
| 8 | 更新 HistoryManager.swift | 5 min |
| 9 | 更新 StatusBarView.swift | 5 min |
| 10 | 更新 ImageView.swift | 25 min |
| 11 | 更新 InfoOverlay.swift | 5 min |
| 12 | 更新 PreferencesView.swift | 5 min |
| 13 | 验证主流程 | 10 min |
| **总计** | | **~170 min** |
