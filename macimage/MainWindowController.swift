import AppKit
import SwiftUI

/// Manages the main image viewer window, toolbar, status bar, and user interactions.
final class MainWindowController: NSWindowController, NSToolbarDelegate {
    
    private(set) var imageView: ImageView!
    private var statusHost: NSHostingView<StatusBarView>!
    private var infoHost: NSHostingView<InfoOverlay>!
    private var sidebarHost: NSHostingView<SidebarView>!
    private var toastHost: NSHostingView<ToastView>?
    
    let imageLoader = ImageLoader()
    
    private var showInfo = false
    private var showSidebar: Bool
    private var infoData = InfoData()
    private var imageLeadingConstraint: NSLayoutConstraint?
    
    // Toolbar item identifiers
    private let toolbarItems: [(NSToolbarItem.Identifier, String, String, Selector)] = [
        (.init("prev"), "chevron.left", "上一张", #selector(tbPrev)),
        (.init("next"), "chevron.right", "下一张", #selector(tbNext)),
        (.space, "", "", #selector(tbNone)),
        (.init("zoomOut"), "minus.magnifyingglass", "缩小", #selector(tbZoomOut)),
        (.init("zoomIn"), "plus.magnifyingglass", "放大", #selector(tbZoomIn)),
        (.init("fit"), "arrow.down.left.and.arrow.up.right", "适配窗口", #selector(tbFit)),
        (.space, "", "", #selector(tbNone)),
        (.init("rotL"), "rotate.left", "左旋", #selector(tbRotL)),
        (.init("rotR"), "rotate.right", "右旋", #selector(tbRotR)),
        (.flexibleSpace, "", "", #selector(tbNone)),
        (.init("sidebar"), "sidebar.left", "侧边栏", #selector(tbSidebar)),
        (.init("info"), "info.circle", "图片信息", #selector(tbInfo)),
    ]
    
    init() {
        self.showSidebar = UserDefaults.standard.object(forKey: "showSidebarByDefault") == nil
            ? true
            : UserDefaults.standard.bool(forKey: "showSidebarByDefault")
        super.init(window: nil)
        buildWindow()
        setupCallbacks()
        setupKeyboardMonitor()
    }
    
    required init?(coder: NSCoder) { fatalError("init(coder:) not implemented") }
    
    // MARK: - Window Setup
    
    private func buildWindow() {
        let container = NSView()
        
        // Status bar
        statusHost = NSHostingView(rootView: StatusBarView(
            filename: "", dimensions: "", fileSize: "", format: "", currentIndex: 0, totalCount: 0
        ))
        statusHost.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(statusHost)
        
        // Sidebar
        sidebarHost = NSHostingView(rootView: SidebarView(imageLoader: imageLoader))
        sidebarHost.translatesAutoresizingMaskIntoConstraints = false
        sidebarHost.isHidden = !showSidebar
        container.addSubview(sidebarHost)
        
        // Image view
        imageView = ImageView(imageLoader: imageLoader)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(imageView)
        
        // Info overlay
        infoHost = NSHostingView(rootView: InfoOverlay(data: infoData))
        infoHost.translatesAutoresizingMaskIntoConstraints = false
        infoHost.isHidden = true
        infoHost.alphaValue = 0
        imageView.addSubview(infoHost)
        
        imageLeadingConstraint = imageView.leadingAnchor.constraint(
            equalTo: showSidebar ? sidebarHost.trailingAnchor : container.leadingAnchor
        )
        
        NSLayoutConstraint.activate([
            statusHost.bottomAnchor.constraint(equalTo: container.bottomAnchor),
            statusHost.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            statusHost.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            
            sidebarHost.topAnchor.constraint(equalTo: container.topAnchor),
            sidebarHost.bottomAnchor.constraint(equalTo: statusHost.topAnchor),
            sidebarHost.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            sidebarHost.widthAnchor.constraint(equalToConstant: 210),
            
            imageView.topAnchor.constraint(equalTo: container.topAnchor),
            imageView.bottomAnchor.constraint(equalTo: statusHost.topAnchor),
            imageView.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            imageLeadingConstraint!,
            
            infoHost.bottomAnchor.constraint(equalTo: imageView.bottomAnchor, constant: -8),
            infoHost.leadingAnchor.constraint(equalTo: imageView.leadingAnchor, constant: 8),
        ])
        
        let styleMask: NSWindow.StyleMask = [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView]
        let window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 1100, height: 700),
                              styleMask: styleMask, backing: .buffered, defer: false)
        window.title = "macimage"
        window.titlebarAppearsTransparent = false
        window.contentView = container
        window.center()
        window.delegate = self
        
        // NSToolbar
        let toolbar = NSToolbar(identifier: "main")
        toolbar.displayMode = .iconOnly
        toolbar.allowsUserCustomization = false
        toolbar.delegate = self
        window.toolbar = toolbar
        window.toolbarStyle = .unified
        
        self.window = window
        window.makeKeyAndOrderFront(nil)
    }
    
    // MARK: - NSToolbarDelegate
    
    func toolbarDefaultItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        toolbarItems.map { $0.0 }
    }
    
    func toolbarAllowedItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        toolbarItems.map { $0.0 }
    }
    
    func toolbar(_ toolbar: NSToolbar, itemForItemIdentifier itemIdentifier: NSToolbarItem.Identifier, willBeInsertedIntoToolbar flag: Bool) -> NSToolbarItem? {
        guard let info = toolbarItems.first(where: { $0.0 == itemIdentifier }) else { return nil }
        
        let item = NSToolbarItem(itemIdentifier: info.0)
        item.label = info.2
        item.paletteLabel = info.2
        item.toolTip = info.2
        item.isBordered = true
        item.image = NSImage(systemSymbolName: info.1, accessibilityDescription: info.2)?
            .withSymbolConfiguration(.init(pointSize: 14, weight: .medium))
        item.action = info.3
        item.target = self
        return item
    }
    
    // MARK: - Toolbar Actions
    
    @objc private func tbPrev() { imageLoader.previousImage() }
    @objc private func tbNext() { imageLoader.nextImage() }
    @objc private func tbZoomIn() { imageView.zoomIn() }
    @objc private func tbZoomOut() { imageView.zoomOut() }
    @objc private func tbFit() { imageView.fitToWindow() }
    @objc private func tbRotL() { imageLoader.rotateLeft() }
    @objc private func tbRotR() { imageLoader.rotateRight() }
    @objc private func tbNone() {}
    
    @objc func tbSidebar() {
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
    
    @objc func tbInfo() {
        showInfo.toggle()
        if showInfo {
            infoHost.isHidden = false
        }
        NSAnimationContext.runAnimationGroup({ context in
            context.duration = 0.25
            infoHost.animator().alphaValue = showInfo ? 1.0 : 0.0
            var frame = infoHost.frame
            if showInfo {
                frame.origin.y = frame.origin.y + 20
            } else {
                frame.origin.y = frame.origin.y - 20
            }
            infoHost.animator().frame = frame
        }) {
            if !self.showInfo {
                self.infoHost.isHidden = true
            }
        }
    }
    
    @objc private func toggleFullscreen() { window?.toggleFullScreen(nil) }
    
    @objc func editCopy() { imageLoader.copyImageToClipboard() }
    
    // MARK: - Callbacks
    
    private func setupCallbacks() {
        imageLoader.onStatusUpdate = { [weak self] in
            DispatchQueue.main.async { self?.updateStatusBar() }
        }
        
        imageLoader.onError = { [weak self] error in
            DispatchQueue.main.async {
                let message: String
                switch error {
                case .directoryNotReadable: message = "无法读取目录"
                case .noSupportedImages: message = "目录中无支持的图片"
                case .imageDecodeFailed: message = "图片解码失败"
                }
                self?.showToast(message: message, type: .error)
            }
        }
    }
    
    private func updateStatusBar() {
        guard let url = imageLoader.currentImageURL else {
            statusHost.rootView = StatusBarView(filename: "", dimensions: "", fileSize: "", format: "", currentIndex: 0, totalCount: 0)
            infoData.clear(); infoHost.rootView = InfoOverlay(data: infoData)
            window?.title = "macimage"
            return
        }
        let name = url.lastPathComponent
        let fmt = url.pathExtension.uppercased()
        var dims = "", size = ""
        if let img = imageLoader.originalImage { dims = "\(Int(img.size.width)) × \(Int(img.size.height))" }
        if let attrs = try? FileManager.default.attributesOfItem(atPath: url.path), let bytes = attrs[.size] as? Int64 {
            let f = ByteCountFormatter(); f.allowedUnits = [.useKB, .useMB, .useGB]; f.countStyle = .file
            size = f.string(fromByteCount: bytes)
        }
        statusHost.rootView = StatusBarView(filename: name, dimensions: dims, fileSize: size, format: fmt,
                                            currentIndex: imageLoader.currentIndex + 1, totalCount: imageLoader.images.count)
        infoData.update(filename: name, dimensions: dims, fileSize: size, format: fmt)
        infoHost.rootView = InfoOverlay(data: infoData)
        window?.title = "macimage — \(name)"
    }
    
    // MARK: - Keyboard
    
    private func setupKeyboardMonitor() {
        NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self = self, let w = self.window, w.isKeyWindow else { return event }
            switch event.keyCode {
            case 123: self.tbPrev(); return nil
            case 124: self.tbNext(); return nil
            case 49:  self.tbNext(); return nil
            case 3, 36: self.toggleFullscreen(); return nil
            case 53:
                if self.window!.styleMask.contains(.fullScreen) { self.toggleFullscreen(); return nil }
                return event
            case 33: self.tbRotL(); return nil
            case 30: self.tbRotR(); return nil
            case 27: self.tbZoomOut(); return nil
            case 24: self.tbZoomIn(); return nil
            case 29: self.tbFit(); return nil
            case 34: self.tbInfo(); return nil
            case 17: self.tbSidebar(); return nil
            case 8:
                if event.modifierFlags.contains(.command) { self.editCopy(); return nil }
                return event
            default: return event
            }
        }
    }
    
    // MARK: - Toast
    
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
    
    // MARK: - Public API for AppDelegate
    
    func openImage(_ url: URL) {
        let result = imageLoader.loadImage(url)
        if case .failure(let error) = result {
            let message: String
            switch error {
            case .directoryNotReadable: message = "无法读取目录"
            case .noSupportedImages: message = "目录中无支持的图片"
            case .imageDecodeFailed: message = "图片解码失败"
            }
            showToast(message: message, type: .error)
        }
    }
}

// MARK: - NSWindowDelegate

extension MainWindowController: NSWindowDelegate {
    func windowWillClose(_ notification: Notification) { NSApp.terminate(nil) }
}
