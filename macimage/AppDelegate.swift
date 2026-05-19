import AppKit
import SwiftUI

final class AppDelegate: NSObject, NSApplicationDelegate, NSToolbarDelegate {
    
    private var window: NSWindow!
    private var imageView: ImageView!
    private var statusHost: NSHostingView<StatusBarView>!
    private var infoHost: NSHostingView<InfoOverlay>!
    private var sidebarHost: NSHostingView<SidebarView>!
    
    let imageLoader = ImageLoader()
    
    private var showInfo = false
    private var showSidebar = true
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
    
    // MARK: - App Lifecycle
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        setupMenus()
        buildWindow()
        setupCallbacks()
        setupKeyboardMonitor()
    }
    
    func application(_ application: NSApplication, open urls: [URL]) {
        guard let url = urls.first else { return }
        imageLoader.loadImage(url)
    }
    
    // MARK: - Menus
    
    private func setupMenus() {
        let mainMenu = NSMenu()
        
        // App menu
        let appMenu = NSMenu()
        appMenu.addItem(NSMenuItem(title: "关于 macimage", action: #selector(NSApplication.orderFrontStandardAboutPanel(_:)), keyEquivalent: ""))
        appMenu.addItem(.separator())
        appMenu.addItem(NSMenuItem(title: "偏好设置...", action: #selector(showPreferences), keyEquivalent: ","))
        appMenu.addItem(.separator())
        appMenu.addItem(NSMenuItem(title: "隐藏 macimage", action: #selector(NSApplication.hide(_:)), keyEquivalent: "h"))
        appMenu.addItem(NSMenuItem(title: "隐藏其他", action: #selector(NSApplication.hideOtherApplications(_:)), keyEquivalent: "h").withModifier([.command, .option]))
        appMenu.addItem(NSMenuItem(title: "显示全部", action: #selector(NSApplication.unhideAllApplications(_:)), keyEquivalent: ""))
        appMenu.addItem(.separator())
        appMenu.addItem(NSMenuItem(title: "退出 macimage", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
        let appItem = NSMenuItem(); appItem.submenu = appMenu
        mainMenu.addItem(appItem)
        
        // File menu
        let fileMenu = NSMenu(title: "文件")
        fileMenu.addItem(NSMenuItem(title: "打开...", action: #selector(fileOpen), keyEquivalent: "o"))
        fileMenu.addItem(.separator())
        fileMenu.addItem(NSMenuItem(title: "关闭窗口", action: #selector(NSWindow.performClose(_:)), keyEquivalent: "w"))
        mainMenu.addItem(NSMenuItem(title: "文件", action: nil, keyEquivalent: "").with(submenu: fileMenu))
        
        // Edit menu
        let editMenu = NSMenu(title: "编辑")
        editMenu.addItem(NSMenuItem(title: "复制图片", action: #selector(editCopy), keyEquivalent: "c"))
        editMenu.addItem(NSMenuItem(title: "全选", action: #selector(NSResponder.selectAll(_:)), keyEquivalent: "a"))
        mainMenu.addItem(NSMenuItem(title: "编辑", action: nil, keyEquivalent: "").with(submenu: editMenu))
        
        // View menu
        let viewMenu = NSMenu(title: "显示")
        viewMenu.addItem(NSMenuItem(title: "显示/隐藏侧边栏", action: #selector(tbSidebar), keyEquivalent: "t"))
        viewMenu.addItem(NSMenuItem(title: "显示/隐藏图片信息", action: #selector(tbInfo), keyEquivalent: "i"))
        viewMenu.addItem(.separator())
        viewMenu.addItem(NSMenuItem(title: "放大", action: #selector(tbZoomIn), keyEquivalent: "="))
        viewMenu.addItem(NSMenuItem(title: "缩小", action: #selector(tbZoomOut), keyEquivalent: "-"))
        viewMenu.addItem(NSMenuItem(title: "适配窗口", action: #selector(tbFit), keyEquivalent: "0"))
        viewMenu.addItem(.separator())
        viewMenu.addItem(NSMenuItem(title: "上一张", action: #selector(tbPrev), keyEquivalent: String(Character(UnicodeScalar(NSLeftArrowFunctionKey)!))))
        viewMenu.addItem(NSMenuItem(title: "下一张", action: #selector(tbNext), keyEquivalent: String(Character(UnicodeScalar(NSRightArrowFunctionKey)!))))
        viewMenu.addItem(.separator())
        viewMenu.addItem(NSMenuItem(title: "进入全屏", action: #selector(toggleFullscreen), keyEquivalent: "f"))
        viewMenu.addItem(NSMenuItem(title: "左旋", action: #selector(tbRotL), keyEquivalent: "["))
        viewMenu.addItem(NSMenuItem(title: "右旋", action: #selector(tbRotR), keyEquivalent: "]"))
        mainMenu.addItem(NSMenuItem(title: "显示", action: nil, keyEquivalent: "").with(submenu: viewMenu))
        
        // Window menu
        let windowMenu = NSMenu(title: "窗口")
        windowMenu.addItem(NSMenuItem(title: "最小化", action: #selector(NSWindow.performMiniaturize(_:)), keyEquivalent: "m"))
        windowMenu.addItem(NSMenuItem(title: "缩放", action: #selector(NSWindow.performZoom(_:)), keyEquivalent: ""))
        windowMenu.addItem(.separator())
        windowMenu.addItem(NSMenuItem(title: "前置全部窗口", action: #selector(NSWindow.orderFrontRegardless), keyEquivalent: ""))
        mainMenu.addItem(NSMenuItem(title: "窗口", action: nil, keyEquivalent: "").with(submenu: windowMenu))
        
        NSApp.mainMenu = mainMenu
    }
    
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
        window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 1100, height: 700),
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
    
    @objc private func tbSidebar() {
        showSidebar.toggle()
        sidebarHost.isHidden = !showSidebar
        guard let container = window.contentView, let oldConstraint = imageLeadingConstraint else { return }
        oldConstraint.isActive = false
        let newConstraint: NSLayoutConstraint = showSidebar
            ? imageView.leadingAnchor.constraint(equalTo: sidebarHost.trailingAnchor)
            : imageView.leadingAnchor.constraint(equalTo: container.leadingAnchor)
        newConstraint.isActive = true
        imageLeadingConstraint = newConstraint
    }
    
    @objc private func tbInfo() { showInfo.toggle(); infoHost.isHidden = !showInfo }
    
    @objc private func toggleFullscreen() { window.toggleFullScreen(nil) }
    
    @objc private func editCopy() { imageLoader.copyImageToClipboard() }
    
    @objc private func fileOpen() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.jpeg, .png, .gif, .bmp, .tiff, .webP]
        panel.allowsMultipleSelection = false
        panel.begin { [weak self] response in
            guard response == .OK, let url = panel.url else { return }
            self?.imageLoader.loadImage(url)
        }
    }
    
    @objc private func showPreferences() { PreferencesWindowController.shared.show() }
    
    // MARK: - Callbacks
    
    private func setupCallbacks() {
        imageLoader.onStatusUpdate = { [weak self] in
            DispatchQueue.main.async { self?.updateStatusBar() }
        }
    }
    
    private func updateStatusBar() {
        guard let url = imageLoader.currentImageURL else {
            statusHost.rootView = StatusBarView(filename: "", dimensions: "", fileSize: "", format: "", currentIndex: 0, totalCount: 0)
            infoData.clear(); infoHost.rootView = InfoOverlay(data: infoData)
            window.title = "macimage"
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
        window.title = "macimage — \(name)"
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
                if self.window.styleMask.contains(.fullScreen) { self.toggleFullscreen(); return nil }
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
}

// MARK: - Helpers

extension NSMenuItem {
    func withModifier(_ modifier: NSEvent.ModifierFlags) -> NSMenuItem {
        keyEquivalentModifierMask = modifier
        return self
    }
    func with(submenu: NSMenu) -> NSMenuItem {
        self.submenu = submenu
        return self
    }
}

extension AppDelegate: NSWindowDelegate {
    func windowWillClose(_ notification: Notification) { NSApp.terminate(nil) }
}
