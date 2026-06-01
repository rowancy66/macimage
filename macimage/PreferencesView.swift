import SwiftUI

/// Polished preferences window with refined toggles and about page.
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
    
    private let accent = Color(red: 1.0, green: 0.42, blue: 0.42)
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Section header
            HStack(spacing: 6) {
                RoundedRectangle(cornerRadius: 1.5)
                    .fill(accent)
                    .frame(width: 3, height: 14)
                Text("通用设置")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.primary.opacity(0.85))
            }
            .padding(.bottom, 16)
            
            // Settings
            VStack(alignment: .leading, spacing: 0) {
                SettingRow(
                    icon: "clock.arrow.circlepath",
                    title: "启动时恢复上次浏览位置",
                    subtitle: "打开 app 时自动回到上次浏览的文件夹和图片",
                    isOn: $launchWithLastImage
                )
                
                SettingDivider()
                
                SettingRow(
                    icon: "sidebar.left",
                    title: "默认显示缩略图侧边栏",
                    subtitle: "打开文件夹时自动展示缩略图列表",
                    isOn: $showSidebarByDefault
                )
                
                SettingDivider()
                
                SettingRow(
                    icon: "power",
                    title: "关闭窗口时退出 app",
                    subtitle: "关闭最后一个窗口时自动退出 macimage",
                    isOn: $quitOnClose
                )
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.primary.opacity(0.03))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .strokeBorder(Color.primary.opacity(0.06), lineWidth: 0.5)
            )
            
            Spacer()
        }
        .padding(20)
    }
}

/// Individual setting row with icon, title, subtitle, and toggle.
struct SettingRow: View {
    let icon: String
    let title: String
    let subtitle: String
    @Binding var isOn: Bool
    private let accent = Color(red: 1.0, green: 0.42, blue: 0.42)
    
    var body: some View {
        HStack(spacing: 12) {
            // Icon
            Image(systemName: icon)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(accent.opacity(0.8))
                .frame(width: 24, height: 24)
                .background(
                    RoundedRectangle(cornerRadius: 5)
                        .fill(accent.opacity(0.08))
                )
            
            // Text
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 12.5, weight: .medium))
                    .foregroundColor(.primary)
                Text(subtitle)
                    .font(.system(size: 10.5))
                    .foregroundColor(.secondary.opacity(0.7))
            }
            
            Spacer()
            
            // Toggle with accent color
            Toggle("", isOn: $isOn)
                .toggleStyle(.switch)
                .controlSize(.small)
        }
        .padding(.vertical, 10)
    }
}

/// Subtle divider between setting rows.
struct SettingDivider: View {
    var body: some View {
        Rectangle()
            .fill(Color.primary.opacity(0.06))
            .frame(height: 0.5)
            .padding(.leading, 36)
    }
}

struct AboutTab: View {
    private let accent = Color(red: 1.0, green: 0.42, blue: 0.42)
    
    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            
            if let icon = NSImage(named: NSImage.applicationIconName) {
                Image(nsImage: icon)
                    .resizable()
                    .frame(width: 72, height: 72)
                    .shadow(color: .black.opacity(0.12), radius: 12, y: 4)
                    .shadow(color: accent.opacity(0.08), radius: 6, y: 2)
            }
            
            Spacer().frame(height: 14)
            
            Text("macimage")
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundColor(.primary)
            
            Spacer().frame(height: 4)
            
            Text("版本 1.0.0")
                .font(.system(size: 11, weight: .medium, design: .monospaced))
                .foregroundColor(.secondary)
            
            Spacer().frame(height: 6)
            
            Text("轻量级 macOS 图片查看器")
                .font(.system(size: 12))
                .foregroundColor(.secondary.opacity(0.7))
            
            Spacer().frame(height: 16)
            
            // Accent line
            RoundedRectangle(cornerRadius: 1)
                .fill(
                    LinearGradient(
                        colors: [accent.opacity(0.6), accent.opacity(0.1)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(width: 80, height: 2)
            
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