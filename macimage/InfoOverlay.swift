import SwiftUI

struct InfoOverlay: View {
    @ObservedObject var data: InfoData
    
    var body: some View {
        if data.filename.isEmpty {
            EmptyView()
        } else {
            VStack(alignment: .leading, spacing: 6) {
                InfoRow(icon: "doc", label: "文件名", value: data.filename)
                InfoRow(icon: "aspectratio", label: "尺寸", value: data.dimensions)
                InfoRow(icon: "externaldrive", label: "大小", value: data.fileSize)
                InfoRow(icon: "photo", label: "格式", value: data.format)
            }
            .padding(10)
            .background(.ultraThinMaterial)
            .cornerRadius(8)
            .fixedSize()
        }
    }
}

struct InfoRow: View {
    let icon: String; let label: String; let value: String
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon).font(.system(size: 10)).foregroundColor(.secondary).frame(width: 14)
            Text(label).font(.system(size: 10)).foregroundColor(.secondary)
            Spacer(minLength: 8)
            Text(value).font(.system(size: 10, design: .monospaced)).foregroundColor(.primary).lineLimit(1)
        }
    }
}

final class InfoData: ObservableObject {
    @Published var filename = ""
    @Published var dimensions = ""
    @Published var fileSize = ""
    @Published var format = ""
    
    func update(filename: String, dimensions: String, fileSize: String, format: String) {
        self.filename = filename
        self.dimensions = dimensions
        self.fileSize = fileSize
        self.format = format
    }
    
    func clear() {
        filename = ""; dimensions = ""; fileSize = ""; format = ""
    }
}
