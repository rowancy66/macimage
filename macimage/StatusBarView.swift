import SwiftUI

/// Direction C — refined status bar with clean typography.
struct StatusBarView: View {
    let filename: String
    let dimensions: String
    let fileSize: String
    let format: String
    let currentIndex: Int
    let totalCount: Int
    
    private let accent = Color(red: 1.0, green: 0.42, blue: 0.42)
    
    var body: some View {
        HStack(spacing: 0) {
            if !filename.isEmpty {
                // File info
                HStack(spacing: 8) {
                    Text(filename)
                        .font(.system(size: 11, weight: .medium, design: .monospaced))
                        .foregroundColor(.primary)
                        .lineLimit(1)
                    
                    dot
                    Text(dimensions).font(.system(size: 11, design: .monospaced)).foregroundColor(.secondary)
                    dot
                    Text(fileSize).font(.system(size: 11, design: .monospaced)).foregroundColor(.secondary)
                    dot
                    Badge(format)
                }
            }
            
            Spacer()
            
            // Keyboard hints
            if !filename.isEmpty {
                HStack(spacing: 10) {
                    Hint("← →", "翻页")
                    Hint("Space", "下一张")
                    Hint("0-9", "跳转")
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(.ultraThinMaterial)
        .overlay(
            Rectangle().fill(Color.primary.opacity(0.06)).frame(height: 1),
            alignment: .top
        )
    }
    
    private var dot: some View {
        Circle().fill(Color.primary.opacity(0.2)).frame(width: 3, height: 3)
    }
}

struct Hint: View {
    let key: String
    let label: String
    init(_ key: String, _ label: String) { self.key = key; self.label = label }
    
    var body: some View {
        HStack(spacing: 3) {
            Text(key)
                .font(.system(size: 9, design: .monospaced))
                .foregroundColor(.secondary)
                .padding(.horizontal, 3).padding(.vertical, 1)
                .background(RoundedRectangle(cornerRadius: 3).fill(Color.primary.opacity(0.06)))
            Text(label)
                .font(.system(size: 9))
                .foregroundColor(.secondary.opacity(0.5))
        }
    }
}

struct Badge: View {
    let text: String
    init(_ text: String) { self.text = text }
    var body: some View {
        Text(text)
            .font(.system(size: 9, weight: .semibold, design: .monospaced))
            .foregroundColor(.secondary)
            .padding(.horizontal, 5).padding(.vertical, 2)
            .background(RoundedRectangle(cornerRadius: 3).fill(Color.primary.opacity(0.06)))
    }
}
