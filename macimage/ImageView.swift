import AppKit

/// The main content view — hosts NSScrollView with NSImageView, handles drag-and-drop and context menu.
final class ImageView: NSView {
    
    let imageLoader: ImageLoader
    let scrollView: NSScrollView
    let imageView: NSImageView
    private let spinner: NSProgressIndicator
    private let emptyIcon: NSImageView
    private let emptyTitle: NSTextField
    private let emptySubtitle: NSTextField
    private var fitScale: CGFloat = 1.0
    private var needsFitAndCenter = false
    var onImageCountChanged: ((Int, Int) -> Void)?
    
    init(imageLoader: ImageLoader) {
        self.imageLoader = imageLoader
        
        scrollView = NSScrollView()
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = true
        scrollView.autohidesScrollers = true
        scrollView.backgroundColor = NSColor(srgbRed: 0.12, green: 0.12, blue: 0.12, alpha: 1.0)
        scrollView.drawsBackground = true
        scrollView.allowsMagnification = true
        scrollView.minMagnification = 0.05
        scrollView.maxMagnification = 32.0
        
        // Image view — scaleNone, let scrollView magnification handle zoom
        imageView = NSImageView()
        imageView.imageScaling = .scaleNone
        imageView.imageAlignment = .alignCenter
        imageView.isEditable = false
        imageView.wantsLayer = true
        
        scrollView.documentView = imageView
        
        // Loading spinner
        spinner = NSProgressIndicator()
        spinner.style = .spinning
        spinner.isHidden = true
        spinner.controlSize = .large
        
        // Empty state
        emptyIcon = NSImageView()
        emptyIcon.image = NSImage(systemSymbolName: "photo.on.rectangle.angled", accessibilityDescription: nil)
        emptyIcon.contentTintColor = .secondaryLabelColor
        emptyIcon.imageScaling = .scaleProportionallyDown
        
        emptyTitle = NSTextField(labelWithString: "拖拽图片到此处")
        emptyTitle.alignment = .center
        emptyTitle.textColor = NSColor(srgbRed: 0.85, green: 0.85, blue: 0.85, alpha: 1.0)
        emptyTitle.font = .systemFont(ofSize: 16, weight: .medium)
        
        emptySubtitle = NSTextField(labelWithString: "或点击工具栏打开按钮选择图片")
        emptySubtitle.alignment = .center
        emptySubtitle.textColor = NSColor(srgbRed: 0.55, green: 0.55, blue: 0.55, alpha: 1.0)
        emptySubtitle.font = .systemFont(ofSize: 12)
        
        super.init(frame: .zero)
        
        wantsLayer = true
        layer?.backgroundColor = NSColor(srgbRed: 0.12, green: 0.12, blue: 0.12, alpha: 1.0).cgColor
        
        addSubview(scrollView)
        addSubview(spinner)
        addSubview(emptyIcon)
        addSubview(emptyTitle)
        addSubview(emptySubtitle)
        
        registerForDraggedTypes([.fileURL, .init("NSFilenamesPboardType"), .init("public.file-url")])
        
        setupContextMenu()
        
        imageLoader.onImagesLoaded = { [weak self] in
            DispatchQueue.main.async { self?.updateDisplay() }
        }
        
        imageLoader.onDisplayUpdate = { [weak self] in
            DispatchQueue.main.async { self?.updateDisplay() }
        }
        
        updateDisplay()
    }
    
    required init?(coder: NSCoder) { fatalError("init(coder:) not implemented") }
    
    override func layout() {
        super.layout()
        scrollView.frame = bounds
        spinner.frame = NSRect(x: (bounds.width - 32) / 2, y: (bounds.height - 32) / 2, width: 32, height: 32)
        
        let emptyStackHeight: CGFloat = 80
        let emptyY = (bounds.height - emptyStackHeight) / 2
        emptyIcon.frame = NSRect(x: (bounds.width - 48) / 2, y: emptyY + 32, width: 48, height: 48)
        emptyTitle.frame = NSRect(x: 0, y: emptyY, width: bounds.width, height: 22)
        emptySubtitle.frame = NSRect(x: 0, y: emptyY - 20, width: bounds.width, height: 18)
        
        if needsFitAndCenter {
            needsFitAndCenter = false
            fitToWindow()
            centerDocument()
        }
    }
    
    // MARK: - Context Menu
    
    private func setupContextMenu() {
        let menu = NSMenu()
        
        menu.addItem(NSMenuItem(title: "复制图片", action: #selector(ctxCopy), keyEquivalent: "").with(icon: "doc.on.doc"))
        menu.addItem(.separator())
        menu.addItem(NSMenuItem(title: "左旋 90°", action: #selector(ctxRotateLeft), keyEquivalent: "").with(icon: "rotate.left"))
        menu.addItem(NSMenuItem(title: "右旋 90°", action: #selector(ctxRotateRight), keyEquivalent: "").with(icon: "rotate.right"))
        menu.addItem(.separator())
        menu.addItem(NSMenuItem(title: "适配窗口", action: #selector(ctxFit), keyEquivalent: "").with(icon: "arrow.down.left.and.arrow.up.right"))
        menu.addItem(NSMenuItem(title: "实际大小", action: #selector(ctxActualSize), keyEquivalent: "").with(icon: "1.magnifyingglass"))
        menu.addItem(.separator())
        menu.addItem(NSMenuItem(title: "在访达中显示", action: #selector(ctxRevealInFinder), keyEquivalent: "").with(icon: "folder"))
        
        imageView.menu = menu
    }
    
    @objc private func ctxCopy() { imageLoader.copyImageToClipboard() }
    @objc private func ctxRotateLeft() { imageLoader.rotateLeft() }
    @objc private func ctxRotateRight() { imageLoader.rotateRight() }
    @objc private func ctxFit() { fitToWindow() }
    @objc private func ctxActualSize() {
        guard let img = imageView.image else { return }
        let centerPoint = NSPoint(x: img.size.width / 2, y: img.size.height / 2)
        scrollView.setMagnification(1.0, centeredAt: centerPoint)
    }
    @objc private func ctxRevealInFinder() {
        guard let url = imageLoader.currentImageURL else { return }
        NSWorkspace.shared.activateFileViewerSelecting([url])
    }
    
    // MARK: - Display
    
    private func updateDisplay() {
        let hasImages = !imageLoader.images.isEmpty
        onImageCountChanged?(imageLoader.currentIndex + 1, imageLoader.images.count)
        
        if hasImages {
            setEmptyStateHidden(true)
            scrollView.isHidden = false
            spinner.isHidden = true
            spinner.stopAnimation(nil)
            
            if let img = imageLoader.displayImage {
                imageView.image = img
                imageView.frame.size = img.size
                imageView.needsDisplay = true
                
                needsFitAndCenter = true
                self.needsLayout = true
            }
        } else {
            setEmptyStateHidden(false)
            scrollView.isHidden = true
            imageView.image = nil
            spinner.isHidden = true
            spinner.stopAnimation(nil)
        }
    }
    
    private func setEmptyStateHidden(_ hidden: Bool) {
        emptyIcon.isHidden = hidden
        emptyTitle.isHidden = hidden
        emptySubtitle.isHidden = hidden
    }
    
    func zoomIn() {
        let oldMag = scrollView.magnification
        let newMag = min(oldMag * 1.5, scrollView.maxMagnification)
        scrollView.magnification = newMag
    }
    
    func zoomOut() {
        let oldMag = scrollView.magnification
        let newMag = max(oldMag * 0.75, scrollView.minMagnification)
        scrollView.magnification = newMag
    }
    
    func fitToWindow() {
        guard let img = imageView.image, img.size.width > 0, img.size.height > 0 else { return }
        let vs = scrollView.bounds.size
        guard vs.width > 0, vs.height > 0 else { return }
        fitScale = min(vs.width / img.size.width, vs.height / img.size.height)
        scrollView.magnification = max(0.05, min(fitScale, 32.0))
    }
    
    private func centerDocument() {
        guard let docView = scrollView.documentView else { return }
        let visible = scrollView.documentVisibleRect
        let docBounds = docView.bounds
        let x = (docBounds.width - visible.width) / 2
        let y = (docBounds.height - visible.height) / 2
        docView.scroll(NSPoint(x: max(0, x), y: max(0, y)))
    }
    
    // MARK: - Loading
    
    func startLoading() {
        spinner.isHidden = false
        spinner.startAnimation(nil)
    }
    
    func stopLoading() {
        spinner.isHidden = true
        spinner.stopAnimation(nil)
    }
    
    // MARK: - Drag & Drop
    
    override func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation { .copy }
    override func prepareForDragOperation(_ sender: NSDraggingInfo) -> Bool { true }
    
    override func performDragOperation(_ sender: NSDraggingInfo) -> Bool {
        if let urls = sender.draggingPasteboard.readObjects(forClasses: [NSURL.self]) as? [URL],
           let url = urls.first {
            imageLoader.loadImage(url)
            return true
        }
        if let paths = sender.draggingPasteboard.propertyList(
            forType: .init("NSFilenamesPboardType")) as? [String],
           let path = paths.first {
            imageLoader.loadImage(URL(fileURLWithPath: path))
            return true
        }
        return false
    }
}

extension NSMenuItem {
    func with(icon systemName: String) -> NSMenuItem {
        image = NSImage(systemSymbolName: systemName, accessibilityDescription: nil)
        return self
    }
}
