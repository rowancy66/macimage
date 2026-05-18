import Foundation

/// Simple position history using UserDefaults.
final class HistoryManager {
    static let shared = HistoryManager()
    
    private let defaults = UserDefaults.standard
    private let key = "com.macimage.browsing-history"
    
    private init() {}
    
    func savePosition(directory: URL, index: Int) {
        var history = loadHistory()
        history[directory.path] = index
        if history.count > 500, let oldest = history.keys.sorted().first {
            history.removeValue(forKey: oldest)
        }
        defaults.set(history, forKey: key)
    }
    
    func getPosition(directory: URL) -> Int? {
        loadHistory()[directory.path]
    }
    
    private func loadHistory() -> [String: Int] {
        defaults.dictionary(forKey: key) as? [String: Int] ?? [:]
    }
}
