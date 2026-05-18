import SwiftUI

struct ToolbarView: View {
    let imageLoader: ImageLoader
    let imageView: ImageView
    let onToggleFullscreen: () -> Void
    let onToggleInfo: () -> Void
    let onCopy: () -> Void
    let onToggleSidebar: () -> Void
    
    @State private var counter = 0
    
    var body: some View {
        HStack(spacing: 8) {
            Button(action: { imageLoader.previousImage(); refresh() }) {
                Image(systemName: "chevron.left").font(.system(size: 13, weight: .medium))
            }.buttonStyle(.plain).help("上一张 (←)")
            
            Button(action: { imageLoader.nextImage(); refresh() }) {
                Image(systemName: "chevron.right").font(.system(size: 13, weight: .medium))
            }.buttonStyle(.plain).help("下一张 (→)")
            
            Divider().frame(height: 16)
            
            Button(action: { imageView.zoomOut() }) {
                Image(systemName: "minus.magnifyingglass").font(.system(size: 13, weight: .medium))
            }.buttonStyle(.plain).help("缩小 (-)")
            
            Button(action: { imageView.zoomIn() }) {
                Image(systemName: "plus.magnifyingglass").font(.system(size: 13, weight: .medium))
            }.buttonStyle(.plain).help("放大 (+)")
            
            Button(action: { imageView.fitToWindow() }) {
                Image(systemName: "arrow.down.left.and.arrow.up.right").font(.system(size: 13, weight: .medium))
            }.buttonStyle(.plain).help("适配窗口 (0)")
            
            Divider().frame(height: 16)
            
            Button(action: { imageLoader.rotateLeft(); refresh() }) {
                Image(systemName: "rotate.left").font(.system(size: 13, weight: .medium))
            }.buttonStyle(.plain).help("左旋 ([)")
            
            Button(action: { imageLoader.rotateRight(); refresh() }) {
                Image(systemName: "rotate.right").font(.system(size: 13, weight: .medium))
            }.buttonStyle(.plain).help("右旋 (])")
            
            Divider().frame(height: 16)
            
            Button(action: onToggleFullscreen) {
                Image(systemName: "arrow.up.left.and.arrow.down.right").font(.system(size: 13, weight: .medium))
            }.buttonStyle(.plain).help("全屏 (F)")
            
            Button(action: onToggleInfo) {
                Image(systemName: "info.circle").font(.system(size: 13, weight: .medium))
            }.buttonStyle(.plain).help("信息 (I)")
            
            Button(action: onCopy) {
                Image(systemName: "doc.on.doc").font(.system(size: 13, weight: .medium))
            }.buttonStyle(.plain).help("复制 (⌘C)")
            
            Button(action: onToggleSidebar) {
                Image(systemName: "sidebar.left").font(.system(size: 13, weight: .medium))
            }.buttonStyle(.plain).help("侧边栏 (T)")
            
            Spacer()
            
            if !imageLoader.images.isEmpty {
                Text("\(imageLoader.currentIndex + 1) / \(imageLoader.images.count)")
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundColor(.secondary)
                    .id(counter)
            }
        }
        .padding(.horizontal, 12).padding(.vertical, 6)
        .background(.regularMaterial)
    }
    
    private func refresh() { counter += 1 }
}
