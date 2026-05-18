import AppKit
import SwiftUI

final class AppDelegate: NSObject, NSApplicationDelegate {
    
    private var window: NSWindow!
    private var imageView: ImageView!
    private var toolbarHost: NSHostingView<ToolbarView>!
    private var statusHost: NSHostingView<StatusBarView>!
    private var infoHost: NSHostingView<InfoOverlay>!
    private var sidebarHost: NSHostingView<SidebarView>!
    
    let imageLoader = ImageLoader()
    
    private var showInfo = false
    private var showSidebar = true
    private var infoData = InfoData()
    private var imageLeadingConstraint: NSLayoutConstraint?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        buildWindow()
        setupCallbacks()
        setupKeyboardMonitor()
    }
    
    func application(_ application: NSApplication, open urls: [URL]) {
        guard let url = urls.first else { return }
        imageLoader.loadImage(url)
    }
    
    // MARK: - Window Setup
    
    private func buildWindow() {
        let container = NSView()
        
        // Toolbar
        let placeholderIV = ImageView(imageLoader: imageLoader)
        toolbarHost = NSHostingView(rootView: ToolbarView(
            imageLoader: imageLoader, imageView: placeholderIV,
            onToggleFullscreen: { [weak self] in self?.window?.toggleFullScreen(nil) },
            onToggleInfo: { [weak self] in self?.toggleInfo() },
            onCopy: { [weak self] in self?.copyImageToClipboard() },
            onToggleSidebar: { [weak self] in self?.toggleSidebar() }
        ))
        toolbarHost.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(toolbarHost)
        
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
        
        // Rebuild toolbar with real imageView
        toolbarHost.rootView = ToolbarView(
            imageLoader: imageLoader, imageView: imageView,
            onToggleFullscreen: { [weak self] in self?.window?.toggleFullScreen(nil) },
            onToggleInfo: { [weak self] in self?.toggleInfo() },
            onCopy: { [weak self] in self?.copyImageToClipboard() },
            onToggleSidebar: { [weak self] in self?.toggleSidebar() }
        )
        
        // Layout
        imageLeadingConstraint = imageView.leadingAnchor.constraint(
            equalTo: showSidebar ? sidebarHost.trailingAnchor : container.leadingAnchor
        )
        
        NSLayoutConstraint.activate([
            toolbarHost.topAnchor.constraint(equalTo: container.topAnchor),
            toolbarHost.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            toolbarHost.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            
            statusHost.bottomAnchor.constraint(equalTo: container.bottomAnchor),
            statusHost.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            statusHost.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            
            sidebarHost.topAnchor.constraint(equalTo: toolbarHost.bottomAnchor),
            sidebarHost.bottomAnchor.constraint(equalTo: statusHost.topAnchor),
            sidebarHost.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            sidebarHost.widthAnchor.constraint(equalToConstant: 200),
            
            imageView.topAnchor.constraint(equalTo: toolbarHost.bottomAnchor),
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
        window.titlebarAppearsTransparent = true
        window.isMovableByWindowBackground = true
        window.contentView = container
        window.makeKeyAndOrderFront(nil)
        window.center()
        window.delegate = self
    }
    
    // MARK: - Sidebar Toggle
    
    private func toggleSidebar() {
        showSidebar.toggle()
        sidebarHost.isHidden = !showSidebar
        guard let container = window.contentView, let oldConstraint = imageLeadingConstraint else { return }
        
        oldConstraint.isActive = false
        let newConstraint: NSLayoutConstraint
        if showSidebar {
            newConstraint = imageView.leadingAnchor.constraint(equalTo: sidebarHost.trailingAnchor)
        } else {
            newConstraint = imageView.leadingAnchor.constraint(equalTo: container.leadingAnchor)
        }
        newConstraint.isActive = true
        imageLeadingConstraint = newConstraint
    }
    
    // MARK: - Info Toggle
    
    private func toggleInfo() {
        showInfo.toggle()
        infoHost.isHidden = !showInfo
    }
    
    // MARK: - Callbacks
    
    private func setupCallbacks() {
        imageLoader.onStatusUpdate = { [weak self] in
            DispatchQueue.main.async { self?.updateStatusBar() }
        }
    }
    
    private func updateStatusBar() {
        guard let url = imageLoader.currentImageURL else {
            statusHost.rootView = StatusBarView(filename: "", dimensions: "", fileSize: "", format: "",
                                                currentIndex: 0, totalCount: 0)
            infoData.clear()
            infoHost.rootView = InfoOverlay(data: infoData)
            return
        }
        let name = url.lastPathComponent
        let fmt = url.pathExtension.uppercased()
        var dims = "", size = ""
        if let img = imageLoader.originalImage {
            dims = "\(Int(img.size.width)) × \(Int(img.size.height))"
        }
        if let attrs = try? FileManager.default.attributesOfItem(atPath: url.path),
           let bytes = attrs[.size] as? Int64 {
            let f = ByteCountFormatter(); f.allowedUnits = [.useKB, .useMB, .useGB]; f.countStyle = .file
            size = f.string(fromByteCount: bytes)
        }
        statusHost.rootView = StatusBarView(filename: name, dimensions: dims, fileSize: size, format: fmt,
                                            currentIndex: imageLoader.currentIndex + 1, totalCount: imageLoader.images.count)
        infoData.update(filename: name, dimensions: dims, fileSize: size, format: fmt)
        infoHost.rootView = InfoOverlay(data: infoData)
    }
    
    private func copyImageToClipboard() {
        guard let image = imageLoader.originalImage else { return }
        let pb = NSPasteboard.general; pb.clearContents(); pb.writeObjects([image])
    }
    
    private func setupKeyboardMonitor() {
        NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self = self, let w = self.window, w.isKeyWindow else { return event }
            switch event.keyCode {
            case 123: self.imageLoader.previousImage(); return nil
            case 124: self.imageLoader.nextImage(); return nil
            case 49:  self.imageLoader.nextImage(); return nil
            case 3, 36: self.window.toggleFullScreen(nil); return nil
            case 53:
                if self.window.styleMask.contains(.fullScreen) { self.window.toggleFullScreen(nil); return nil }
                return event
            case 33: self.imageLoader.rotateLeft(); return nil
            case 30: self.imageLoader.rotateRight(); return nil
            case 27: self.imageView.zoomOut(); return nil
            case 24: self.imageView.zoomIn(); return nil
            case 29: self.imageView.fitToWindow(); return nil
            case 34: self.toggleInfo(); return nil
            case 17: self.toggleSidebar(); return nil
            case 8:
                if event.modifierFlags.contains(.command) { self.copyImageToClipboard(); return nil }
                return event
            default: return event
            }
        }
    }
}

extension AppDelegate: NSWindowDelegate {
    func windowWillClose(_ notification: Notification) { NSApp.terminate(nil) }
}
