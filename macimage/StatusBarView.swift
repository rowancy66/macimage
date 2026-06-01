import SwiftUI

/// Refined status bar with clear visual hierarchy and elegant separators.
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
                HStack(spacing: 10) {
                    // Filename — primary, slightly larger
                    Text(filename)
                        .font(.system(size: 11.5, weight: .semibold, design: .monospaced))
                        .foregroundColor(.primary)
                        .lineLimit(1)
                    
                    separator
                    
                    // Metadata group
                    HStack(spacing: 8) {
                        MetaChip(icon: "aspectratio", value: dimensions)
                        MetaChip(icon: "externaldrive", value: fileSize)
                        Badge(format)
                    }
                    
                    if totalCount > 0 {
                        separator
                        
                        // Position indicator with accent
                        HStack(spacing: 3) {
                            Text("\(currentIndex)")
                                .font(.system(size: 11, weight: .semibold, design: .monospaced))
                                .foregroundColor(accent)
                            Text("/")
                                .font(.system(size: 10, design: .monospaced))
                                .foregroundColor(.secondary)
                            Text("\(totalCount)")
                                .font(.system(size: 10, design: .monospaced))
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            
            Spacer()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 7)
        .background(.ultraThinMaterial)
        .overlay(
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [Color.primary.opacity(0.1), Color.primary.opacity(0.04)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(height: 0.5),
            alignment: .top
        )
    }
    
    private var separator: some View {
        Circle()
            .fill(Color.primary.opacity(0.12))
            .frame(width: 3, height: 3)
    }
}

/// Small metadata chip with icon.
struct MetaChip: View {
    let icon: String
    let value: String
    
    var body: some View {
        HStack(spacing: 3) {
            Image(systemName: icon)
                .font(.system(size: 8.5, weight: .medium))
                .foregroundColor(.secondary.opacity(0.7))
            Text(value)
                .font(.system(size: 10.5, design: .monospaced))
                .foregroundColor(.secondary)
        }
    }
}

struct Hint: View {
    let key: String
    let label: String
    init(_ key: String, _ label: String) { self.key = key; self.label = label }
    
    var body: some View {
        HStack(spacing: 3) {
            Text(key)
                .font(.system(size: 9, weight: .medium, design: .monospaced))
                .foregroundColor(.primary.opacity(0.6))
                .padding(.horizontal, 4)
                .padding(.vertical, 1.5)
                .background(
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color.primary.opacity(0.05))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 3)
                        .strokeBorder(Color.primary.opacity(0.08), lineWidth: 0.5)
                )
            Text(label)
                .font(.system(size: 9))
                .foregroundColor(.secondary.opacity(0.5))
        }
    }
}

struct Badge: View {
    let text: String
    private let accent = Color(red: 1.0, green: 0.42, blue: 0.42)
    init(_ text: String) { self.text = text }
    var body: some View {
        Text(text.uppercased())
            .font(.system(size: 8.5, weight: .bold, design: .monospaced))
            .foregroundColor(accent.opacity(0.85))
            .padding(.horizontal, 6)
            .padding(.vertical, 2.5)
            .background(
                RoundedRectangle(cornerRadius: 3)
                    .fill(accent.opacity(0.08))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 3)
                    .strokeBorder(accent.opacity(0.15), lineWidth: 0.5)
            )
    }
}