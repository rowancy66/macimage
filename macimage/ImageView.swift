import AppKit

/// The main content view — hosts NSScrollView with NSImageView and handles drag-and-drop.
final class ImageView: NSView {
    
    let imageLoader: ImageLoader
    let scrollView: NSScrollView
    let imageView: NSImageView
    private let emptyLabel: NSTextField
    private var fitScale: CGFloat = 1.0
    
    var onImageCountChanged: ((Int, Int) -> Void)?
    
    init(imageLoader: ImageLoader) {
        self.imageLoader = imageLoader
        
        scrollView = NSScrollView()
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = true
        scrollView.autohidesScrollers = true
        scrollView.backgroundColor = .windowBackgroundColor
        scrollView.drawsBackground = true
        scrollView.allowsMagnification = true
        scrollView.minMagnification = 0.05
        scrollView.maxMagnification = 32.0
        
        // Image view — scaleNone, let scrollView magnification handle zoom
        imageView = NSImageView()
        imageView.imageScaling = .scaleNone
        imageView.imageAlignment = .alignCenter
        imageView.isEditable = false
        
        scrollView.documentView = imageView
        
        emptyLabel = NSTextField(labelWithString: "拖拽图片到此处\n或双击图片文件用 macimage 打开")
        emptyLabel.alignment = .center
        emptyLabel.textColor = .secondaryLabelColor
        emptyLabel.font = .systemFont(ofSize: 16)
        
        super.init(frame: .zero)
        
        addSubview(scrollView)
        addSubview(emptyLabel)
        
        registerForDraggedTypes([.fileURL, .init("NSFilenamesPboardType"), .init("public.file-url")])
        
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
        emptyLabel.frame = bounds
    }
    
    private func updateDisplay() {
        let hasImages = !imageLoader.images.isEmpty
        onImageCountChanged?(imageLoader.currentIndex + 1, imageLoader.images.count)
        
        if hasImages {
            emptyLabel.isHidden = true
            scrollView.isHidden = false
            
            if let img = imageLoader.displayImage {
                // Set image and its natural size as frame
                imageView.image = img
                imageView.frame.size = img.size
                imageView.needsDisplay = true
                
                // Make scrollView aware of content size change
                scrollView.documentView?.scroll(NSPoint.zero)
                
                fitToWindow()
            }
        } else {
            emptyLabel.isHidden = false
            scrollView.isHidden = true
            imageView.image = nil
        }
    }
    
    func zoomIn() { scrollView.animator().magnification *= 1.5 }
    func zoomOut() { scrollView.animator().magnification *= 0.75 }
    
    func fitToWindow() {
        guard let img = imageView.image, img.size.width > 0, img.size.height > 0 else { return }
        let vs = scrollView.bounds.size
        guard vs.width > 0, vs.height > 0 else { return }
        fitScale = min(vs.width / img.size.width, vs.height / img.size.height)
        scrollView.animator().magnification = max(0.05, min(fitScale, 32.0))
    }
    
    func toggleZoom() {
        let current = scrollView.magnification
        if abs(current - fitScale) < 0.01 {
            scrollView.animator().magnification = 1.0
        } else {
            scrollView.animator().magnification = fitScale
        }
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
