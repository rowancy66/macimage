import SwiftUI

struct ContentView: View {
    @StateObject private var imageLoader = ImageLoader()
    @State private var scale: CGFloat = 1.0
    @State private var rotation: Double = 0
    @State private var offset: CGSize = .zero
    @State private var isFullscreen = false
    @State private var showInfo = false
    @State private var jumpText = ""
    @State private var showJumpInput = false
    
    var body: some View {
        ZStack {
            // Background
            Color(nsColor: .windowBackgroundColor)
                .ignoresSafeArea()
            
            if let image = imageLoader.currentImage {
                VStack(spacing: 0) {
                    // Toolbar
                    ToolbarView(
                        imageLoader: imageLoader,
                        scale: $scale,
                        rotation: $rotation,
                        isFullscreen: $isFullscreen,
                        showInfo: $showInfo
                    )
                    
                    // Image viewer
                    GeometryReader { geometry in
                        ZStack {
                            ImageViewer(
                                image: image,
                                scale: $scale,
                                rotation: $rotation,
                                offset: $offset
                            )
                            .frame(width: geometry.size.width, height: geometry.size.height)
                        }
                    }
                    .ignoresSafeArea()
                }
                
                // Page indicator
                VStack {
                    Spacer()
                    PageIndicator(
                        currentIndex: imageLoader.currentIndex,
                        totalCount: imageLoader.images.count
                    )
                    .padding(.bottom, 16)
                }
                
                // Info overlay
                if showInfo {
                    VStack {
                        Spacer()
                        HStack {
                            InfoOverlay(info: imageLoader.currentImageInfo)
                            Spacer()
                        }
                        .padding(.bottom, 60)
                    }
                }
                
                // Jump input
                if showJumpInput {
                    VStack {
                        Spacer()
                        HStack {
                            Spacer()
                            JumpInputView(
                                text: $jumpText,
                                onSubmit: {
                                    if let index = Int(jumpText) {
                                        imageLoader.jumpTo(index: index - 1)
                                    }
                                    showJumpInput = false
                                    jumpText = ""
                                },
                                onCancel: {
                                    showJumpInput = false
                                    jumpText = ""
                                }
                            )
                            Spacer()
                        }
                        .padding(.bottom, 60)
                    }
                }
            } else {
                // Empty state
                VStack(spacing: 16) {
                    Image(systemName: "photo.on.rectangle.angled")
                        .font(.system(size: 64))
                        .foregroundColor(.secondary)
                    
                    Text("拖拽图片到此处")
                        .font(.title2)
                        .foregroundColor(.secondary)
                    
                    Text("或双击图片文件打开")
                        .font(.body)
                        .foregroundColor(.secondary.opacity(0.7))
                }
            }
        }
        .frame(minWidth: 800, minHeight: 600)
        .onAppear {
            setupKeyboardMonitoring()
        }
        .onReceive(NotificationCenter.default.publisher(for: .openImage)) { notification in
            if let url = notification.object as? URL {
                imageLoader.loadImage(url)
                resetView()
            }
        }
        .onDrop(of: [.fileURL], isTargeted: nil) { providers in
            handleDrop(providers: providers)
        }
    }
    
    private func setupKeyboardMonitoring() {
        NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            handleKeyPress(event: event)
        }
    }
    
    private func handleKeyPress(event: NSEvent) -> NSEvent? {
        // Number keys for jump
        if let chars = event.characters, let number = Int(chars), number >= 0 && number <= 9 {
            if !showJumpInput {
                showJumpInput = true
                jumpText = chars
                return nil
            }
        }
        
        switch event.keyCode {
        case 123: // Left arrow
            withAnimation(.easeInOut(duration: 0.3)) {
                imageLoader.previousImage()
                resetView()
            }
            return nil
        case 124: // Right arrow
            withAnimation(.easeInOut(duration: 0.3)) {
                imageLoader.nextImage()
                resetView()
            }
            return nil
        case 49: // Space
            withAnimation(.easeInOut(duration: 0.3)) {
                imageLoader.nextImage()
                resetView()
            }
            return nil
        case 34: // I
            showInfo.toggle()
            return nil
        case 3: // F
            toggleFullscreen()
            return nil
        case 36: // Enter
            toggleFullscreen()
            return nil
        case 53: // Esc
            if isFullscreen {
                toggleFullscreen()
            }
            return nil
        case 24: // =
            zoom(by: 1.25)
            return nil
        case 27: // -
            zoom(by: 0.8)
            return nil
        case 29: // 0
            fitToWindow()
            return nil
        case 33: // [
            rotate(by: -90)
            return nil
        case 30: // ]
            rotate(by: 90)
            return nil
        case 8: // C
            if event.modifierFlags.contains(.command) {
                copyImage()
                return nil
            }
            return event
        case 51: // Delete
            // Could add delete functionality here
            return event
        default:
            return event
        }
    }
    
    private func resetView() {
        scale = 1.0
        rotation = 0
        offset = .zero
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
        NSApp.keyWindow?.toggleFullScreen(nil)
        isFullscreen.toggle()
    }
    
    private func copyImage() {
        guard let image = imageLoader.currentImage else { return }
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.writeObjects([image])
    }
    
    private func handleDrop(providers: [NSItemProvider]) -> Bool {
        guard let provider = providers.first else { return false }
        provider.loadItem(forTypeIdentifier: "public.file-url") { data, error in
            guard let data = data as? Data,
                  let url = URL(dataRepresentation: data, relativeTo: nil) else { return }
            DispatchQueue.main.async {
                imageLoader.loadImage(url)
                resetView()
            }
        }
        return true
    }
}

struct JumpInputView: View {
    @Binding var text: String
    let onSubmit: () -> Void
    let onCancel: () -> Void
    
    var body: some View {
        HStack {
            Text("跳转到:")
                .font(.system(size: 14))
            
            TextField("", text: $text)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .frame(width: 80)
                .onSubmit(onSubmit)
            
            Button("确定") { onSubmit() }
                .buttonStyle(.borderedProminent)
            
            Button("取消") { onCancel() }
                .buttonStyle(.bordered)
        }
        .padding(12)
        .background(.ultraThinMaterial)
        .cornerRadius(10)
    }
}
