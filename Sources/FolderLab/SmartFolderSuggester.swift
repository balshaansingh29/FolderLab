import Foundation
import SwiftUI

// MARK: - Smart Folder Suggestion Model

public struct FolderSuggestion: Identifiable, Equatable {
    public var id: String { title }
    public let title: String
    public let reason: String
    public let symbolName: String
    public let color1: Color
    public let color2: Color
    public let color3: Color?
    public let texture: SurfaceTexture
    public let badge: CornerBadge
    public let peekContentType: PeekContentType?

    public static func == (lhs: FolderSuggestion, rhs: FolderSuggestion) -> Bool {
        lhs.title == rhs.title && lhs.symbolName == rhs.symbolName
    }
}

// MARK: - Smart Folder Suggester

public enum SmartFolderSuggester {
    public static func suggest(for folderURL: URL) -> FolderSuggestion? {
        let name = folderURL.lastPathComponent.lowercased()
        return suggest(forFolderName: name)
    }

    public static func suggest(forFolderName name: String) -> FolderSuggestion? {
        let n = name.lowercased()

        if n.contains("code") || n.contains("dev") || n.contains("git") || n.contains("repo") || n.contains("swift") || n.contains("project") || n.contains("script") || n.contains("src") || n.contains("app") {
            return FolderSuggestion(
                title: "Developer Project",
                reason: "Detected development / code repository",
                symbolName: "terminal.fill",
                color1: Color(hex: "#2D3748") ?? .black,
                color2: Color(hex: "#1A202C") ?? .black,
                color3: Color(hex: "#4A5568"),
                texture: .carbon,
                badge: .none,
                peekContentType: .code
            )
        } else if n.contains("download") || n.contains("inbox") || n.contains("incoming") {
            return FolderSuggestion(
                title: "Downloads & Inbox",
                reason: "Detected incoming files directory",
                symbolName: "arrow.down.circle.fill",
                color1: Color(hex: "#0284C7") ?? .blue,
                color2: Color(hex: "#0369A1") ?? .blue,
                color3: nil,
                texture: .none,
                badge: .none,
                peekContentType: .documents
            )
        } else if n.contains("doc") || n.contains("note") || n.contains("pdf") || n.contains("paper") || n.contains("book") || n.contains("read") {
            return FolderSuggestion(
                title: "Documents & Notes",
                reason: "Detected reading / writing documents",
                symbolName: "doc.text.fill",
                color1: Color(hex: "#D97706") ?? .orange,
                color2: Color(hex: "#B45309") ?? .orange,
                color3: nil,
                texture: .leather,
                badge: .none,
                peekContentType: .documents
            )
        } else if n.contains("photo") || n.contains("pic") || n.contains("img") || n.contains("camera") || n.contains("screenshot") || n.contains("wallpaper") {
            return FolderSuggestion(
                title: "Photos & Wallpapers",
                reason: "Detected visual image gallery",
                symbolName: "camera.fill",
                color1: Color(hex: "#059669") ?? .green,
                color2: Color(hex: "#047857") ?? .green,
                color3: nil,
                texture: .none,
                badge: .star,
                peekContentType: .photos
            )
        } else if n.contains("music") || n.contains("audio") || n.contains("sound") || n.contains("podcast") || n.contains("beat") || n.contains("track") {
            return FolderSuggestion(
                title: "Audio & Music",
                reason: "Detected acoustic / music assets",
                symbolName: "waveform.path",
                color1: Color(hex: "#9333EA") ?? .purple,
                color2: Color(hex: "#7E22CE") ?? .purple,
                color3: nil,
                texture: .grid,
                badge: .none,
                peekContentType: .music
            )
        } else if n.contains("video") || n.contains("film") || n.contains("movie") || n.contains("youtube") || n.contains("clip") || n.contains("stream") {
            return FolderSuggestion(
                title: "Cinema & Video",
                reason: "Detected multimedia video assets",
                symbolName: "film.fill",
                color1: Color(hex: "#E11D48") ?? .red,
                color2: Color(hex: "#BE123C") ?? .red,
                color3: nil,
                texture: .none,
                badge: .none,
                peekContentType: .photos
            )
        } else if n.contains("money") || n.contains("tax") || n.contains("finance") || n.contains("budget") || n.contains("bank") || n.contains("crypto") || n.contains("receipt") {
            return FolderSuggestion(
                title: "Vault & Finance",
                reason: "Detected financial documents",
                symbolName: "lock.shield.fill",
                color1: Color(hex: "#10B981") ?? .green,
                color2: Color(hex: "#047857") ?? .green,
                color3: Color(hex: "#F59E0B"),
                texture: .brushed,
                badge: .lock,
                peekContentType: .documents
            )
        } else if n.contains("archive") || n.contains("backup") || n.contains("old") || n.contains("storage") || n.contains("zip") {
            return FolderSuggestion(
                title: "Archive Vault",
                reason: "Detected cold storage / backup folder",
                symbolName: "archivebox.fill",
                color1: Color(hex: "#4B5563") ?? .gray,
                color2: Color(hex: "#374151") ?? .gray,
                color3: nil,
                texture: .stripes,
                badge: .none,
                peekContentType: .documents
            )
        } else if n.contains("work") || n.contains("office") || n.contains("client") || n.contains("corp") || n.contains("business") {
            return FolderSuggestion(
                title: "Executive & Client",
                reason: "Detected professional workplace folder",
                symbolName: "briefcase.fill",
                color1: Color(hex: "#1D4ED8") ?? .blue,
                color2: Color(hex: "#1E40AF") ?? .blue,
                color3: nil,
                texture: .leather,
                badge: .none,
                peekContentType: .documents
            )
        } else if n.contains("art") || n.contains("design") || n.contains("figma") || n.contains("ui") || n.contains("asset") || n.contains("icon") {
            return FolderSuggestion(
                title: "Creative Studio",
                reason: "Detected design & illustration workspace",
                symbolName: "paintpalette.fill",
                color1: Color(hex: "#EC4899") ?? .pink,
                color2: Color(hex: "#8B5CF6") ?? .purple,
                color3: Color(hex: "#3B82F6"),
                texture: .none,
                badge: .star,
                peekContentType: .photos
            )
        }

        return nil
    }
}
