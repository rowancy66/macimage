import SwiftUI

/// Refined sidebar with polished thumbnails, accent selection, and visual depth.
struct SidebarView: View {
    @ObservedObject var imageLoader: ImageLoader
    private let accent = Color(red: 1.0, green: 0.42, blue: 0.42)
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack(spacing: 6) {
                Image(systemName: "photo.on.rectangle")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(accent)
                Text("缩略图")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.primary.opacity(0.85))
                Spacer()
                Text("\(imageLoader.images.count) 张")
                    .font(.system(size: 10, weight: .medium, design: .monospaced))
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(
                        Capsule()
                            .fill(Color.primary.opacity(0.05))
                    )
                    .overlay(
                        Capsule()
                            .strokeBorder(Color.primary.opacity(0.06), lineWidth: 0.5)
                    )
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(Color.primary.opacity(0.02))
            
            Rectangle()
                .fill(Color.primary.opacity(0.06))
                .frame(height: 0.5)
            
            // Thumbnails
            if imageLoader.images.isEmpty {
                Spacer()
                VStack(spacing: 10) {
                    ZStack {
                        Circle()
                            .fill(Color.primary.opacity(0.04))
                            .frame(width: 52, height: 52)
                        Image(systemName: "photo.on.rectangle.angled")
                            .font(.system(size: 22, weight: .light))
                            .foregroundColor(.secondary.opacity(0.35))
                    }
                    Text("无图片")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.secondary.opacity(0.6))
                }
                Spacer()
            } else {
                ScrollViewReader { proxy in
                    ScrollView(.vertical, showsIndicators: false) {
                        LazyVStack(spacing: 4) {
                            ForEach(Array(imageLoader.images.enumerated()), id: \.offset) { idx, url in
                                ThumbnailCell(url: url, isSelected: idx == imageLoader.currentIndex)
                                    .onTapGesture { imageLoader.jumpTo(index: idx) }
                                    .id(idx)
                            }
                        }
                        .padding(.vertical, 6)
                    }
                    .onChange(of: imageLoader.currentIndex) { newIdx in
                        withAnimation(.easeInOut(duration: 0.25)) {
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
                .fill(
                    LinearGradient(
                        colors: [Color.primary.opacity(0.06), Color.primary.opacity(0.03)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
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
    @State private var isHovered = false
    
    private let accent = Color(red: 1.0, green: 0.42, blue: 0.42)
    
    var body: some View {
        HStack(spacing: 0) {
            // Left accent bar for selection
            RoundedRectangle(cornerRadius: 1.5)
                .fill(isSelected ? accent : Color.clear)
                .frame(width: 3)
                .padding(.vertical, 4)
            
            VStack(spacing: 4) {
                if let t = thumb {
                    Image(nsImage: t)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 178, height: 104)
                        .clipped()
                        .clipShape(RoundedRectangle(cornerRadius: 5))
                        .overlay(
                            RoundedRectangle(cornerRadius: 5)
                                .strokeBorder(
                                    isSelected
                                        ? accent.opacity(0.5)
                                        : Color.primary.opacity(isHovered ? 0.12 : 0.06),
                                    lineWidth: isSelected ? 1.5 : 0.5
                                )
                        )
                        .shadow(
                            color: isSelected ? accent.opacity(0.15) : .black.opacity(isHovered ? 0.08 : 0.03),
                            radius: isSelected ? 6 : (isHovered ? 4 : 2),
                            y: isSelected ? 3 : 1
                        )
                } else {
                    RoundedRectangle(cornerRadius: 5)
                        .fill(
                            LinearGradient(
                                colors: [Color.primary.opacity(0.03), Color.primary.opacity(0.06)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 178, height: 104)
                        .overlay(
                            Image(systemName: "photo")
                                .font(.system(size: 18, weight: .light))
                                .foregroundColor(.secondary.opacity(0.25))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 5)
                                .strokeBorder(Color.primary.opacity(0.06), lineWidth: 0.5)
                        )
                }
                
                Text(url.lastPathComponent)
                    .font(.system(size: 9.5, weight: isSelected ? .medium : .regular))
                    .foregroundColor(isSelected ? accent : .secondary.opacity(isHovered ? 0.9 : 0.7))
                    .lineLimit(1)
                    .truncationMode(.middle)
                    .frame(width: 178, alignment: .leading)
            }
            .padding(.leading, 6)
            .padding(.trailing, 8)
            .padding(.vertical, 6)
        }
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(
                    isSelected
                        ? accent.opacity(0.08)
                        : (isHovered ? Color.primary.opacity(0.03) : Color.clear)
                )
        )
        .animation(.easeInOut(duration: 0.18), value: isSelected)
        .animation(.easeInOut(duration: 0.12), value: isHovered)
        .onAppear { if thumb == nil { loadThumb() } }
        .onDisappear { ThumbnailLoader.shared.cancelLoading(for: url) }
        .onHover { hovering in isHovered = hovering }
    }
    
    private func loadThumb() {
        let size = CGSize(width: 178 * 2, height: 104 * 2)
        ThumbnailLoader.shared.loadThumbnail(for: url, size: size) { image in
            self.thumb = image
        }
    }
}