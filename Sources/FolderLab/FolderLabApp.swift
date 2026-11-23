import SwiftUI
import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationWillFinishLaunching(_ notification: Notification) {
        NSApplication.shared.setActivationPolicy(.regular)
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApplication.shared.setActivationPolicy(.regular)
        NSApplication.shared.activate(ignoringOtherApps: true)
        AppIconManager.shared.forceApplyCurrentIcon()
    }
}

@main
struct FolderLabApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        WindowGroup("FolderLab") {
            ContentView()
                .onAppear {
                    NSApplication.shared.setActivationPolicy(.regular)
                    NSApplication.shared.activate(ignoringOtherApps: true)
                    AppIconManager.shared.forceApplyCurrentIcon()
                }
        }
        .windowResizability(.contentMinSize)
        .defaultSize(width: 1180, height: 800)

        #if os(macOS)
        Settings {
            SettingsView()
        }
        #endif
    }
}
