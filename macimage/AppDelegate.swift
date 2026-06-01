import AppKit
import SwiftUI

final class AppDelegate: NSObject, NSApplicationDelegate {
    
    private var mainWindowController: MainWindowController!
    
    // MARK: - App Lifecycle
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        setupMenus()
        
        mainWindowController = MainWindowController()
        
        if UserDefaults.standard.bool(forKey: "launchWithLastImage") {
            if let lastDir = HistoryManager.shared.getLastDirectory(),
               let lastIndex = HistoryManager.shared.getPosition(directory: lastDir),
               lastIndex >= 0 {
                let urls = try? FileManager.default.contentsOfDirectory(
                    at: lastDir, includingPropertiesForKeys: nil, options: [.skipsHiddenFiles]
                )
                let imageFiles = urls?.filter { ImageLoader.supportedExtensions.contains($0.pathExtension.lowercased()) }
                    .sorted { $0.lastPathComponent.localizedStandardCompare($1.lastPathComponent) == .orderedAscending }
                if let target = imageFiles?[safe: lastIndex] {
                    mainWindowController.openImage(target)
                }
            }
        }
    }
    
    func application(_ application: NSApplication, open urls: [URL]) {
        guard let url = urls.first else { return }
        mainWindowController?.openImage(url)
    }
    
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return UserDefaults.standard.object(forKey: "quitOnClose") == nil
            ? true
            : UserDefaults.standard.bool(forKey: "quitOnClose")
    }
    
    // MARK: - Menus
    
    private func setupMenus() {
        let mainMenu = NSMenu()
        
        // App menu
        let appMenu = NSMenu()
        appMenu.addItem(NSMenuItem(title: "关于 macimage", action: #selector(NSApplication.orderFrontStandardAboutPanel(_:)), keyEquivalent: ""))
        appMenu.addItem(.separator())
        appMenu.addItem(NSMenuItem(title: "偏好设置...", action: #selector(showPreferences), keyEquivalent: ","))
        appMenu.addItem(.separator())
        appMenu.addItem(NSMenuItem(title: "隐藏 macimage", action: #selector(NSApplication.hide(_:)), keyEquivalent: "h"))
        appMenu.addItem(NSMenuItem(title: "隐藏其他", action: #selector(NSApplication.hideOtherApplications(_:)), keyEquivalent: "h").withModifier([.command, .option]))
        appMenu.addItem(NSMenuItem(title: "显示全部", action: #selector(NSApplication.unhideAllApplications(_:)), keyEquivalent: ""))
        appMenu.addItem(.separator())
        appMenu.addItem(NSMenuItem(title: "退出 macimage", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
        let appItem = NSMenuItem(); appItem.submenu = appMenu
        mainMenu.addItem(appItem)
        
        // File menu
        let fileMenu = NSMenu(title: "文件")
        fileMenu.addItem(NSMenuItem(title: "打开...", action: #selector(fileOpen), keyEquivalent: "o"))
        fileMenu.addItem(.separator())
        fileMenu.addItem(NSMenuItem(title: "关闭窗口", action: #selector(NSWindow.performClose(_:)), keyEquivalent: "w"))
        mainMenu.addItem(NSMenuItem(title: "文件", action: nil, keyEquivalent: "").with(submenu: fileMenu))
        
        // Edit menu
        let editMenu = NSMenu(title: "编辑")
        editMenu.addItem(NSMenuItem(title: "复制图片", action: #selector(editCopy), keyEquivalent: "c"))
        editMenu.addItem(NSMenuItem(title: "全选", action: #selector(NSResponder.selectAll(_:)), keyEquivalent: "a"))
        mainMenu.addItem(NSMenuItem(title: "编辑", action: nil, keyEquivalent: "").with(submenu: editMenu))
        
        // View menu
        let viewMenu = NSMenu(title: "显示")
        viewMenu.addItem(NSMenuItem(title: "显示/隐藏侧边栏", action: #selector(tbSidebar), keyEquivalent: "t"))
        viewMenu.addItem(NSMenuItem(title: "显示/隐藏图片信息", action: #selector(tbInfo), keyEquivalent: "i"))
        viewMenu.addItem(.separator())
        viewMenu.addItem(NSMenuItem(title: "放大", action: #selector(tbZoomIn), keyEquivalent: "="))
        viewMenu.addItem(NSMenuItem(title: "缩小", action: #selector(tbZoomOut), keyEquivalent: "-"))
        viewMenu.addItem(NSMenuItem(title: "适配窗口", action: #selector(tbFit), keyEquivalent: "0"))
        viewMenu.addItem(.separator())
        viewMenu.addItem(NSMenuItem(title: "上一张", action: #selector(tbPrev), keyEquivalent: String(Character(UnicodeScalar(NSLeftArrowFunctionKey)!))))
        viewMenu.addItem(NSMenuItem(title: "下一张", action: #selector(tbNext), keyEquivalent: String(Character(UnicodeScalar(NSRightArrowFunctionKey)!))))
        viewMenu.addItem(.separator())
        viewMenu.addItem(NSMenuItem(title: "进入全屏", action: #selector(toggleFullscreen), keyEquivalent: "f"))
        viewMenu.addItem(NSMenuItem(title: "左旋", action: #selector(tbRotL), keyEquivalent: "["))
        viewMenu.addItem(NSMenuItem(title: "右旋", action: #selector(tbRotR), keyEquivalent: "]"))
        mainMenu.addItem(NSMenuItem(title: "显示", action: nil, keyEquivalent: "").with(submenu: viewMenu))
        
        // Window menu
        let windowMenu = NSMenu(title: "窗口")
        windowMenu.addItem(NSMenuItem(title: "最小化", action: #selector(NSWindow.performMiniaturize(_:)), keyEquivalent: "m"))
        windowMenu.addItem(NSMenuItem(title: "缩放", action: #selector(NSWindow.performZoom(_:)), keyEquivalent: ""))
        windowMenu.addItem(.separator())
        windowMenu.addItem(NSMenuItem(title: "前置全部窗口", action: #selector(NSWindow.orderFrontRegardless), keyEquivalent: ""))
        mainMenu.addItem(NSMenuItem(title: "窗口", action: nil, keyEquivalent: "").with(submenu: windowMenu))
        
        NSApp.mainMenu = mainMenu
    }
    
    // MARK: - Toolbar / View Actions (delegated to MainWindowController)
    
    @objc private func tbPrev() { mainWindowController?.imageLoader.previousImage() }
    @objc private func tbNext() { mainWindowController?.imageLoader.nextImage() }
    @objc private func tbZoomIn() { mainWindowController?.imageView.zoomIn() }
    @objc private func tbZoomOut() { mainWindowController?.imageView.zoomOut() }
    @objc private func tbFit() { mainWindowController?.imageView.fitToWindow() }
    @objc private func tbRotL() { mainWindowController?.imageLoader.rotateLeft() }
    @objc private func tbRotR() { mainWindowController?.imageLoader.rotateRight() }
    @objc private func tbSidebar() { mainWindowController?.tbSidebar() }
    @objc private func tbInfo() { mainWindowController?.tbInfo() }
    @objc private func toggleFullscreen() { mainWindowController?.window?.toggleFullScreen(nil) }
    @objc private func editCopy() { mainWindowController?.editCopy() }
    
    @objc private func fileOpen() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.jpeg, .png, .gif, .bmp, .tiff, .webP]
        panel.allowsMultipleSelection = false
        panel.begin { [weak self] response in
            guard response == .OK, let url = panel.url else { return }
            self?.mainWindowController?.openImage(url)
        }
    }
    
    @objc private func showPreferences() { PreferencesWindowController.shared.show() }
}

// MARK: - Helpers

extension NSMenuItem {
    func withModifier(_ modifier: NSEvent.ModifierFlags) -> NSMenuItem {
        keyEquivalentModifierMask = modifier
        return self
    }
    func with(submenu: NSMenu) -> NSMenuItem {
        self.submenu = submenu
        return self
    }
}

extension AppDelegate: NSWindowDelegate {
    func windowWillClose(_ notification: Notification) { NSApp.terminate(nil) }
}
