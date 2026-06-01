import SwiftUI

/// Polished info overlay card with accent header, refined typography, and depth.
struct InfoOverlay: View {
    @ObservedObject var data: InfoData
    
    private let accent = Color(red: 1.0, green: 0.42, blue: 0.42)
    
    var body: some View {
        if data.filename.isEmpty {
            EmptyView()
        } else {
            VStack(alignment: .leading, spacing: 0) {
                // Header bar with accent
                HStack(spacing: 6) {
                    Image(systemName: "info.circle.fill")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(accent)
                    Text("图片信息")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.primary.opacity(0.9))
                    Spacer()
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 9)
                .background(accent.opacity(0.06))
                
                // Content
                VStack(alignment: .leading, spacing: 6) {
                    InfoRow(icon: "doc", label: "文件名", value: data.filename)
                    InfoRow(icon: "aspectratio", label: "尺寸", value: data.dimensions)
                    InfoRow(icon: "externaldrive", label: "大小", value: data.fileSize)
                    InfoRow(icon: "photo", label: "格式", value: data.format)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
            }
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(
                        LinearGradient(
                            colors: [accent.opacity(0.25), accent.opacity(0.08)],
                            startPoint: .top,
                            endPoint: .bottom
                        ),
                        lineWidth: 0.5
                    )
            )
            .shadow(color: .black.opacity(0.12), radius: 16, y: 6)
            .shadow(color: accent.opacity(0.06), radius: 8, y: 2)
            .fixedSize()
            .transition(.opacity.combined(with: .scale(scale: 0.96)))
        }
    }
}

struct InfoRow: View {
    let icon: String
    let label: String
    let value: String
    
    var body: some View {
        HStack(spacing: 10) {
            // Icon in subtle circle
            Image(systemName: icon)
                .font(.system(size: 9.5, weight: .medium))
                .foregroundColor(.secondary.opacity(0.65))
                .frame(width: 18, height: 18)
                .background(
                    Circle()
                        .fill(Color.primary.opacity(0.04))
                )
            
            Text(label)
                .font(.system(size: 10.5, weight: .medium))
                .foregroundColor(.secondary)
                .frame(width: 36, alignment: .leading)
            
            Spacer(minLength: 8)
            
            Text(value)
                .font(.system(size: 10.5, weight: .medium, design: .monospaced))
                .foregroundColor(.primary.opacity(0.85))
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