import SwiftUI

/// Direction C — modern lightweight style: clean glass panels, rounded corners, coral accent.
struct ToolbarView: View {
    let imageLoader: ImageLoader
    let imageView: ImageView
    let onToggleFullscreen: () -> Void
    let onToggleInfo: () -> Void
    let onCopy: () -> Void
    let onToggleSidebar: () -> Void
    
    @State private var counter = 0
    
    private let accent = Color(red: 1.0, green: 0.42, blue: 0.42) // #FF6B6B
    
    var body: some View {
        HStack(spacing: 4) {
            Group {
                navBtn("chevron.left", "上一张 (←)") { imageLoader.previousImage(); refresh() }
                navBtn("chevron.right", "下一张 (→)") { imageLoader.nextImage(); refresh() }
            }
            
            separator
            
            Group {
                toolBtn("minus.magnifyingglass", "缩小 (-)") { imageView.zoomOut() }
                toolBtn("plus.magnifyingglass", "放大 (+)") { imageView.zoomIn() }
                toolBtn("arrow.down.left.and.arrow.up.right", "适配 (0)") { imageView.fitToWindow() }
            }
            
            separator
            
            Group {
                toolBtn("rotate.left", "左旋 ([)") { imageLoader.rotateLeft(); refresh() }
                toolBtn("rotate.right", "右旋 (])") { imageLoader.rotateRight(); refresh() }
            }
            
            separator
            
            Group {
                toolBtn("arrow.up.left.and.arrow.down.right", "全屏 (F)", onToggleFullscreen)
                toolBtn("info.circle", "信息 (I)", onToggleInfo)
                toolBtn("doc.on.doc", "复制 (⌘C)", onCopy)
                toolBtn("sidebar.left", "侧边栏 (T)", onToggleSidebar)
            }
            
            Spacer()
            
            if !imageLoader.images.isEmpty {
                pageCounter
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.06), radius: 8, y: 2)
        .padding(.horizontal, 8)
        .padding(.top, 6)
    }
    
    private var separator: some View {
        Rectangle()
            .fill(Color.primary.opacity(0.1))
            .frame(width: 1, height: 18)
            .padding(.horizontal, 2)
    }
    
    private var pageCounter: some View {
        HStack(spacing: 2) {
            Text("\(imageLoader.currentIndex + 1)")
                .font(.system(size: 12, weight: .semibold, design: .monospaced))
                .foregroundColor(accent)
            Text("/")
                .font(.system(size: 11, design: .monospaced))
                .foregroundColor(.secondary)
            Text("\(imageLoader.images.count)")
                .font(.system(size: 11, design: .monospaced))
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 4)
        .background(Capsule().fill(Color.primary.opacity(0.05)))
        .id(counter)
    }
    
    private func navBtn(_ icon: String, _ help: String, _ action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.primary)
                .frame(width: 30, height: 30)
                .background(Circle().fill(Color.primary.opacity(0.06)))
        }
        .buttonStyle(.plain)
        .help(help)
    }
    
    private func toolBtn(_ icon: String, _ help: String, _ action: @escaping () -> Void = {}) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .regular))
                .foregroundColor(.secondary)
                .frame(width: 28, height: 28)
        }
        .buttonStyle(.plain)
        .help(help)
    }
    
    private func refresh() { counter += 1 }
}
