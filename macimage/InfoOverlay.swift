import SwiftUI

/// Direction C — card-style info overlay with accent border.
struct InfoOverlay: View {
    @ObservedObject var data: InfoData
    
    private let accent = Color(red: 1.0, green: 0.42, blue: 0.42)
    
    var body: some View {
        if data.filename.isEmpty {
            EmptyView()
        } else {
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 6) {
                    Image(systemName: "info.circle.fill")
                        .font(.system(size: 11))
                        .foregroundColor(accent)
                    Text("图片信息")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.primary)
                }
                
                Divider().opacity(0.3)
                
                InfoRow(icon: "doc", label: "文件名", value: data.filename)
                InfoRow(icon: "aspectratio", label: "尺寸", value: data.dimensions)
                InfoRow(icon: "externaldrive", label: "大小", value: data.fileSize)
                InfoRow(icon: "photo", label: "格式", value: data.format)
            }
            .padding(12)
            .background(.ultraThinMaterial)
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(accent.opacity(0.3), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.08), radius: 12, y: 4)
            .fixedSize()
        }
    }
}

struct InfoRow: View {
    let icon: String; let label: String; let value: String
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 10))
                .foregroundColor(.secondary)
                .frame(width: 14)
            Text(label)
                .font(.system(size: 10))
                .foregroundColor(.secondary)
            Spacer(minLength: 12)
            Text(value)
                .font(.system(size: 10, design: .monospaced))
                .foregroundColor(.primary)
                .lineLimit(1)
        }
    }
}

final class InfoData: ObservableObject {
    @Published var filename = ""
    @Published var dimensions = ""
    @Published var fileSize = ""
    @Published var format = ""
    
    func update(filename: String, dimensions: String, fileSize: String, format: String) {
        self.filename = filename; self.dimensions = dimensions
        self.fileSize = fileSize; self.format = format
    }
    
    func clear() {
        filename = ""; dimensions = ""; fileSize = ""; format = ""
    }
}
