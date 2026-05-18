import SwiftUI

@main
struct macimageApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .commands {
            CommandGroup(replacing: .newItem) { }
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    func application(_ application: NSApplication, open urls: [URL]) {
        guard let url = urls.first else { return }
        NotificationCenter.default.post(name: .openImage, object: url)
    }
}

extension Notification.Name {
    static let openImage = Notification.Name("openImage")
}
