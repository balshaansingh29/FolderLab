import Foundation
import AppKit
import SwiftUI

@MainActor
final class QuickActionManager: ObservableObject {
    static let shared = QuickActionManager()

    static let workflowName = "Style with FolderLab…"
    static let workflowFileName = "Style with FolderLab….workflow"

    @Published var isInstalled: Bool = false
    @Published var statusMessage: String? = nil

    private var servicesDirectory: URL {
        FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library", isDirectory: true)
            .appendingPathComponent("Services", isDirectory: true)
    }

    var workflowURL: URL {
        servicesDirectory.appendingPathComponent(Self.workflowFileName)
    }

    init() {
        checkInstalled()
    }

    func checkInstalled() {
        let plist = workflowURL.appendingPathComponent("Contents/Info.plist")
        let doc = workflowURL.appendingPathComponent("Contents/document.wflow")
        isInstalled = FileManager.default.fileExists(atPath: plist.path) && FileManager.default.fileExists(atPath: doc.path)
    }

    func autoInstallIfNeeded() {
        checkInstalled()
        if !isInstalled {
            _ = install()
        }
    }

    @discardableResult
    func install() -> (success: Bool, message: String) {
        let fm = FileManager.default

        do {
            try fm.createDirectory(at: servicesDirectory, withIntermediateDirectories: true)

            let contentsDir = workflowURL.appendingPathComponent("Contents", isDirectory: true)
            if fm.fileExists(atPath: workflowURL.path) {
                try fm.removeItem(at: workflowURL)
            }
            try fm.createDirectory(at: contentsDir, withIntermediateDirectories: true)

            // 1. Info.plist
            let infoPlistURL = contentsDir.appendingPathComponent("Info.plist")
            try infoPlistContent.write(to: infoPlistURL, atomically: true, encoding: .utf8)

            // 2. document.wflow
            let docWorkflowURL = contentsDir.appendingPathComponent("document.wflow")
            try documentWflowContent.write(to: docWorkflowURL, atomically: true, encoding: .utf8)

            // 3. Update macOS Services cache & Finder preferences
            updateServicesCache()

            isInstalled = true
            let msg = "Finder Quick Action 'Style with FolderLab…' installed successfully!"
            statusMessage = msg
            return (true, msg)
        } catch {
            let msg = "Failed to install Quick Action: \(error.localizedDescription)"
            statusMessage = msg
            return (false, msg)
        }
    }

    @discardableResult
    func uninstall() -> (success: Bool, message: String) {
        let fm = FileManager.default
        do {
            if fm.fileExists(atPath: workflowURL.path) {
                try fm.removeItem(at: workflowURL)
            }
            cleanPbsPreferences()
            updateServicesCache()
            isInstalled = false
            let msg = "Removed 'Style with FolderLab…' from Finder Services."
            statusMessage = msg
            return (true, msg)
        } catch {
            let msg = "Failed to uninstall: \(error.localizedDescription)"
            statusMessage = msg
            return (false, msg)
        }
    }

    func revealInFinder() {
        if FileManager.default.fileExists(atPath: workflowURL.path) {
            NSWorkspace.shared.selectFile(workflowURL.path, inFileViewerRootedAtPath: "")
        } else {
            NSWorkspace.shared.open(servicesDirectory)
        }
    }

    func openShortcutsSettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.keyboard?Shortcuts") {
            NSWorkspace.shared.open(url)
        }
    }

    private func updateServicesCache() {
        // 1. Enable in pbs.plist
        let pbsURL = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/Preferences/pbs.plist")
        if let data = try? Data(contentsOf: pbsURL),
           var dict = (try? PropertyListSerialization.propertyList(from: data, options: .mutableContainersAndLeaves, format: nil)) as? [String: Any] {
            var services = (dict["NSServicesStatus"] as? [String: Any]) ?? [:]
            var finderActive = (dict["FinderActive"] as? [String: Any]) ?? [:]

            let keys = [
                "(null) - Style with FolderLab… - runWorkflowAsService",
                "(null) - Style with FolderLab... - runWorkflowAsService",
                "com.balshaansingh.folderlab.quickaction - Style with FolderLab… - runWorkflowAsService",
                "com.balshaansingh.folderlab.quickaction - Style with FolderLab... - runWorkflowAsService"
            ]

            let statusDict: [String: Any] = [
                "enabled_context_menu": true,
                "enabled_services_menu": true
            ]

            for k in keys {
                services[k] = statusDict
                finderActive[k] = true
            }
            finderActive["Style with FolderLab…"] = true
            finderActive["Style with FolderLab..."] = true

            dict["NSServicesStatus"] = services
            dict["FinderActive"] = finderActive

            if let outData = try? PropertyListSerialization.data(fromPropertyList: dict, format: .binary, options: 0) {
                try? outData.write(to: pbsURL, options: .atomic)
            }
        }

        // 2. Register URL scheme and app with LaunchServices
        let lsregister = "/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister"
        if FileManager.default.fileExists(atPath: lsregister) {
            let p = Process()
            p.executableURL = URL(fileURLWithPath: lsregister)
            p.arguments = ["-f", "/Applications/FolderLab.app", Bundle.main.bundlePath]
            try? p.run()
            p.waitUntilExit()
        }

        // 3. Update macOS Services daemon cache
        let pbs = Process()
        pbs.executableURL = URL(fileURLWithPath: "/System/Library/CoreServices/pbs")
        pbs.arguments = ["-update"]
        try? pbs.run()
        pbs.waitUntilExit()

        // 4. Flush Pasteboard server cache
        let pbsFlush = Process()
        pbsFlush.executableURL = URL(fileURLWithPath: "/System/Library/CoreServices/pbs")
        pbsFlush.arguments = ["-flush"]
        try? pbsFlush.run()
        pbsFlush.waitUntilExit()

        // 5. Restart Finder so the context menu updates immediately
        let killFinder = Process()
        killFinder.executableURL = URL(fileURLWithPath: "/usr/bin/killall")
        killFinder.arguments = ["Finder"]
        try? killFinder.run()
        killFinder.waitUntilExit()
    }

    private func cleanPbsPreferences() {
        let pbsURL = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/Preferences/pbs.plist")
        guard let data = try? Data(contentsOf: pbsURL),
              var dict = (try? PropertyListSerialization.propertyList(from: data, options: .mutableContainersAndLeaves, format: nil)) as? [String: Any] else { return }

        var services = (dict["NSServicesStatus"] as? [String: Any]) ?? [:]
        var finderActive = (dict["FinderActive"] as? [String: Any]) ?? [:]

        let keys = [
            "(null) - Style with FolderLab… - runWorkflowAsService",
            "(null) - Style with FolderLab... - runWorkflowAsService",
            "com.balshaansingh.folderlab.quickaction - Style with FolderLab… - runWorkflowAsService",
            "com.balshaansingh.folderlab.quickaction - Style with FolderLab... - runWorkflowAsService",
            "Style with FolderLab…",
            "Style with FolderLab..."
        ]

        for k in keys {
            services.removeValue(forKey: k)
            finderActive.removeValue(forKey: k)
        }

        dict["NSServicesStatus"] = services
        dict["FinderActive"] = finderActive

        if let outData = try? PropertyListSerialization.data(fromPropertyList: dict, format: .binary, options: 0) {
            try? outData.write(to: pbsURL, options: .atomic)
        }
    }

    // MARK: - Workflow Template Plists

    private var infoPlistContent: String {
        """
        <?xml version="1.0" encoding="UTF-8"?>
        <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
        <plist version="1.0">
        <dict>
        \t<key>CFBundleIdentifier</key>
        \t<string>com.balshaansingh.folderlab.quickaction</string>
        \t<key>CFBundleName</key>
        \t<string>Style with FolderLab…</string>
        \t<key>CFBundleShortVersionString</key>
        \t<string>1.0</string>
        \t<key>NSServices</key>
        \t<array>
        \t\t<dict>
        \t\t\t<key>NSBackgroundColorName</key>
        \t\t\t<string>background</string>
        \t\t\t<key>NSIconName</key>
        \t\t\t<string>NSActionTemplate</string>
        \t\t\t<key>NSMenuItem</key>
        \t\t\t<dict>
        \t\t\t\t<key>default</key>
        \t\t\t\t<string>Style with FolderLab…</string>
        \t\t\t</dict>
        \t\t\t<key>NSMessage</key>
        \t\t\t<string>runWorkflowAsService</string>
        \t\t\t<key>NSRequiredContext</key>
        \t\t\t<dict>
        \t\t\t\t<key>NSApplicationIdentifier</key>
        \t\t\t\t<string>com.apple.finder</string>
        \t\t\t</dict>
        \t\t\t<key>NSSendFileTypes</key>
        \t\t\t<array>
        \t\t\t\t<string>public.folder</string>
        \t\t\t</array>
        \t\t</dict>
        \t</array>
        </dict>
        </plist>
        """
    }

    private var documentWflowContent: String {
        """
        <?xml version="1.0" encoding="UTF-8"?>
        <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
        <plist version="1.0">
        <dict>
        \t<key>AMApplicationBuild</key>
        \t<string>534</string>
        \t<key>AMApplicationVersion</key>
        \t<string>2.10</string>
        \t<key>AMDocumentVersion</key>
        \t<string>2</string>
        \t<key>actions</key>
        \t<array>
        \t\t<dict>
        \t\t\t<key>action</key>
        \t\t\t<dict>
        \t\t\t\t<key>AMAccepts</key>
        \t\t\t\t<dict>
        \t\t\t\t\t<key>Container</key>
        \t\t\t\t\t<string>List</string>
        \t\t\t\t\t<key>Optional</key>
        \t\t\t\t\t<true/>
        \t\t\t\t\t<key>Types</key>
        \t\t\t\t\t<array>
        \t\t\t\t\t\t<string>com.apple.cocoa.string</string>
        \t\t\t\t\t</array>
        \t\t\t\t</dict>
        \t\t\t\t<key>AMActionVersion</key>
        \t\t\t\t<string>2.0.3</string>
        \t\t\t\t<key>AMApplication</key>
        \t\t\t\t<array>
        \t\t\t\t\t<string>Automator</string>
        \t\t\t\t</array>
        \t\t\t\t<key>AMParameterProperties</key>
        \t\t\t\t<dict>
        \t\t\t\t\t<key>COMMAND_STRING</key>
        \t\t\t\t\t<dict/>
        \t\t\t\t\t<key>CheckedForUserDefaultShell</key>
        \t\t\t\t\t<dict/>
        \t\t\t\t\t<key>inputMethod</key>
        \t\t\t\t\t<dict/>
        \t\t\t\t\t<key>shell</key>
        \t\t\t\t\t<dict/>
        \t\t\t\t\t<key>source</key>
        \t\t\t\t\t<dict/>
        \t\t\t\t</dict>
        \t\t\t\t<key>AMProvides</key>
        \t\t\t\t<dict>
        \t\t\t\t\t<key>Container</key>
        \t\t\t\t\t<string>List</string>
        \t\t\t\t\t<key>Types</key>
        \t\t\t\t\t<array>
        \t\t\t\t\t\t<string>com.apple.cocoa.string</string>
        \t\t\t\t\t</array>
        \t\t\t\t</dict>
        \t\t\t\t<key>ActionBundlePath</key>
        \t\t\t\t<string>/System/Library/Automator/Run Shell Script.action</string>
        \t\t\t\t<key>ActionName</key>
        \t\t\t\t<string>Run Shell Script</string>
        \t\t\t\t<key>ActionParameters</key>
        \t\t\t\t<dict>
        \t\t\t\t\t<key>COMMAND_STRING</key>
        \t\t\t\t\t<string>for f in "$@"
        do
            if [ -d "$f" ]; then
                if [ -d "/Applications/FolderLab.app" ]; then
                    open -a "/Applications/FolderLab.app" "$f" 2&gt;/dev/null || open -a "FolderLab" "$f" 2&gt;/dev/null
                else
                    open -a "FolderLab" "$f" 2&gt;/dev/null
                fi
                u=$(python3 -c "import urllib.parse, sys; print(urllib.parse.quote(sys.argv[1]))" "$f" 2&gt;/dev/null)
                if [ -n "$u" ]; then
                    open "folderlab://open?path=$u" 2&gt;/dev/null
                fi
            fi
        done</string>
        \t\t\t\t\t<key>CheckedForUserDefaultShell</key>
        \t\t\t\t\t<true/>
        \t\t\t\t\t<key>inputMethod</key>
        \t\t\t\t\t<integer>1</integer>
        \t\t\t\t\t<key>shell</key>
        \t\t\t\t\t<string>/bin/zsh</string>
        \t\t\t\t\t<key>source</key>
        \t\t\t\t\t<string></string>
        \t\t\t\t</dict>
        \t\t\t\t<key>BundleIdentifier</key>
        \t\t\t\t<string>com.apple.RunShellScript</string>
        \t\t\t\t<key>CFBundleVersion</key>
        \t\t\t\t<string>2.0.3</string>
        \t\t\t\t<key>CanShowSelectedItemsWhenRun</key>
        \t\t\t\t<false/>
        \t\t\t\t<key>CanShowWhenRun</key>
        \t\t\t\t<true/>
        \t\t\t\t<key>Category</key>
        \t\t\t\t<array>
        \t\t\t\t\t<string>AMCategoryUtilities</string>
        \t\t\t\t</array>
        \t\t\t\t<key>Class Name</key>
        \t\t\t\t<string>RunShellScriptAction</string>
        \t\t\t\t<key>InputUUID</key>
        \t\t\t\t<string>D6F2B653-EA94-46D6-9B6F-D3751B56F4BE</string>
        \t\t\t\t<key>Keywords</key>
        \t\t\t\t<array>
        \t\t\t\t\t<string>Shell</string>
        \t\t\t\t\t<string>Script</string>
        \t\t\t\t\t<string>Command</string>
        \t\t\t\t\t<string>Run</string>
        \t\t\t\t\t<string>Unix</string>
        \t\t\t\t</array>
        \t\t\t\t<key>OutputUUID</key>
        \t\t\t\t<string>123E4FA9-1D43-4067-937C-4D3E23DFB12A</string>
        \t\t\t\t<key>UUID</key>
        \t\t\t\t<string>A74C6067-E14A-47F7-B7A0-7FCDD1C7DE7C</string>
        \t\t\t\t<key>UnlocalizedApplications</key>
        \t\t\t\t<array>
        \t\t\t\t\t<string>Automator</string>
        \t\t\t\t</array>
        \t\t\t\t<key>arguments</key>
        \t\t\t\t<dict>
        \t\t\t\t\t<key>0</key>
        \t\t\t\t\t<dict>
        \t\t\t\t\t\t<key>default value</key>
        \t\t\t\t\t\t<integer>0</integer>
        \t\t\t\t\t\t<key>name</key>
        \t\t\t\t\t\t<string>inputMethod</string>
        \t\t\t\t\t\t<key>required</key>
        \t\t\t\t\t\t<string>0</string>
        \t\t\t\t\t\t<key>type</key>
        \t\t\t\t\t\t<string>0</string>
        \t\t\t\t\t\t<key>uuid</key>
        \t\t\t\t\t\t<string>0</string>
        \t\t\t\t\t</dict>
        \t\t\t\t\t<key>1</key>
        \t\t\t\t\t<dict>
        \t\t\t\t\t\t<key>default value</key>
        \t\t\t\t\t\t<false/>
        \t\t\t\t\t\t<key>name</key>
        \t\t\t\t\t\t<string>CheckedForUserDefaultShell</string>
        \t\t\t\t\t\t<key>required</key>
        \t\t\t\t\t\t<string>0</string>
        \t\t\t\t\t\t<key>type</key>
        \t\t\t\t\t\t<string>0</string>
        \t\t\t\t\t\t<key>uuid</key>
        \t\t\t\t\t\t<string>1</string>
        \t\t\t\t\t</dict>
        \t\t\t\t\t<key>2</key>
        \t\t\t\t\t<dict>
        \t\t\t\t\t\t<key>default value</key>
        \t\t\t\t\t\t<string></string>
        \t\t\t\t\t\t<key>name</key>
        \t\t\t\t\t\t<string>source</string>
        \t\t\t\t\t\t<key>required</key>
        \t\t\t\t\t\t<string>0</string>
        \t\t\t\t\t\t<key>type</key>
        \t\t\t\t\t\t<string>0</string>
        \t\t\t\t\t\t<key>uuid</key>
        \t\t\t\t\t\t<string>2</string>
        \t\t\t\t\t</dict>
        \t\t\t\t\t<key>3</key>
        \t\t\t\t\t<dict>
        \t\t\t\t\t\t<key>default value</key>
        \t\t\t\t\t\t<string></string>
        \t\t\t\t\t\t<key>name</key>
        \t\t\t\t\t\t<string>COMMAND_STRING</string>
        \t\t\t\t\t\t<key>required</key>
        \t\t\t\t\t\t<string>0</string>
        \t\t\t\t\t\t<key>type</key>
        \t\t\t\t\t\t<string>0</string>
        \t\t\t\t\t\t<key>uuid</key>
        \t\t\t\t\t\t<string>3</string>
        \t\t\t\t\t</dict>
        \t\t\t\t\t<key>4</key>
        \t\t\t\t\t<dict>
        \t\t\t\t\t\t<key>default value</key>
        \t\t\t\t\t\t<string>/bin/sh</string>
        \t\t\t\t\t\t<key>name</key>
        \t\t\t\t\t\t<string>shell</string>
        \t\t\t\t\t\t<key>required</key>
        \t\t\t\t\t\t<string>0</string>
        \t\t\t\t\t\t<key>type</key>
        \t\t\t\t\t\t<string>0</string>
        \t\t\t\t\t\t<key>uuid</key>
        \t\t\t\t\t\t<string>4</string>
        \t\t\t\t\t</dict>
        \t\t\t\t</dict>
        \t\t\t\t<key>conversionLabel</key>
        \t\t\t\t<integer>0</integer>
        \t\t\t\t<key>isViewVisible</key>
        \t\t\t\t<integer>1</integer>
        \t\t\t\t<key>location</key>
        \t\t\t\t<string>309.000000:305.000000</string>
        \t\t\t\t<key>nibPath</key>
        \t\t\t\t<string>/System/Library/Automator/Run Shell Script.action/Contents/Resources/Base.lproj/main.nib</string>
        \t\t\t</dict>
        \t\t\t<key>isViewVisible</key>
        \t\t\t<integer>1</integer>
        \t\t</dict>
        \t</array>
        \t<key>connectors</key>
        \t<dict/>
        \t<key>workflowMetaData</key>
        \t<dict>
        \t\t<key>applicationBundleID</key>
        \t\t<string>com.apple.finder</string>
        \t\t<key>applicationBundleIDsByPath</key>
        \t\t<dict>
        \t\t\t<key>/System/Library/CoreServices/Finder.app</key>
        \t\t\t<string>com.apple.finder</string>
        \t\t\t<key>com.apple.finder</key>
        \t\t\t<string>/System/Library/CoreServices/Finder.app</string>
        \t\t</dict>
        \t\t<key>applicationPath</key>
        \t\t<string>/System/Library/CoreServices/Finder.app</string>
        \t\t<key>applicationPaths</key>
        \t\t<array>
        \t\t\t<string>/System/Library/CoreServices/Finder.app</string>
        \t\t</array>
        \t\t<key>inputTypeIdentifier</key>
        \t\t<string>com.apple.Automator.fileSystemObject.folder</string>
        \t\t<key>outputTypeIdentifier</key>
        \t\t<string>com.apple.Automator.nothing</string>
        \t\t<key>presentationMode</key>
        \t\t<integer>15</integer>
        \t\t<key>processesInput</key>
        \t\t<false/>
        \t\t<key>serviceApplicationBundleID</key>
        \t\t<string>com.apple.finder</string>
        \t\t<key>serviceApplicationPath</key>
        \t\t<string>/System/Library/CoreServices/Finder.app</string>
        \t\t<key>serviceInputTypeIdentifier</key>
        \t\t<string>com.apple.Automator.fileSystemObject.folder</string>
        \t\t<key>serviceOutputTypeIdentifier</key>
        \t\t<string>com.apple.Automator.nothing</string>
        \t\t<key>serviceProcessesInput</key>
        \t\t<false/>
        \t\t<key>systemImageName</key>
        \t\t<string>NSActionTemplate</string>
        \t\t<key>useAutomaticInputType</key>
        \t\t<false/>
        \t\t<key>workflowTypeIdentifier</key>
        \t\t<string>com.apple.Automator.servicesMenu</string>
        \t</dict>
        </dict>
        </plist>
        """
    }
}
