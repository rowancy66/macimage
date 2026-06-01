import Foundation

/// Simple position history using UserDefaults.
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
