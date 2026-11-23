import SwiftUI
import AppKit
import UniformTypeIdentifiers

// MARK: - Preset Manager (Shareable .folderlab Themes)

@MainActor
enum PresetManager {
    static func exportPreset(spec: IconSpec, defaultName: String = "MyFolderTheme") -> String {
        let panel = NSSavePanel()
        panel.title = "Export Folder Theme Preset"
        panel.nameFieldStringValue = "\(defaultName).folderlab"
        panel.allowedContentTypes = [
            UTType(filenameExtension: "folderlab") ?? .json,
            .json
        ]

        guard panel.runModal() == .OK, let dest = panel.url else {
            return "Export cancelled."
        }

        let preset = spec.toPreset(name: defaultName)
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]

        do {
            let data = try encoder.encode(preset)
            try data.write(to: dest)
            return "Exported theme preset '\(dest.lastPathComponent)'! 🎨"
        } catch {
            return "Failed to export preset: \(error.localizedDescription)"
        }
    }

    static func importPreset() -> (spec: IconSpec?, message: String) {
        let panel = NSOpenPanel()
        panel.title = "Import Folder Theme Preset"
        panel.prompt = "Import Theme"
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false
        panel.allowedContentTypes = [
            UTType(filenameExtension: "folderlab") ?? .json,
            .json
        ]

        guard panel.runModal() == .OK, let url = panel.url else {
            return (nil, "Import cancelled.")
        }

        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            let preset = try decoder.decode(FolderLabPreset.self, from: data)
            let spec = IconSpec.fromPreset(preset)
            return (spec, "Imported theme '\(preset.name)' successfully! ✨")
        } catch {
            return (nil, "Failed to load preset: \(error.localizedDescription)")
        }
    }
}
