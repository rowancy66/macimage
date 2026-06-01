import SwiftUI

/// Simple preferences window for macimage.
struct PreferencesView: View {
    @AppStorage("launchWithLastImage") private var launchWithLastImage = false
    @AppStorage("showSidebarByDefault") private var showSidebarByDefault = true
    @AppStorage("quitOnClose") private var quitOnClose = true
    
    private let accent = Color(red: 1.0, green: 0.42, blue: 0.42)
    
    var body: some View {
        TabView {
            GeneralTab(launchWithLastImage: $launchWithLastImage,
                       showSidebarByDefault: $showSidebarByDefault,
                       quitOnClose: $quitOnClose)
                .tabItem { Label("通用", systemImage: "gearshape") }
            
            AboutTab()
                .tabItem { Label("关于", systemImage: "info.circle") }
        }
        .frame(width: 420, height: 280)
    }
}

struct GeneralTab: View {
    @Binding var launchWithLastImage: Bool
    @Binding var showSidebarByDefault: Bool
    @Binding var quitOnClose: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("通用设置")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.secondary)
            
            Toggle(isOn: $launchWithLastImage) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("启动时恢复上次浏览位置")
                        .font(.system(size: 13))
                    Text("打开 app 时自动回到上次浏览的文件夹和图片")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }
            }
            
            Divider().opacity(0.5)
            
            Toggle(isOn: $showSidebarByDefault) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("默认显示缩略图侧边栏")
                        .font(.system(size: 13))
                    Text("打开文件夹时自动展示缩略图列表")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }
            }
            
            Divider().opacity(0.5)
            
            Toggle(isOn: $quitOnClose) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("关闭窗口时退出 app")
                        .font(.system(size: 13))
                    Text("关闭最后一个窗口时自动退出 macimage")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
        }
        .padding(20)
    }
}

struct AboutTab: View {
    var body: some View {
        VStack(spacing: 12) {
            Spacer()
            
            if let icon = NSImage(named: NSImage.applicationIconName) {
                Image(nsImage: icon)
                    .resizable()
                    .frame(width: 64, height: 64)
                    .shadow(color: .black.opacity(0.1), radius: 8, y: 4)
            }
            
            Text("macimage")
                .font(.system(size: 18, weight: .semibold))
            
            Text("版本 1.0.0")
                .font(.system(size: 12))
                .foregroundColor(.secondary)
            
            Text("轻量级 macOS 图片查看器")
                .font(.system(size: 12))
                .foregroundColor(.secondary)
            
            Spacer()
        }
        .padding(20)
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Window Controller

final class PreferencesWindowController: NSWindowController {
    static let shared = PreferencesWindowController()
    
    private init() {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 420, height: 280),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.title = "偏好设置"
        window.contentView = NSHostingView(rootView: PreferencesView())
        window.center()
        super.init(window: window)
    }
    
    required init?(coder: NSCoder) { fatalError("init(coder:) not implemented") }
    
    func show() {
        window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}
