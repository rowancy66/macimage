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
        let actualSize = CGSize(width: CGFloat(cgThumb.width), height: CGFloat(cgThumb.height))
        return NSImage(cgImage: cgThumb, size: actualSize)
    }
}
