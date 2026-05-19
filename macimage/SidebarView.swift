import SwiftUI

/// Direction C — modern lightweight sidebar with refined thumbnails.
struct SidebarView: View {
    @ObservedObject var imageLoader: ImageLoader
    private let accent = Color(red: 1.0, green: 0.42, blue: 0.42)
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Label("缩略图", systemImage: "photo.on.rectangle")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.secondary)
                Spacer()
                Text("\(imageLoader.images.count) 张")
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Capsule().fill(Color.primary.opacity(0.06)))
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            
            Divider().opacity(0.5)
            
            // Thumbnails
            if imageLoader.images.isEmpty {
                Spacer()
                VStack(spacing: 6) {
                    Image(systemName: "photo.on.rectangle.angled")
                        .font(.system(size: 24))
                        .foregroundColor(.secondary.opacity(0.4))
                    Text("无图片")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }
                Spacer()
            } else {
                ScrollViewReader { proxy in
                    ScrollView(.vertical, showsIndicators: false) {
                        LazyVStack(spacing: 6) {
                            ForEach(Array(imageLoader.images.enumerated()), id: \.offset) { idx, url in
                                ThumbnailCell(url: url, isSelected: idx == imageLoader.currentIndex)
                                    .onTapGesture { imageLoader.jumpTo(index: idx) }
                                    .id(idx)
                            }
                        }
                        .padding(8)
                    }
                    .onChange(of: imageLoader.currentIndex) { newIdx in
                        withAnimation(.easeInOut(duration: 0.2)) {
                            proxy.scrollTo(newIdx, anchor: .center)
                        }
                    }
                }
            }
        }
        .frame(width: 210)
        .background(.ultraThinMaterial)
        .overlay(
            Rectangle()
                .fill(Color.primary.opacity(0.04))
                .frame(width: 1),
            alignment: .trailing
        )
    }
}

// MARK: - Thumbnail Cell

struct ThumbnailCell: View {
    let url: URL
    let isSelected: Bool
    @State private var thumb: NSImage?
    
    private let accent = Color(red: 1.0, green: 0.42, blue: 0.42)
    
    var body: some View {
        VStack(spacing: 3) {
            if let t = thumb {
                Image(nsImage: t)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 186, height: 108)
                    .clipped()
            } else {
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color.primary.opacity(0.04))
                    .frame(width: 186, height: 108)
                    .overlay(
                        Image(systemName: "photo")
                            .font(.system(size: 20))
                            .foregroundColor(.secondary.opacity(0.3))
                    )
            }
            
            Text(url.lastPathComponent)
                .font(.system(size: 9.5))
                .foregroundColor(isSelected ? .primary : .secondary)
                .lineLimit(1)
                .frame(width: 186, alignment: .leading)
        }
        .padding(5)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isSelected ? accent.opacity(0.08) : Color.clear)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(isSelected ? accent.opacity(0.35) : Color.clear, lineWidth: 1.5)
        )
        .onAppear { if thumb == nil { loadThumb() } }
    }
    
    private func loadThumb() {
        DispatchQueue.global(qos: .userInitiated).async {
            guard let img = NSImage(contentsOf: url) else { return }
            let size = NSSize(width: 186 * 2, height: 108 * 2)
            let t = NSImage(size: size)
            t.lockFocus()
            img.draw(in: NSRect(origin: .zero, size: size), from: .zero, operation: .sourceOver, fraction: 1)
            t.unlockFocus()
            DispatchQueue.main.async { self.thumb = t }
        }
    }
}
