import SwiftUI

struct StatusBarView: View {
    let filename: String
    let dimensions: String
    let fileSize: String
    let format: String
    let currentIndex: Int
    let totalCount: Int
    
    var body: some View {
        HStack(spacing: 6) {
            if !filename.isEmpty {
                Text(filename).font(.system(size: 11, design: .monospaced)).foregroundColor(.primary).lineLimit(1)
                Circle().fill(Color.secondary).frame(width: 3, height: 3)
                Text(dimensions).font(.system(size: 11, design: .monospaced)).foregroundColor(.secondary)
                Circle().fill(Color.secondary).frame(width: 3, height: 3)
                Text(fileSize).font(.system(size: 11, design: .monospaced)).foregroundColor(.secondary)
                Circle().fill(Color.secondary).frame(width: 3, height: 3)
                Text(format).font(.system(size: 10)).foregroundColor(.secondary)
                    .padding(.horizontal, 4).padding(.vertical, 1)
                    .background(Color.primary.opacity(0.08)).cornerRadius(3)
            }
            Spacer()
            HStack(spacing: 8) {
                HintLabel("← →", "翻页")
                HintLabel("Space", "下一张")
                HintLabel("F", "全屏")
                HintLabel("I", "信息")
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(.ultraThinMaterial)
    }
}

struct HintLabel: View {
    let key: String
    let label: String
    init(_ key: String, _ label: String) { self.key = key; self.label = label }
    var body: some View {
        HStack(spacing: 2) {
            Text(key).font(.system(size: 9, design: .monospaced)).foregroundColor(.secondary)
                .padding(.horizontal, 3).padding(.vertical, 1)
                .background(Color.primary.opacity(0.06)).cornerRadius(2)
            Text(label).font(.system(size: 9)).foregroundColor(.secondary.opacity(0.6))
        }
    }
}
