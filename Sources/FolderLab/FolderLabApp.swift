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

        // Background update check if enabled (defaults to true)
        let autoCheck = UserDefaults.standard.object(forKey: "autoCheckForUpdates") as? Bool ?? true
        if autoCheck {
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                UpdateManager.shared.checkForUpdates(userInitiated: false)
            }
        }
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
        .commands {
            CommandGroup(after: .appInfo) {
                Button("Check for Updates…") {
                    UpdateManager.shared.checkForUpdates(userInitiated: true)
                }
                Divider()
            }
        }

        #if os(macOS)
        Settings {
            SettingsView()
        }
        #endif
    }
}
