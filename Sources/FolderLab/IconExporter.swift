import SwiftUI
import AppKit
import UniformTypeIdentifiers

@MainActor
enum IconExporter {

    // MARK: Rendering

    static func cgImage(_ spec: IconSpec, pixels: Int) -> CGImage? {
        let renderer = ImageRenderer(content: IconCanvas(spec: spec, size: CGFloat(pixels)))
        renderer.scale = 1          // exact pixel dimensions
        return renderer.cgImage
    }

    static func pngData(_ spec: IconSpec, pixels: Int) -> Data? {
        guard let cg = cgImage(spec, pixels: pixels) else { return nil }
        let rep = NSBitmapImageRep(cgImage: cg)
        rep.size = NSSize(width: pixels, height: pixels)
        return rep.representation(using: .png, properties: [:])
    }

    static func nsImage(_ spec: IconSpec, pixels: Int = 1024) -> NSImage? {
        guard let cg = cgImage(spec, pixels: pixels) else { return nil }
        let rep = NSBitmapImageRep(cgImage: cg)
        rep.size = NSSize(width: 512, height: 512)
        let image = NSImage(size: NSSize(width: 512, height: 512))
        image.addRepresentation(rep)
        return image
    }

    // MARK: Copy to Clipboard

    static func copyToClipboard(_ spec: IconSpec) -> String {
        guard let image = nsImage(spec, pixels: 1024) else {
            return "Failed to render icon for clipboard."
        }
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        if pasteboard.writeObjects([image]) {
            return "Copied 1024×1024 icon to clipboard! (Paste in Finder Get Info: Cmd+I → click icon → Cmd+V)"
        } else {
            return "Failed to copy icon to clipboard."
        }
    }

    // MARK: Save PNG

    static func savePNG(_ spec: IconSpec) -> String {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.png]
        panel.nameFieldStringValue = "Icon.png"
        guard panel.runModal() == .OK, let url = panel.url else { return "PNG export cancelled." }
        guard let data = pngData(spec, pixels: 1024) else { return "Could not render icon." }
        do {
            try data.write(to: url)
            return "Saved \(url.lastPathComponent) (1024×1024)."
        } catch {
            return "Save failed: \(error.localizedDescription)"
        }
    }

    // MARK: Save .icns

    static func saveICNS(_ spec: IconSpec) -> String {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.icns]
        panel.nameFieldStringValue = "Icon.icns"
        guard panel.runModal() == .OK, let dest = panel.url else { return "ICNS export cancelled." }

        let fm = FileManager.default
        let tmp = fm.temporaryDirectory.appendingPathComponent("FolderLab-\(UUID().uuidString)")
        let set = tmp.appendingPathComponent("Icon.iconset")
        defer { try? fm.removeItem(at: tmp) }

        do {
            try fm.createDirectory(at: set, withIntermediateDirectories: true)
            let sizes: [(String, Int)] = [
                ("icon_16x16", 16), ("icon_16x16@2x", 32),
                ("icon_32x32", 32), ("icon_32x32@2x", 64),
                ("icon_128x128", 128), ("icon_128x128@2x", 256),
                ("icon_256x256", 256), ("icon_256x256@2x", 512),
                ("icon_512x512", 512), ("icon_512x512@2x", 1024)
            ]
            for (name, px) in sizes {
                guard let data = pngData(spec, pixels: px) else { return "Could not render \(px)px image." }
                try data.write(to: set.appendingPathComponent("\(name).png"))
            }
            if fm.fileExists(atPath: dest.path) { try fm.removeItem(at: dest) }

            let p = Process()
            p.executableURL = URL(fileURLWithPath: "/usr/bin/iconutil")
            p.arguments = ["-c", "icns", set.path, "-o", dest.path]
            try p.run()
            p.waitUntilExit()
            return p.terminationStatus == 0
                ? "Saved \(dest.lastPathComponent)."
                : "iconutil failed (status \(p.terminationStatus))."
        } catch {
            return "Export failed: \(error.localizedDescription)"
        }
    }

    // MARK: - Folder Metadata & Design Persistence (xattr)

    public static let xattrSpecKey = "com.folderlab.spec"

    public static func saveStoredSpec(_ spec: IconSpec, for url: URL) -> Bool {
        let preset = spec.toPreset(name: url.lastPathComponent)
        guard let data = try? JSONEncoder().encode(preset) else { return false }
        return data.withUnsafeBytes { buffer in
            guard let base = buffer.baseAddress else { return false }
            return setxattr(url.path, xattrSpecKey, base, buffer.count, 0, 0) == 0
        }
    }

    public static func readStoredSpec(for url: URL) -> IconSpec? {
        let length = getxattr(url.path, xattrSpecKey, nil, 0, 0, 0)
        guard length > 0 else { return nil }
        var data = Data(count: length)
        let readLen = data.withUnsafeMutableBytes { buffer in
            guard let base = buffer.baseAddress else { return -1 }
            return getxattr(url.path, xattrSpecKey, base, length, 0, 0)
        }
        guard readLen > 0,
              let preset = try? JSONDecoder().decode(FolderLabPreset.self, from: data) else {
            return nil
        }
        return IconSpec.fromPreset(preset)
    }

    public static func removeStoredSpec(for url: URL) {
        removexattr(url.path, xattrSpecKey, 0)
    }

    // MARK: - Finder Desktop & Window Invalidation

    public static func refreshFinder(for url: URL) {
        try? FileManager.default.setAttributes([.modificationDate: Date()], ofItemAtPath: url.path)
        NSWorkspace.shared.noteFileSystemChanged(url.path)

        let parent = url.deletingLastPathComponent().path
        if !parent.isEmpty {
            try? FileManager.default.setAttributes([.modificationDate: Date()], ofItemAtPath: parent)
            NSWorkspace.shared.noteFileSystemChanged(parent)
        }
    }

    // MARK: Apply to files / folders

    static func apply(spec: IconSpec, to url: URL) -> (success: Bool, message: String) {
        guard let image = nsImage(spec, pixels: 1024) else {
            return (false, "Could not render folder icon.")
        }
        let success = NSWorkspace.shared.setIcon(image, forFile: url.path, options: [])
        if success {
            _ = saveStoredSpec(spec, for: url)
            if spec.syncFinderTag, let tag = spec.selectedFinderTag {
                _ = setFinderTag(tag.rawValue, for: url)
            }
            refreshFinder(for: url)
            return (true, "Customized folder '\(url.lastPathComponent)'! ✨")
        } else {
            return (false, "Failed to customize '\(url.lastPathComponent)'. Check permissions.")
        }
    }

    static func applyToItems(_ spec: IconSpec) -> String {
        let panel = NSOpenPanel()
        panel.message = "Choose one or more folders to apply this custom icon"
        panel.prompt = "Customize Folder"
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = true
        guard panel.runModal() == .OK, !panel.urls.isEmpty else { return "Cancelled." }

        var ok = 0, failed = 0
        for url in panel.urls {
            let (success, _) = apply(spec: spec, to: url)
            if success {
                ok += 1
            } else {
                failed += 1
            }
        }
        return failed == 0
            ? "Customized \(ok) folder(s)! ✨"
            : "Applied to \(ok), failed for \(failed) (check folder permissions)."
    }

    static func resetItems() -> String {
        let panel = NSOpenPanel()
        panel.message = "Choose folders to restore Apple default icon"
        panel.prompt = "Restore Default"
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = true
        guard panel.runModal() == .OK, !panel.urls.isEmpty else { return "Cancelled." }

        var ok = 0, failed = 0
        for url in panel.urls {
            if NSWorkspace.shared.setIcon(nil, forFile: url.path, options: []) {
                removeStoredSpec(for: url)
                refreshFinder(for: url)
                ok += 1
            } else {
                failed += 1
            }
        }
        return failed == 0
            ? "Restored \(ok) folder(s) to default macOS icon."
            : "Reset \(ok), failed for \(failed)."
    }

    // MARK: - Batch Subfolders Styler (Feature 2)

    static func applyToSubfolders(_ spec: IconSpec) -> String {
        let panel = NSOpenPanel()
        panel.message = "Choose a parent directory to skin all its subfolders"
        panel.prompt = "Skin Subfolders"
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        guard panel.runModal() == .OK, let parentDir = panel.url else { return "Cancelled." }

        let fm = FileManager.default
        guard let contents = try? fm.contentsOfDirectory(at: parentDir, includingPropertiesForKeys: [.isDirectoryKey], options: [.skipsHiddenFiles]) else {
            return "Could not read contents of directory."
        }

        let subfolders = contents.filter { url in
            (try? url.resourceValues(forKeys: [.isDirectoryKey]))?.isDirectory == true
        }

        guard !subfolders.isEmpty else {
            return "No subfolders found in '\(parentDir.lastPathComponent)'."
        }

        var ok = 0, failed = 0
        for folder in subfolders {
            let (success, _) = apply(spec: spec, to: folder)
            if success {
                ok += 1
            } else {
                failed += 1
            }
        }

        return failed == 0
            ? "Customized all \(ok) subfolders in '\(parentDir.lastPathComponent)'! 🚀"
            : "Applied to \(ok) subfolders, failed for \(failed)."
    }

    static func resetSubfolders() -> String {
        let panel = NSOpenPanel()
        panel.message = "Choose parent directory to restore Apple default icons for all subfolders"
        panel.prompt = "Reset Subfolders"
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        guard panel.runModal() == .OK, let parentDir = panel.url else { return "Cancelled." }

        let fm = FileManager.default
        guard let contents = try? fm.contentsOfDirectory(at: parentDir, includingPropertiesForKeys: [.isDirectoryKey], options: [.skipsHiddenFiles]) else {
            return "Could not read contents of directory."
        }

        let subfolders = contents.filter { url in
            (try? url.resourceValues(forKeys: [.isDirectoryKey]))?.isDirectory == true
        }

        guard !subfolders.isEmpty else {
            return "No subfolders found in '\(parentDir.lastPathComponent)'."
        }

        var ok = 0, failed = 0
        for folder in subfolders {
            if NSWorkspace.shared.setIcon(nil, forFile: folder.path, options: []) {
                removeStoredSpec(for: folder)
                refreshFinder(for: folder)
                ok += 1
            } else {
                failed += 1
            }
        }

        return failed == 0
            ? "Restored all \(ok) subfolders in '\(parentDir.lastPathComponent)' to default icon."
            : "Reset \(ok), failed for \(failed)."
    }

    // MARK: - Native macOS Finder Tag Helpers (Feature 5)

    static func getFinderTags(for url: URL) -> [String] {
        guard let values = try? url.resourceValues(forKeys: [.tagNamesKey]),
              let tags = values.tagNames else {
            return []
        }
        return tags
    }

    static func setFinderTag(_ tagName: String?, for url: URL) -> Bool {
        let nsURL = url as NSURL
        var tags: [String] = []
        if let tagName = tagName, !tagName.isEmpty {
            tags = [tagName]
        }
        do {
            try nsURL.setResourceValue(tags, forKey: .tagNamesKey)
            NSWorkspace.shared.noteFileSystemChanged(url.path)
            return true
        } catch {
            return false
        }
    }

    // MARK: Xcode .appiconset Pack (Pro Feature)

    static func saveAppIconSet(_ spec: IconSpec) -> String {
        let panel = NSOpenPanel()
        panel.message = "Choose folder where AppIcon.appiconset will be saved"
        panel.prompt = "Save AppIcon.appiconset"
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.canCreateDirectories = true
        panel.allowsMultipleSelection = false
        guard panel.runModal() == .OK, let dir = panel.url else { return "Cancelled." }

        let iconsetURL = dir.appendingPathComponent("AppIcon.appiconset")
        let fm = FileManager.default

        do {
            if fm.fileExists(atPath: iconsetURL.path) {
                try fm.removeItem(at: iconsetURL)
            }
            try fm.createDirectory(at: iconsetURL, withIntermediateDirectories: true)

            let sizes: [(String, Int)] = [
                ("icon_16x16.png", 16),
                ("icon_16x16@2x.png", 32),
                ("icon_32x32.png", 32),
                ("icon_32x32@2x.png", 64),
                ("icon_128x128.png", 128),
                ("icon_128x128@2x.png", 256),
                ("icon_256x256.png", 256),
                ("icon_256x256@2x.png", 512),
                ("icon_512x512.png", 512),
                ("icon_512x512@2x.png", 1024),
                ("icon_1024x1024.png", 1024)
            ]

            for (name, px) in sizes {
                guard let data = pngData(spec, pixels: px) else { continue }
                try data.write(to: iconsetURL.appendingPathComponent(name))
            }

            let contentsJSON = """
            {
              "images" : [
                { "size" : "16x16", "idiom" : "mac", "filename" : "icon_16x16.png", "scale" : "1x" },
                { "size" : "16x16", "idiom" : "mac", "filename" : "icon_16x16@2x.png", "scale" : "2x" },
                { "size" : "32x32", "idiom" : "mac", "filename" : "icon_32x32.png", "scale" : "1x" },
                { "size" : "32x32", "idiom" : "mac", "filename" : "icon_32x32@2x.png", "scale" : "2x" },
                { "size" : "128x128", "idiom" : "mac", "filename" : "icon_128x128.png", "scale" : "1x" },
                { "size" : "128x128", "idiom" : "mac", "filename" : "icon_128x128@2x.png", "scale" : "2x" },
                { "size" : "256x256", "idiom" : "mac", "filename" : "icon_256x256.png", "scale" : "1x" },
                { "size" : "256x256", "idiom" : "mac", "filename" : "icon_256x256@2x.png", "scale" : "2x" },
                { "size" : "512x512", "idiom" : "mac", "filename" : "icon_512x512.png", "scale" : "1x" },
                { "size" : "512x512", "idiom" : "mac", "filename" : "icon_512x512@2x.png", "scale" : "2x" },
                { "size" : "1024x1024", "idiom" : "mac", "filename" : "icon_1024x1024.png", "scale" : "1x" }
              ],
              "info" : {
                "author" : "xcode",
                "version" : 1
              }
            }
            """
            try contentsJSON.data(using: .utf8)?.write(to: iconsetURL.appendingPathComponent("Contents.json"))
            return "Exported Xcode AppIcon.appiconset (ready for Assets.xcassets)!"
        } catch {
            return "Export failed: \(error.localizedDescription)"
        }
    }

    // MARK: Modern Xcode Icon Composer (.icon Package)

    static func saveIconComposerDocument(_ spec: IconSpec) -> String {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [UTType(filenameExtension: "icon") ?? .package]
        panel.nameFieldStringValue = "AppIcon.icon"
        guard panel.runModal() == .OK, let dest = panel.url else { return "Icon Composer export cancelled." }

        let fm = FileManager.default
        do {
            if fm.fileExists(atPath: dest.path) {
                try fm.removeItem(at: dest)
            }
            try fm.createDirectory(at: dest, withIntermediateDirectories: true)

            // Convert spec primary color to extended sRGB values
            let nsCol = NSColor(spec.color1).usingColorSpace(.extendedSRGB) ?? NSColor(srgbRed: 0.145, green: 0.388, blue: 0.922, alpha: 1.0)
            let r = String(format: "%.3f", nsCol.redComponent)
            let g = String(format: "%.3f", nsCol.greenComponent)
            let b = String(format: "%.3f", nsCol.blueComponent)
            let a = String(format: "%.3f", nsCol.alphaComponent)

            let iconJSON = """
            {
              "fill" : {
                "automatic-gradient" : "extended-srgb:\(r),\(g),\(b),\(a)"
              },
              "groups" : [

              ],
              "supported-platforms" : {
                "squares" : [
                  "macOS",
                  "iOS"
                ]
              }
            }
            """
            try iconJSON.write(to: dest.appendingPathComponent("icon.json"), atomically: true, encoding: .utf8)
            return "Exported \(dest.lastPathComponent) (Icon Composer Document)!"
        } catch {
            return "Export failed: \(error.localizedDescription)"
        }
    }
}
