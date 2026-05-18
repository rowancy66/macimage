import Foundation

class HistoryManager {
    static let shared = HistoryManager()
    
    private let defaults = UserDefaults.standard
    private let key = "com.macimage.browsing-history"
    
    private init() {}
    
    func savePosition(directory: URL, index: Int) {
        var history = loadHistory()
        history[directory.path] = index
        defaults.set(history, forKey: key)
    }
    
    func getPosition(directory: URL) -> Int? {
        let history = loadHistory()
        return history[directory.path]
    }
    
    private func loadHistory() -> [String: Int] {
        return defaults.dictionary(forKey: key) as? [String: Int] ?? [:]
    }
    
    func clearHistory() {
        defaults.removeObject(forKey: key)
    }
}
