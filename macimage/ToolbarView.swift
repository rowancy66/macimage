import SwiftUI

struct ToolbarView: View {
    @ObservedObject var imageLoader: ImageLoader
    @Binding var scale: CGFloat
    @Binding var rotation: Double
    @Binding var isFullscreen: Bool
    @Binding var showInfo: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            // Previous
            Button(action: imageLoader.previousImage) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 14, weight: .medium))
            }
            .keyboardShortcut(.leftArrow, modifiers: [])
            .help("上一张 (←)")
            
            // Next
            Button(action: imageLoader.nextImage) {
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .medium))
            }
            .keyboardShortcut(.rightArrow, modifiers: [])
            .help("下一张 (→)")
            
            Divider()
                .frame(height: 20)
            
            // Zoom Out
            Button(action: { zoom(by: 0.8) }) {
                Image(systemName: "minus.magnifyingglass")
                    .font(.system(size: 14, weight: .medium))
            }
            .keyboardShortcut("-", modifiers: [])
            .help("缩小 (-)")
            
            // Zoom In
            Button(action: { zoom(by: 1.25) }) {
                Image(systemName: "plus.magnifyingglass")
                    .font(.system(size: 14, weight: .medium))
            }
            .keyboardShortcut("=", modifiers: [])
            .help("放大 (+)")
            
            // Fit Window
            Button(action: fitToWindow) {
                Image(systemName: "arrow.up.left.and.arrow.down.right")
                    .font(.system(size: 14, weight: .medium))
            }
            .keyboardShortcut("0", modifiers: [])
            .help("适配窗口 (0)")
            
            Divider()
                .frame(height: 20)
            
            // Rotate Left
            Button(action: { rotate(by: -90) }) {
                Image(systemName: "rotate.left")
                    .font(.system(size: 14, weight: .medium))
            }
            .keyboardShortcut("[", modifiers: [])
            .help("左旋 ([)")
            
            // Rotate Right
            Button(action: { rotate(by: 90) }) {
                Image(systemName: "rotate.right")
                    .font(.system(size: 14, weight: .medium))
            }
            .keyboardShortcut("]", modifiers: [])
            .help("右旋 (])")
            
            Divider()
                .frame(height: 20)
            
            // Fullscreen
            Button(action: toggleFullscreen) {
                Image(systemName: isFullscreen ? "arrow.down.right.and.arrow.up.left" : "arrow.up.left.and.arrow.down.right")
                    .font(.system(size: 14, weight: .medium))
            }
            .keyboardShortcut("f", modifiers: [])
            .help("全屏 (F)")
            
            // Info
            Button(action: { showInfo.toggle() }) {
                Image(systemName: "info.circle")
                    .font(.system(size: 14, weight: .medium))
            }
            .keyboardShortcut("i", modifiers: [])
            .help("图片信息 (I)")
            
            Spacer()
            
            // Image counter
            if !imageLoader.images.isEmpty {
                Text("\(imageLoader.currentIndex + 1) / \(imageLoader.images.count)")
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(.ultraThinMaterial)
    }
    
    private func zoom(by factor: CGFloat) {
        withAnimation(.easeInOut(duration: 0.2)) {
            scale *= factor
            scale = max(0.1, min(10.0, scale))
        }
    }
    
    private func fitToWindow() {
        withAnimation(.easeInOut(duration: 0.3)) {
            scale = 1.0
            rotation = 0
            offset = .zero
        }
    }
    
    private func rotate(by degrees: Double) {
        withAnimation(.easeInOut(duration: 0.3)) {
            rotation += degrees
        }
    }
    
    private func toggleFullscreen() {
        if isFullscreen {
            NSWindow.toggleFullScreen(nil)
        } else {
            NSWindow.toggleFullScreen(nil)
        }
        isFullscreen.toggle()
    }
}
