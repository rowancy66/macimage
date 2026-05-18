import SwiftUI

struct SidebarView: View {
    @ObservedObject var imageLoader: ImageLoader
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("缩略图").font(.system(size: 11, weight: .semibold)).foregroundColor(.secondary)
                Spacer()
                Text("\(imageLoader.images.count) 张").font(.system(size: 10, design: .monospaced)).foregroundColor(.secondary)
            }
            .padding(.horizontal, 10).padding(.vertical, 6)
            .background(.regularMaterial)
            
            if imageLoader.images.isEmpty {
                Spacer()
                Text("无图片").font(.system(size: 11)).foregroundColor(.secondary)
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
                        .padding(6)
                    }
                    .onChange(of: imageLoader.currentIndex) { newIdx in
                        withAnimation { proxy.scrollTo(newIdx, anchor: .center) }
                    }
                }
            }
        }
        .frame(width: 200)
        .background(.ultraThinMaterial)
    }
}

struct ThumbnailCell: View {
    let url: URL
    let isSelected: Bool
    @State private var thumb: NSImage?
    
    var body: some View {
        VStack(spacing: 2) {
            if let t = thumb {
                Image(nsImage: t).resizable().aspectRatio(contentMode: .fill)
                    .frame(width: 180, height: 100).clipped().cornerRadius(4)
            } else {
                RoundedRectangle(cornerRadius: 4).fill(Color.primary.opacity(0.06))
                    .frame(width: 180, height: 100)
                    .overlay(ProgressView().scaleEffect(0.5))
            }
            Text(url.lastPathComponent).font(.system(size: 9)).lineLimit(1)
                .foregroundColor(isSelected ? .primary : .secondary)
                .frame(width: 180, alignment: .leading)
        }
        .padding(3)
        .background(isSelected ? Color.accentColor.opacity(0.12) : Color.clear)
        .cornerRadius(6)
        .onAppear { if thumb == nil { loadThumb() } }
    }
    
    private func loadThumb() {
        DispatchQueue.global(qos: .userInitiated).async {
            guard let img = NSImage(contentsOf: url) else { return }
            let size = NSSize(width: 180 * 2, height: 100 * 2)
            let t = NSImage(size: size)
            t.lockFocus()
            img.draw(in: NSRect(origin: .zero, size: size), from: .zero, operation: .sourceOver, fraction: 1)
            t.unlockFocus()
            DispatchQueue.main.async { self.thumb = t }
        }
    }
}
