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
                UpdateManager.shared.checkForUpdates(showModal: false)
            }
        }

        // Check & ensure Finder Context Menu Quick Action is available
        QuickActionManager.shared.autoInstallIfNeeded()

        // Check if a folder path was passed directly via CLI arguments
        let args = CommandLine.arguments.dropFirst()
        for arg in args {
            if !arg.hasPrefix("-") {
                let url = URL(fileURLWithPath: arg)
                var isDir: ObjCBool = false
                if FileManager.default.fileExists(atPath: url.path, isDirectory: &isDir), isDir.boolValue {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        IconStore.shared.stageFolder(url: url)
                        NSApplication.shared.activate(ignoringOtherApps: true)
                    }
                    break
                }
            }
        }
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        if !flag {
            for window in sender.windows where !(window is NSPanel) {
                window.makeKeyAndOrderFront(nil)
            }
        }
        return true
    }

    // MARK: - Native File & Folder Open Event Handlers (Finder / Open With / Quick Action)

    func application(_ sender: NSApplication, openFiles filenames: [String]) {
        for path in filenames {
            let url = URL(fileURLWithPath: path)
            var isDir: ObjCBool = false
            if FileManager.default.fileExists(atPath: url.path, isDirectory: &isDir), isDir.boolValue {
                Task { @MainActor in
                    IconStore.shared.stageFolder(url: url)
                    NSApplication.shared.activate(ignoringOtherApps: true)
                }
                break
            }
        }
        sender.reply(toOpenOrPrint: .success)
    }

    func application(_ sender: NSApplication, openFile filename: String) -> Bool {
        let url = URL(fileURLWithPath: filename)
        var isDir: ObjCBool = false
        if FileManager.default.fileExists(atPath: url.path, isDirectory: &isDir), isDir.boolValue {
            Task { @MainActor in
                IconStore.shared.stageFolder(url: url)
                NSApplication.shared.activate(ignoringOtherApps: true)
            }
            return true
        }
        return false
    }

    func application(_ application: NSApplication, open urls: [URL]) {
        for url in urls {
            handleIncomingURL(url)
        }
    }

    private func handleIncomingURL(_ url: URL) {
        if url.scheme == "folderlab" {
            if let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
               let pathItem = components.queryItems?.first(where: { $0.name == "path" })?.value {
                let folderURL = URL(fileURLWithPath: pathItem)
                var isDir: ObjCBool = false
                if FileManager.default.fileExists(atPath: folderURL.path, isDirectory: &isDir), isDir.boolValue {
                    Task { @MainActor in
                        IconStore.shared.stageFolder(url: folderURL)
                        NSApplication.shared.activate(ignoringOtherApps: true)
                    }
                }
            }
        } else if url.isFileURL {
            var isDir: ObjCBool = false
            if FileManager.default.fileExists(atPath: url.path, isDirectory: &isDir), isDir.boolValue {
                Task { @MainActor in
                    IconStore.shared.stageFolder(url: url)
                    NSApplication.shared.activate(ignoringOtherApps: true)
                }
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
                .onOpenURL { url in
                    if url.scheme == "folderlab" {
                        if let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
                           let pathItem = components.queryItems?.first(where: { $0.name == "path" })?.value {
                            let folderURL = URL(fileURLWithPath: pathItem)
                            var isDir: ObjCBool = false
                            if FileManager.default.fileExists(atPath: folderURL.path, isDirectory: &isDir), isDir.boolValue {
                                IconStore.shared.stageFolder(url: folderURL)
                                NSApplication.shared.activate(ignoringOtherApps: true)
                            }
                        }
                    } else if url.isFileURL {
                        var isDir: ObjCBool = false
                        if FileManager.default.fileExists(atPath: url.path, isDirectory: &isDir), isDir.boolValue {
                            IconStore.shared.stageFolder(url: url)
                            NSApplication.shared.activate(ignoringOtherApps: true)
                        }
                    }
                }
        }
        .windowResizability(.contentMinSize)
        .defaultSize(width: 1180, height: 800)
        .commands {
            CommandGroup(after: .appInfo) {
                Button("Check for Updates…") {
                    UpdateManager.shared.checkForUpdates(showModal: true)
                }
                Divider()
                Button("Install Finder Quick Action…") {
                    _ = QuickActionManager.shared.install()
                    IconStore.shared.notify("Installed 'Style with FolderLab…' in Finder Context Menu! 🖱️✨")
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
