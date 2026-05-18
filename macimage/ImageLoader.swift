import Foundation
import AppKit
import UniformTypeIdentifiers

class ImageLoader: ObservableObject {
    @Published var images: [URL] = []
    @Published var currentIndex: Int = 0
    
    private var currentDirectory: URL?
    
    static let supportedExtensions: Set<String> = ["jpg", "jpeg", "png", "gif", "bmp", "tiff", "tif", "webp"]
    
    func loadImage(_ url: URL) {
        let directory = url.deletingLastPathComponent()
        currentDirectory = directory
        
        // Scan directory for supported images
        let fileManager = FileManager.default
        guard let contents = try? fileManager.contentsOfDirectory(
            at: directory,
            includingPropertiesForKeys: [.creationDateKey],
            options: [.skipsHiddenFiles]
        ) else { return }
        
        // Filter and sort by filename
        let imageFiles = contents
            .filter { Self.supportedExtensions.contains($0.pathExtension.lowercased()) }
            .sorted { $0.lastPathComponent.localizedStandardCompare($1.lastPathComponent) == .orderedAscending }
        
        // Find index of opened file
        let index = imageFiles.firstIndex(of: url) ?? 0
        
        DispatchQueue.main.async {
            self.images = imageFiles
            self.currentIndex = index
        }
        
        // Save last position
        HistoryManager.shared.savePosition(directory: directory, index: index)
    }
    
    func nextImage() {
        guard !images.isEmpty else { return }
        currentIndex = (currentIndex + 1) % images.count
        saveCurrentPosition()
    }
    
    func previousImage() {
        guard !images.isEmpty else { return }
        currentIndex = (currentIndex - 1 + images.count) % images.count
        saveCurrentPosition()
    }
    
    func jumpTo(index: Int) {
        guard index >= 0 && index < images.count else { return }
        currentIndex = index
        saveCurrentPosition()
    }
    
    func randomImage() {
        guard images.count > 1 else { return }
        var newIndex: Int
        repeat {
            newIndex = Int.random(in: 0..<images.count)
        } while newIndex == currentIndex
        currentIndex = newIndex
        saveCurrentPosition()
    }
    
    var currentImageURL: URL? {
        guard currentIndex < images.count else { return nil }
        return images[currentIndex]
    }
    
    var currentImage: NSImage? {
        guard let url = currentImageURL else { return nil }
        return NSImage(contentsOf: url)
    }
    
    var currentImageInfo: ImageInfo? {
        guard let url = currentImageURL else { return nil }
        return ImageInfo(url: url)
    }
    
    private func saveCurrentPosition() {
        guard let directory = currentDirectory else { return }
        HistoryManager.shared.savePosition(directory: directory, index: currentIndex)
    }
    
    func restoreLastPosition() {
        guard let directory = currentDirectory else { return }
        if let savedIndex = HistoryManager.shared.getPosition(directory: directory) {
            currentIndex = min(savedIndex, images.count - 1)
        }
    }
}

struct ImageInfo {
    let url: URL
    let filename: String
    let width: Int
    let height: Int
    let fileSize: Int64
    let format: String
    
    init?(url: URL) {
        guard let image = NSImage(contentsOf: url),
              let rep = image.representations.first else { return nil }
        
        self.url = url
        self.filename = url.lastPathComponent
        self.width = rep.pixelsWide
        self.height = rep.pixelsHigh
        
        let attributes = try? FileManager.default.attributesOfItem(atPath: url.path)
        self.fileSize = attributes?[.size] as? Int64 ?? 0
        
        self.format = url.pathExtension.uppercased()
    }
    
    var fileSizeFormatted: String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB, .useGB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: fileSize)
    }
}
