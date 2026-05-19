import AppKit
import Combine

/// State management for the image viewer.
final class ImageLoader: NSObject, ObservableObject {
    @Published var images: [URL] = []
    @Published var currentIndex: Int = 0
    private(set) var rotation: CGFloat = 0
    private var currentDirectory: URL?
    
    // Cached images — avoids recomputing on every access
    private var _cachedOriginal: NSImage?
    private var _cachedDisplay: NSImage?
    private var _cachedURL: URL?
    private var _cachedRotation: CGFloat = 0
    
    // Callbacks
    var onImagesLoaded: (() -> Void)?       // ImageView display update
    var onDisplayUpdate: (() -> Void)?      // ImageView display update (navigation/rotation)
    var onStatusUpdate: (() -> Void)?       // AppDelegate status bar update
    
    // Current image display (cached)
    var currentImageURL: URL? {
        guard currentIndex < images.count else { return nil }
        return images[currentIndex]
    }
    
    var originalImage: NSImage? {
        guard let url = currentImageURL else { _cachedOriginal = nil; return nil }
        if _cachedURL == url { return _cachedOriginal }
        _cachedURL = url
        _cachedOriginal = NSImage(contentsOf: url)
        _cachedDisplay = nil // force recompute
        return _cachedOriginal
    }
    
    var displayImage: NSImage? {
        guard let img = originalImage else { _cachedDisplay = nil; return nil }
        if _cachedRotation == rotation, let cached = _cachedDisplay { return cached }
        _cachedRotation = rotation
        _cachedDisplay = (rotation == 0) ? img : img.rotated(byDegrees: rotation)
        return _cachedDisplay
    }
    
    // MARK: - Load
    
    func loadImage(_ url: URL) {
        let directory = url.deletingLastPathComponent()
        currentDirectory = directory
        
        let fm = FileManager.default
        guard let contents = try? fm.contentsOfDirectory(
            at: directory,
            includingPropertiesForKeys: nil,
            options: [.skipsHiddenFiles]
        ) else { return }
        
        let exts = ImageLoader.supportedExtensions
        let imageFiles = contents
            .filter { exts.contains($0.pathExtension.lowercased()) }
            .sorted { $0.lastPathComponent.localizedStandardCompare($1.lastPathComponent) == .orderedAscending }
        
        guard !imageFiles.isEmpty else { return }
        
        // Path-based URL matching (URL.== unreliable across creation methods)
        let targetPath = url.resolvingSymlinksInPath().path
        let foundIndex = imageFiles.firstIndex { $0.resolvingSymlinksInPath().path == targetPath } ?? 0
        let savedIndex = HistoryManager.shared.getPosition(directory: directory)
        let finalIndex = savedIndex.map { $0 < imageFiles.count ? $0 : foundIndex } ?? foundIndex
        
        images = imageFiles
        currentIndex = finalIndex
        rotation = 0
        invalidateCache()
        
        onImagesLoaded?()
        onDisplayUpdate?()
        onStatusUpdate?()
    }
    
    // MARK: - Navigation
    
    func nextImage() {
        guard !images.isEmpty else { return }
        currentIndex = (currentIndex + 1) % images.count
        resetView()
    }
    
    func previousImage() {
        guard !images.isEmpty else { return }
        currentIndex = (currentIndex - 1 + images.count) % images.count
        resetView()
    }
    
    func jumpTo(index: Int) {
        guard index >= 0, index < images.count else { return }
        currentIndex = index
        resetView()
    }
    
    // MARK: - Rotation
    
    func rotateLeft() {
        rotation = (rotation - 90).truncatingRemainder(dividingBy: 360)
        if rotation < 0 { rotation += 360 }
        _cachedDisplay = nil // invalidate display cache
        notifyAll()
    }
    
    func rotateRight() {
        rotation = (rotation + 90).truncatingRemainder(dividingBy: 360)
        _cachedDisplay = nil
        notifyAll()
    }
    
    // MARK: - Private
    
    private func resetView() {
        rotation = 0
        invalidateCache()
        savePosition()
        notifyAll()
    }
    
    private func invalidateCache() {
        _cachedURL = nil
        _cachedOriginal = nil
        _cachedDisplay = nil
        _cachedRotation = 0
    }
    
    private func notifyAll() {
        onDisplayUpdate?()
        onStatusUpdate?()
    }
    
    private func savePosition() {
        guard let dir = currentDirectory else { return }
        HistoryManager.shared.savePosition(directory: dir, index: currentIndex)
    }
    
    // MARK: - Copy
    
    func copyImageToClipboard() {
        guard let img = originalImage else { return }
        let pb = NSPasteboard.general
        pb.clearContents()
        pb.writeObjects([img])
    }
    
    // MARK: - Static
    
    static let supportedExtensions: Set<String> = [
        "jpg", "jpeg", "png", "gif", "bmp", "tiff", "tif", "webp"
    ]
}

// MARK: - NSImage Rotation

extension NSImage {
    func rotated(byDegrees degrees: CGFloat) -> NSImage {
        let rad = degrees * .pi / 180
        let newSize = NSSize(
            width: size.width * abs(cos(rad)) + size.height * abs(sin(rad)),
            height: size.width * abs(sin(rad)) + size.height * abs(cos(rad))
        )
        let img = NSImage(size: newSize)
        img.lockFocus()
        let t = NSAffineTransform()
        t.translateX(by: newSize.width / 2, yBy: newSize.height / 2)
        t.rotate(byRadians: rad)
        t.translateX(by: -size.width / 2, yBy: -size.height / 2)
        t.concat()
        draw(at: .zero, from: NSRect(origin: .zero, size: size), operation: .copy, fraction: 1)
        img.unlockFocus()
        return img
    }
}
