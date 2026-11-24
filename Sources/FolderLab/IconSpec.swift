import SwiftUI

// MARK: - Core Model

struct IconSpec: Equatable {
    // Canvas & Geometry
    var size: CGFloat = 512
    var macMargin = false
    var base: IconBase = .folder
    var shape: IconShape = .squircle
    var cornerRadius = 0.2237

    // Folder Color Fill
    var color1 = Color(hex: "#6CD0FF") ?? .blue  // Classic macOS folder blue
    var color2 = Color(hex: "#2F9DF4") ?? .blue
    var useGradient = true
    var gradientAngle = 90.0        // degrees, 90 = top to bottom
    var gloss = true
    var innerRim = true             // highlight rim on folder flap
    var liquidGlass = false         // translucent glass folder skin
    var glassOpacity = 0.45
    var specularRimWidth = 0.007

    // 3-Stop Gradients (v0.2)
    var useThreeColorGradient = false
    var color3 = Color(hex: "#1E40AF") ?? .blue

    // Surface Textures & Patterns (v0.2)
    var texture: SurfaceTexture = .none
    var textureOpacity = 0.22

    // Text & Monogram Stamping (v0.2)
    var textFontFamily: TextFontFamily = .rounded
    var textDepthStyle: TextDepthStyle = .flat
    var glyphEngravedFolderTint: Bool = true // in engraved mode, tints glyph with authentic translucent folder deboss

    // SF Symbol Badging (v0.2)
    var cornerBadge: CornerBadge = .none
    var cornerBadgeColor = Color.white

    // Folder Glyph / Stamp
    var glyphKind: GlyphKind = .symbol
    var symbolName = "folder.fill"
    var text = "A"
    var symbolMode: SymbolMode = .monochrome
    var glyphColor = Color.white.opacity(0.95)
    var glyphGradient = false
    var glyphColor2 = Color(hex: "#A78BFA") ?? .purple
    var glyphOpacity = 0.90
    var glyphScale = 0.36           // standard folder stamp scale
    var glyphYOffset = 0.06          // centered on front flap
    var glyphRotation = 0.0
    var glyphShadow = true

    // Border
    var borderOn = false
    var borderColor = Color.white.opacity(0.8)
    var borderWidth = 0.012         // fraction of side

    // Custom Image Flap Stamping (Feature 4)
    var customImageData: Data? = nil
    var customImageTinted = false
    var customImageName: String? = nil

    // macOS Tag Sync (Feature 5)
    var syncFinderTag = false
    var selectedFinderTag: FinderTagColor? = nil

    // Folder Nameplate / Label Banner (v0.4)
    var nameplateEnabled: Bool = false
    var nameplateText: String = "PROJECTS"
    var nameplateStyle: NameplateStyle = .retroTape
    var nameplateColor: Color = Color(hex: "#1E222A") ?? .black
    var nameplateTextColor: Color = .white
    var nameplateYOffset: Double = 0.22      // vertical position on folder flap (0.0 = center, positive = lower, negative = higher)
    var nameplateScale: Double = 0.72        // width fraction of flap
    var nameplateMoveIconAbove: Bool = true  // moves logo/icon into upper flap area when nameplate is active

    // Outer drop shadow (only with macMargin)
    var dropShadow = true
}

// MARK: - Enums

enum IconBase: String, CaseIterable, Identifiable {
    case tile = "App Icon Tile"
    case folder = "macOS Folder"
    case none = "Glyph Only"
    var id: String { rawValue }
}

enum IconShape: String, CaseIterable, Identifiable {
    case squircle = "macOS Squircle"
    case circle = "Circle"
    case rounded = "Rounded Rectangle"
    case square = "Square"
    var id: String { rawValue }
}

enum GlyphKind: String, CaseIterable, Identifiable, Codable {
    case symbol = "SF Symbol"
    case text = "Monogram / Emoji"
    case customImage = "Custom Image"
    var id: String { rawValue }
}

enum FinderTagColor: String, CaseIterable, Identifiable, Codable {
    case red = "Red"
    case orange = "Orange"
    case yellow = "Yellow"
    case green = "Green"
    case blue = "Blue"
    case purple = "Purple"
    case gray = "Gray"

    var id: String { rawValue }

    var colors: (String, String) {
        switch self {
        case .red: return ("#FF6058", "#E02020")
        case .orange: return ("#FF9F0A", "#D97706")
        case .yellow: return ("#FFD60A", "#D99B00")
        case .green: return ("#30D158", "#059669")
        case .blue: return ("#0A84FF", "#0066CC")
        case .purple: return ("#BF5AF2", "#9333EA")
        case .gray: return ("#8E8E93", "#636366")
        }
    }

    var primaryColor: Color { Color(hex: colors.0) ?? .blue }
    var secondaryColor: Color { Color(hex: colors.1) ?? .blue }
}

public enum TextFontFamily: String, CaseIterable, Identifiable, Codable {
    case rounded = "SF Rounded"
    case monospaced = "SF Mono"
    case serif = "New York Serif"
    case standard = "SF Pro"
    public var id: String { rawValue }
}

public enum TextDepthStyle: String, CaseIterable, Identifiable, Codable {
    case flat = "Flat Clean"
    case engraved = "macOS Engraved"
    case embossed = "Embossed 3D"
    case insetShadow = "Deep Inset"

    public var id: String { rawValue }

    public init?(rawValue: String) {
        switch rawValue {
        case "Flat Clean": self = .flat
        case "macOS Engraved", "Engraved Inset", "Engraved", "macOS Folder Engraved": self = .engraved
        case "Embossed 3D": self = .embossed
        case "Deep Inset": self = .insetShadow
        default: return nil
        }
    }
}

public enum CornerBadge: String, CaseIterable, Identifiable, Codable {
    case none = "None"
    case lock = "Lock"
    case star = "Star"
    case checkmark = "Checkmark"
    case warning = "Warning"
    case cloud = "Cloud"
    case heart = "Heart"
    case tag = "Tag"
    case bookmark = "Bookmark"
    case pin = "Pin"

    public var id: String { rawValue }

    public var symbolName: String? {
        switch self {
        case .none: return nil
        case .lock: return "lock.fill"
        case .star: return "star.fill"
        case .checkmark: return "checkmark.seal.fill"
        case .warning: return "exclamationmark.triangle.fill"
        case .cloud: return "icloud.fill"
        case .heart: return "heart.fill"
        case .tag: return "tag.fill"
        case .bookmark: return "bookmark.fill"
        case .pin: return "pin.fill"
        }
    }
}

public enum SurfaceTexture: String, CaseIterable, Identifiable, Codable {
    case none = "Smooth / Pure"
    case carbon = "Carbon Fiber"
    case brushed = "Brushed Metal"
    case leather = "Tactile Grain"
    case grid = "Dot Matrix Grid"
    case stripes = "Diagonal Ribs"
    public var id: String { rawValue }
}

public enum NameplateStyle: String, CaseIterable, Identifiable, Codable {
    case textOnly = "Text Only"
    case retroTape = "Retro Embossed Tape"
    case folderEngraved = "Folder Engraved Deboss"
    case glassCapsule = "Modern Glass Capsule"
    case brassPlate = "Engraved Brass Plaque"
    case cyberRibbon = "Cyber Neon Banner"
    case maskingTape = "Paper Masking Tape"
    case cleanTag = "Minimal Clean Badge"

    public var id: String { rawValue }

    public var iconName: String {
        switch self {
        case .textOnly: return "textformat"
        case .retroTape: return "rectangle.fill"
        case .folderEngraved: return "applelogo"
        case .glassCapsule: return "capsule.fill"
        case .brassPlate: return "shield.lefthalf.filled"
        case .cyberRibbon: return "bolt.horizontal.fill"
        case .maskingTape: return "line.diagonal"
        case .cleanTag: return "tag.fill"
        }
    }
}

// MARK: - Shareable Theme Preset (.folderlab)

struct FolderLabPreset: Codable {
    var version: Int = 2
    var name: String
    var color1Hex: String
    var color2Hex: String
    var useGradient: Bool
    var gradientAngle: Double
    var gloss: Bool
    var innerRim: Bool
    var liquidGlass: Bool
    var glassOpacity: Double
    var specularRimWidth: Double
    var glyphKind: String
    var symbolName: String
    var text: String
    var symbolMode: String
    var glyphColorHex: String
    var glyphGradient: Bool
    var glyphColor2Hex: String
    var glyphOpacity: Double
    var glyphScale: Double
    var glyphYOffset: Double
    var glyphRotation: Double
    var glyphShadow: Bool
    var customImageData: Data?
    var customImageTinted: Bool
    var customImageName: String?
    var borderOn: Bool
    var borderColorHex: String
    var borderWidth: Double
    var dropShadow: Bool
    // v0.2 Extensions
    var useThreeColorGradient: Bool? = false
    var color3Hex: String? = "#1E40AF"
    var texture: String? = "Smooth / Pure"
    var textureOpacity: Double? = 0.22
    var textFontFamily: String? = "SF Rounded"
    var textDepthStyle: String? = "Flat Clean"
    var cornerBadge: String? = "None"
    var cornerBadgeColorHex: String? = "#FFFFFF"
    // v0.4 Nameplate Extensions
    var nameplateEnabled: Bool? = false
    var nameplateText: String? = "PROJECTS"
    var nameplateStyle: String? = "Retro Embossed Tape"
    var nameplateColorHex: String? = "#1E222A"
    var nameplateTextColorHex: String? = "#FFFFFF"
    var nameplateYOffset: Double? = 0.22
    var nameplateScale: Double? = 0.72
    var nameplateMoveIconAbove: Bool? = true
    var glyphEngravedFolderTint: Bool? = true
}

enum SymbolMode: String, CaseIterable, Identifiable {
    case monochrome = "Monochrome"
    case hierarchical = "Hierarchical"
    case multicolor = "Multicolor"
    case palette = "Palette"
    var id: String { rawValue }
}

enum IconStyle: String, CaseIterable, Identifiable {
    case bigSur = "Big Sur Light"
    case gradient = "Vibrant Gradient"
    case dark = "Dark Mode Titanium"
    case liquidGlass = "Liquid Glass"
    case tintedMode = "Tinted Mode"
    case cyber = "Neon Cyber"
    case sunset = "Warm Sunset"
    case emerald = "Fresh Emerald"
    case gold = "Prestige Gold"
    case ruby = "Crimson Ruby"
    case folder = "macOS Folder"
    case glyphOnly = "Glyph Silhouette"
    var id: String { rawValue }
}

// MARK: - Style presets

extension IconSpec {
    /// Returns a preset look while keeping the current symbol / text.
    static func styled(_ style: IconStyle, keepingGlyphFrom old: IconSpec) -> IconSpec {
        func c(_ hex: String) -> Color { Color(hex: hex) ?? .gray }

        var s = IconSpec()
        s.glyphKind = old.glyphKind
        s.symbolName = old.symbolName
        s.text = old.text
        s.glyphScale = old.glyphScale
        s.glyphYOffset = old.glyphYOffset
        s.customImageData = old.customImageData
        s.customImageTinted = old.customImageTinted
        s.customImageName = old.customImageName
        s.nameplateEnabled = old.nameplateEnabled
        s.nameplateText = old.nameplateText
        s.nameplateStyle = old.nameplateStyle
        s.nameplateColor = old.nameplateColor
        s.nameplateTextColor = old.nameplateTextColor
        s.nameplateYOffset = old.nameplateYOffset
        s.nameplateScale = old.nameplateScale

        switch style {
        case .bigSur:       // light tile, colored glyph, like Apple's own apps
            s.base = .folder
            s.shape = .squircle
            s.useGradient = true
            s.color1 = c("#FFFFFF")
            s.color2 = c("#DDE2EC")
            s.gradientAngle = 90
            s.gloss = true
            s.innerRim = true
            s.glyphColor = c("#0A84FF")
            s.glyphGradient = false
            s.glyphShadow = false
        case .gradient:
            s.base = .folder
            s.shape = .squircle
            s.useGradient = true
            s.color1 = c("#36D1DC")
            s.color2 = c("#5B86E5")
            s.gradientAngle = 135
            s.gloss = true
            s.innerRim = true
            s.glyphColor = .white
            s.glyphShadow = true
        case .dark:
            s.base = .folder
            s.shape = .squircle
            s.useGradient = true
            s.color1 = c("#3A3D45")
            s.color2 = c("#141518")
            s.gradientAngle = 90
            s.gloss = true
            s.innerRim = true
            s.glyphColor = .white
            s.glyphShadow = true
        case .liquidGlass:
            s.base = .folder
            s.shape = .squircle
            s.liquidGlass = true
            s.glassOpacity = 0.40
            s.specularRimWidth = 0.007
            s.useGradient = true
            s.color1 = Color(white: 0.16, opacity: 0.45)
            s.color2 = Color(white: 0.05, opacity: 0.65)
            s.gradientAngle = 90
            s.gloss = true
            s.innerRim = true
            s.glyphColor = .white
            s.glyphShadow = true
        case .tintedMode:
            s.base = .folder
            s.shape = .squircle
            s.useGradient = true
            s.color1 = c("#1B1D26")
            s.color2 = c("#0B0C10")
            s.gradientAngle = 90
            s.gloss = true
            s.innerRim = true
            s.borderOn = true
            s.borderColor = Color(hex: "#8B5CF6")?.opacity(0.65) ?? .purple
            s.borderWidth = 0.006
            s.glyphGradient = true
            s.glyphColor = c("#00F0FF")
            s.glyphColor2 = c("#A78BFA")
            s.glyphShadow = true
        case .cyber:
            s.base = .folder
            s.shape = .squircle
            s.useGradient = true
            s.color1 = c("#FF007F")
            s.color2 = c("#7928CA")
            s.gradientAngle = 135
            s.gloss = true
            s.innerRim = true
            s.glyphColor = c("#00F0FF")
            s.glyphShadow = true
        case .sunset:
            s.base = .folder
            s.shape = .squircle
            s.useGradient = true
            s.color1 = c("#FF7E5F")
            s.color2 = c("#FEB47B")
            s.gradientAngle = 90
            s.gloss = true
            s.innerRim = true
            s.glyphColor = .white
            s.glyphShadow = true
        case .emerald:
            s.base = .folder
            s.shape = .squircle
            s.useGradient = true
            s.color1 = c("#11998E")
            s.color2 = c("#38EF7D")
            s.gradientAngle = 135
            s.gloss = true
            s.innerRim = true
            s.glyphColor = .white
            s.glyphShadow = true
        case .gold:
            s.base = .folder
            s.shape = .squircle
            s.useGradient = true
            s.color1 = c("#FFE000")
            s.color2 = c("#799F0C")
            s.gradientAngle = 120
            s.gloss = true
            s.innerRim = true
            s.glyphColor = .white
            s.glyphShadow = true
        case .ruby:
            s.base = .folder
            s.shape = .squircle
            s.useGradient = true
            s.color1 = c("#ED213A")
            s.color2 = c("#93291E")
            s.gradientAngle = 90
            s.gloss = true
            s.innerRim = true
            s.glyphColor = .white
            s.glyphShadow = true
        case .folder:       // like a default macOS folder
            s.base = .folder
            s.useGradient = true
            s.color1 = c("#6CD0FF")
            s.color2 = c("#2F9DF4")
            s.gradientAngle = 90
            s.gloss = false
            s.innerRim = false
            s.glyphColor = .white
            s.glyphOpacity = 0.90
            s.glyphShadow = false
        case .glyphOnly:    // transparent background, just the symbol
            s.base = .folder
            s.glyphScale = 0.85
            s.glyphGradient = true
            s.glyphColor = c("#FF9F0A")
            s.glyphColor2 = c("#FF375F")
            s.glyphShadow = true
        }
        return s
    }

    /// Generates an inspiring procedurally randomized icon with intelligent archetype styling, harmonious palettes, and optional nameplate text banners.
    static func random(includeTextBar: Bool) -> (spec: IconSpec, summary: String) {
        func c(_ hex: String) -> Color { Color(hex: hex) ?? .blue }

        // Over 32 curated tri-color aesthetic design palettes
        let palettes: [(name: String, c1: String, c2: String, c3: String, glyph1: String, glyph2: String)] = [
            ("Apple Finder", "#6CD0FF", "#2F9DF4", "#0A84FF", "#FFFFFF", "#E0F2FE"),
            ("Hyper Sapphire", "#2563EB", "#1D4ED8", "#1E3A8A", "#FFFFFF", "#93C5FD"),
            ("Nordic Glacier", "#30CFD0", "#330867", "#1CB5E0", "#FFFFFF", "#CFFAFE"),
            ("Cyber Synthwave", "#FF007F", "#7928CA", "#00F0FF", "#00F0FF", "#FFFFFF"),
            ("Sunset Horizon", "#FF8A5B", "#EA3B7A", "#6A11CB", "#FFFFFF", "#FFE4E6"),
            ("Solar Amber", "#F7971E", "#FFD200", "#FF512F", "#FFFFFF", "#FEF3C7"),
            ("Mint Emerald", "#11998E", "#38EF7D", "#059669", "#FFFFFF", "#D1FAE5"),
            ("Obsidian Titanium", "#3A3D45", "#141518", "#0B0C10", "#FFFFFF", "#94A3B8"),
            ("Deep Nebula", "#8E54E9", "#4776E6", "#141E30", "#FFFFFF", "#DDD6FE"),
            ("Cotton Candy", "#FC5C7D", "#6A82FB", "#A78BFA", "#FFFFFF", "#FBCFE8"),
            ("Crimson Ruby", "#ED213A", "#93291E", "#4B1212", "#FFFFFF", "#FECDD3"),
            ("Vaporwave Dusk", "#FF7E5F", "#FEB47B", "#7F00FF", "#FFFFFF", "#FED7AA"),
            ("Hacker Matrix", "#0D1117", "#161B22", "#00FF66", "#00FF66", "#FFFFFF"),
            ("Prestige Gold", "#F5AF19", "#E65C00", "#FFE000", "#FFFFFF", "#FEF08A"),
            ("Royal Amethyst", "#654EA3", "#EAAFC8", "#3B185F", "#FFFFFF", "#F3E8FF"),
            ("Forest Moss", "#134E5E", "#71B280", "#0B3C49", "#FFFFFF", "#D1FAE5"),
            ("Midnight Oceanic", "#0F2027", "#203A43", "#2C5364", "#FFFFFF", "#93C5FD"),
            ("Titanium Slate", "#485563", "#29323C", "#1E293B", "#FFFFFF", "#E2E8F0"),
            ("Electric Violet", "#7F00FF", "#E100FF", "#3B0764", "#FFFFFF", "#F5D0FE"),
            ("Peach Cream", "#ED4264", "#FFEDBC", "#F43F5E", "#FFFFFF", "#FFE4E6"),
            ("Matcha Cream", "#10B981", "#059669", "#064E3B", "#FFFFFF", "#A7F3D0"),
            ("Champagne Silk", "#FCD34D", "#F59E0B", "#D97706", "#FFFFFF", "#FEF3C7"),
            ("Tokyo Neon", "#F43F5E", "#8B5CF6", "#06B6D4", "#FFFFFF", "#CFFAFE"),
            ("Stealth Slate", "#18191C", "#23272A", "#7289DA", "#7289DA", "#FFFFFF"),
            ("Emerald Glass", "#34D399", "#059669", "#065F46", "#FFFFFF", "#D1FAE5"),
            ("Rose Quartz", "#FB7185", "#F43F5E", "#BE123C", "#FFFFFF", "#FFE4E6"),
            ("Midnight Stealth", "#1E293B", "#0F172A", "#020617", "#FFFFFF", "#94A3B8"),
            ("Solar Flare", "#F97316", "#EA580C", "#9A3412", "#FFFFFF", "#FED7AA"),
            ("Glacier Chill", "#38BDF8", "#0284C7", "#0C4A6E", "#FFFFFF", "#E0F2FE"),
            ("Toxic Lime", "#43E97B", "#38F9D7", "#10B981", "#FFFFFF", "#A7F3D0"),
            ("Bronze Copper", "#8A2387", "#E94057", "#F27121", "#FFFFFF", "#FED7AA"),
            ("Minimal Chalk", "#2C3E50", "#3498DB", "#1A252F", "#FFFFFF", "#BAE6FD")
        ]

        let devSymbols = [
            "terminal.fill", "cpu.fill", "gearshape.2.fill", "macbook", "chevron.left.forwardslash.chevron.right",
            "server.rack", "swift", "waveform.path.ecg", "network", "externaldrive.fill", "folder.badge.gearshape.fill",
            "lock.shield.fill", "key.fill", "archivebox.fill"
        ]

        let designSymbols = [
            "paintpalette.fill", "wand.and.stars", "sparkles", "cube.transparent.fill", "camera.fill",
            "pencil.and.outline", "circle.hexagongrid.fill", "slider.horizontal.3", "diamond.fill", "eye.fill"
        ]

        let mediaSymbols = [
            "music.note", "headphones", "film.fill", "mic.fill", "speaker.wave.3.fill", "play.circle.fill"
        ]

        let natureSymbols = [
            "flame.fill", "bolt.fill", "drop.fill", "leaf.fill", "sun.max.fill", "moon.stars.fill",
            "globe.americas.fill", "rocket.fill", "airplane", "paperplane.fill", "star.fill", "crown.fill"
        ]

        let textMonograms = [
            "A", "B", "C", "D", "E", "F", "G", "H", "J", "K", "L", "M", "N", "P", "Q", "R", "S", "T", "V", "W", "X", "Y", "Z",
            "🚀", "⚡️", "💎", "🔥", "🪐", "💡", "🎨", "👾", "🦊", "🎧", "☕️", "✨", "🛡️", "🔮", "🍀", "🍎", "🧬", "🕹️"
        ]

        let devWords = ["DEV", "CODE", "SYSTEM", "TERMINAL", "BACKEND", "ENGINE", "API", "CLOUD"]
        let designWords = ["STUDIO", "DESIGN", "ASSETS", "CAMERA", "CREATIVE", "PORTFOLIO", "PHOTOS"]
        let securityWords = ["VAULT", "CONFIDENTIAL", "ARCHIVE", "TOP SECRET", "SECURE", "OFFICIAL", "RECORDS"]
        let generalWords = ["PROJECTS", "LAB", "2026", "NOTES", "MUSIC", "MEDIA", "WORKSPACE", "CLIENT"]

        var s = IconSpec()
        s.base = .folder
        s.shape = .squircle
        s.dropShadow = true
        s.gloss = true
        s.innerRim = true

        enum Archetype {
            case nativeEngraved
            case liquidGlass
            case cyberNeon
            case industrialStudio
            case executiveLuxury
            case modernMesh
        }

        let archetypes: [Archetype] = [
            .nativeEngraved, .nativeEngraved,
            .liquidGlass,
            .cyberNeon,
            .industrialStudio,
            .executiveLuxury,
            .modernMesh, .modernMesh
        ]
        let chosenArchetype = archetypes.randomElement() ?? .nativeEngraved

        var summaryText = ""

        switch chosenArchetype {
        case .nativeEngraved:
            let nativePalettes = palettes.filter {
                $0.name == "Apple Finder" || $0.name == "Titanium Slate" || $0.name == "Obsidian Titanium" || $0.name == "Forest Moss" || $0.name == "Crimson Ruby"
            }
            let pal = nativePalettes.randomElement() ?? palettes[0]
            s.color1 = c(pal.c1)
            s.color2 = c(pal.c2)
            s.color3 = c(pal.c3)
            s.useThreeColorGradient = false
            s.gradientAngle = 90.0
            s.textDepthStyle = .engraved
            s.glyphEngravedFolderTint = true
            s.glyphKind = .symbol
            s.symbolName = (devSymbols + designSymbols).randomElement() ?? "folder.badge.gearshape.fill"
            s.texture = [.none, .none, .leather, .brushed].randomElement() ?? .none
            s.textureOpacity = 0.20

            if includeTextBar {
                s.nameplateEnabled = true
                s.nameplateStyle = [.folderEngraved, .textOnly, .retroTape].randomElement() ?? .folderEngraved
                s.nameplateText = (securityWords + devWords).randomElement() ?? "PROJECTS"
                s.nameplateMoveIconAbove = true
                s.glyphScale = Double.random(in: 0.36...0.42)
                s.nameplateScale = Double.random(in: 0.66...0.76)
                s.nameplateYOffset = Double.random(in: 0.21...0.25)
                if s.nameplateStyle == .folderEngraved {
                    s.nameplateColor = Color.black.opacity(0.14)
                    s.nameplateTextColor = Color.black.opacity(0.55)
                } else if s.nameplateStyle == .textOnly {
                    s.nameplateTextColor = .white
                } else {
                    s.nameplateColor = Color(hex: "#1A1A1A") ?? .black
                    s.nameplateTextColor = .white
                }
            } else {
                s.nameplateEnabled = false
                s.glyphScale = Double.random(in: 0.44...0.52)
            }
            summaryText = "Generated '\(pal.name)' with Native macOS Debossing! 📁✨"

        case .liquidGlass:
            let glassPalettes = palettes.filter {
                $0.name == "Hyper Sapphire" || $0.name == "Nordic Glacier" || $0.name == "Deep Nebula" || $0.name == "Cotton Candy" || $0.name == "Emerald Glass"
            }
            let pal = glassPalettes.randomElement() ?? palettes[1]
            s.color1 = c(pal.c1)
            s.color2 = c(pal.c2)
            s.color3 = c(pal.c3)
            s.liquidGlass = true
            s.glassOpacity = Double.random(in: 0.40...0.55)
            s.specularRimWidth = 0.008
            s.useThreeColorGradient = true
            s.gradientAngle = [45.0, 90.0, 135.0].randomElement() ?? 135.0
            s.glyphKind = .symbol
            s.symbolName = (designSymbols + natureSymbols).randomElement() ?? "sparkles"
            s.glyphColor = .white
            s.glyphShadow = true

            if includeTextBar {
                s.nameplateEnabled = true
                s.nameplateStyle = [.glassCapsule, .cleanTag, .textOnly].randomElement() ?? .glassCapsule
                s.nameplateText = (designWords + generalWords).randomElement() ?? "STUDIO"
                s.nameplateMoveIconAbove = true
                s.glyphScale = Double.random(in: 0.36...0.42)
                s.nameplateScale = Double.random(in: 0.65...0.75)
                s.nameplateYOffset = Double.random(in: 0.20...0.24)
                s.nameplateColor = s.color1.darker(0.25)
                s.nameplateTextColor = .white
            } else {
                s.nameplateEnabled = false
                s.glyphScale = Double.random(in: 0.45...0.54)
            }
            summaryText = "Generated '\(pal.name)' with Liquid Glass & Specular Sheen! 💎🧊"

        case .cyberNeon:
            let cyberPalettes = palettes.filter {
                $0.name == "Cyber Synthwave" || $0.name == "Hacker Matrix" || $0.name == "Tokyo Neon" || $0.name == "Electric Violet"
            }
            let pal = cyberPalettes.randomElement() ?? palettes[3]
            s.color1 = c(pal.c1)
            s.color2 = c(pal.c2)
            s.color3 = c(pal.c3)
            s.useThreeColorGradient = true
            s.gradientAngle = [90.0, 135.0, 225.0].randomElement() ?? 135.0
            s.texture = [.carbon, .grid].randomElement() ?? .carbon
            s.textureOpacity = Double.random(in: 0.22...0.35)
            s.glyphKind = .symbol
            s.symbolName = (devSymbols + ["bolt.fill", "flame.fill"]).randomElement() ?? "bolt.fill"
            s.glyphGradient = true
            s.glyphColor = c(pal.glyph1)
            s.glyphColor2 = c(pal.glyph2)
            s.glyphShadow = true

            if includeTextBar {
                s.nameplateEnabled = true
                s.nameplateStyle = [.cyberRibbon, .retroTape, .cleanTag].randomElement() ?? .cyberRibbon
                s.nameplateText = (devWords + ["CYBER", "MATRIX", "CORE"]).randomElement() ?? "CYBER"
                s.nameplateMoveIconAbove = true
                s.glyphScale = Double.random(in: 0.36...0.42)
                s.nameplateScale = Double.random(in: 0.68...0.78)
                s.nameplateYOffset = Double.random(in: 0.21...0.25)
                s.nameplateColor = c(pal.glyph1)
                s.nameplateTextColor = c(pal.glyph1)
            } else {
                s.nameplateEnabled = false
                s.glyphScale = Double.random(in: 0.44...0.52)
            }
            summaryText = "Generated '\(pal.name)' with Cyber Neon Ribbon! ⚡🔮"

        case .industrialStudio:
            let studioPalettes = palettes.filter {
                $0.name == "Titanium Slate" || $0.name == "Midnight Stealth" || $0.name == "Minimal Chalk" || $0.name == "Nordic Glacier"
            }
            let pal = studioPalettes.randomElement() ?? palettes[17]
            s.color1 = c(pal.c1)
            s.color2 = c(pal.c2)
            s.color3 = c(pal.c3)
            s.useThreeColorGradient = false
            s.gradientAngle = 90.0
            s.texture = [.brushed, .carbon, .grid].randomElement() ?? .brushed
            s.textureOpacity = Double.random(in: 0.25...0.40)
            s.textDepthStyle = [.embossed, .engraved, .flat].randomElement() ?? .embossed
            s.glyphKind = .symbol
            s.symbolName = (devSymbols + ["cube.transparent.fill", "wrench.and.screwdriver"]).randomElement() ?? "gearshape.2.fill"
            s.glyphColor = .white
            s.glyphShadow = true

            if includeTextBar {
                s.nameplateEnabled = true
                s.nameplateStyle = [.retroTape, .brassPlate, .cleanTag].randomElement() ?? .retroTape
                s.nameplateText = (devWords + generalWords).randomElement() ?? "HARDWARE"
                s.nameplateMoveIconAbove = true
                s.glyphScale = Double.random(in: 0.36...0.42)
                s.nameplateScale = Double.random(in: 0.66...0.76)
                s.nameplateYOffset = Double.random(in: 0.21...0.25)
                if s.nameplateStyle == .brassPlate {
                    s.nameplateColor = Color(hex: "#E5A93C") ?? .orange
                    s.nameplateTextColor = Color(hex: "#3D2400") ?? .black
                } else {
                    s.nameplateColor = Color(hex: "#1A1A1A") ?? .black
                    s.nameplateTextColor = .white
                }
            } else {
                s.nameplateEnabled = false
                s.glyphScale = Double.random(in: 0.44...0.52)
            }
            summaryText = "Generated '\(pal.name)' with Industrial Surface Texture! 🏷️🪨"

        case .executiveLuxury:
            let luxPalettes = palettes.filter {
                $0.name == "Prestige Gold" || $0.name == "Crimson Ruby" || $0.name == "Champagne Silk" || $0.name == "Royal Amethyst"
            }
            let pal = luxPalettes.randomElement() ?? palettes[13]
            s.color1 = c(pal.c1)
            s.color2 = c(pal.c2)
            s.color3 = c(pal.c3)
            s.useThreeColorGradient = true
            s.gradientAngle = [90.0, 120.0, 135.0].randomElement() ?? 120.0
            s.texture = [.leather, .stripes, .none].randomElement() ?? .none
            s.textureOpacity = 0.22
            s.textDepthStyle = [.embossed, .engraved].randomElement() ?? .embossed
            s.glyphKind = .symbol
            s.symbolName = ["crown.fill", "star.fill", "trophy.fill", "rosette", "diamond.fill", "shield.checkerboard"].randomElement() ?? "crown.fill"
            s.glyphColor = .white
            s.glyphShadow = true

            if includeTextBar {
                s.nameplateEnabled = true
                s.nameplateStyle = [.brassPlate, .retroTape, .cleanTag, .textOnly].randomElement() ?? .brassPlate
                s.nameplateText = (securityWords + ["OFFICIAL", "PRESTIGE", "VIP"]).randomElement() ?? "OFFICIAL"
                s.nameplateMoveIconAbove = true
                s.glyphScale = Double.random(in: 0.36...0.42)
                s.nameplateScale = Double.random(in: 0.65...0.76)
                s.nameplateYOffset = Double.random(in: 0.21...0.25)
                if s.nameplateStyle == .brassPlate {
                    s.nameplateColor = Color(hex: "#E5A93C") ?? .orange
                    s.nameplateTextColor = Color(hex: "#3D2400") ?? .black
                } else {
                    s.nameplateColor = Color(hex: "#1A1A1A") ?? .black
                    s.nameplateTextColor = .white
                }
            } else {
                s.nameplateEnabled = false
                s.glyphScale = Double.random(in: 0.44...0.52)
            }
            summaryText = "Generated '\(pal.name)' with Executive Brass Plaque! 👑🏆"

        case .modernMesh:
            let pal = palettes.randomElement() ?? palettes[0]
            s.color1 = c(pal.c1)
            s.color2 = c(pal.c2)
            s.color3 = c(pal.c3)
            s.useThreeColorGradient = Double.random(in: 0...1) < 0.65
            s.gradientAngle = [45.0, 90.0, 135.0, 180.0, 225.0].randomElement() ?? 135.0
            s.texture = [.none, .none, .grid, .carbon].randomElement() ?? .none
            s.textureOpacity = 0.20

            if Double.random(in: 0...1) < 0.18 {
                s.glyphKind = .text
                s.text = textMonograms.randomElement() ?? "A"
                s.textFontFamily = TextFontFamily.allCases.randomElement() ?? .rounded
                s.textDepthStyle = TextDepthStyle.allCases.randomElement() ?? .embossed
            } else {
                s.glyphKind = .symbol
                s.symbolName = (designSymbols + mediaSymbols + natureSymbols).randomElement() ?? "sparkles"
                if Double.random(in: 0...1) < 0.35 {
                    s.glyphGradient = true
                    s.glyphColor = c(pal.glyph1)
                    s.glyphColor2 = c(pal.glyph2)
                } else {
                    s.glyphGradient = false
                    s.glyphColor = c(pal.glyph1)
                }
            }
            s.glyphShadow = true

            if includeTextBar {
                s.nameplateEnabled = true
                s.nameplateStyle = NameplateStyle.allCases.randomElement() ?? .cleanTag
                s.nameplateText = (designWords + generalWords).randomElement() ?? "CREATIVE"
                s.nameplateMoveIconAbove = true
                s.glyphScale = Double.random(in: 0.36...0.42)
                s.nameplateScale = Double.random(in: 0.65...0.78)
                s.nameplateYOffset = Double.random(in: 0.20...0.25)
                switch s.nameplateStyle {
                case .textOnly:
                    s.nameplateTextColor = .white
                case .retroTape:
                    s.nameplateColor = Color(hex: "#1A1A1A") ?? .black
                    s.nameplateTextColor = .white
                case .folderEngraved:
                    s.nameplateColor = Color.black.opacity(0.14)
                    s.nameplateTextColor = Color.black.opacity(0.55)
                case .glassCapsule:
                    s.nameplateColor = s.color1.darker(0.25)
                    s.nameplateTextColor = .white
                case .brassPlate:
                    s.nameplateColor = Color(hex: "#E5A93C") ?? .orange
                    s.nameplateTextColor = Color(hex: "#3D2400") ?? .black
                case .cyberRibbon:
                    s.nameplateColor = c(pal.glyph1)
                    s.nameplateTextColor = c(pal.glyph1)
                case .maskingTape:
                    s.nameplateColor = Color(hex: "#F8F4E8") ?? .white
                    s.nameplateTextColor = Color(hex: "#262626") ?? .black
                case .cleanTag:
                    s.nameplateColor = s.color1
                    s.nameplateTextColor = .white
                }
            } else {
                s.nameplateEnabled = false
                s.glyphScale = Double.random(in: 0.44...0.52)
            }
            summaryText = "Generated '\(pal.name)' with Harmonious Palette! 🎨✨"
        }

        if Double.random(in: 0...1) < 0.18 {
            let badges: [CornerBadge] = [.lock, .star, .checkmark, .warning, .cloud, .heart, .tag, .bookmark, .pin]
            s.cornerBadge = badges.randomElement() ?? .star
            let badgeColors: [Color] = [.white, c("#FFD700"), c("#00F0FF"), c("#FF3B30"), c("#30D158")]
            s.cornerBadgeColor = badgeColors.randomElement() ?? .white
        } else {
            s.cornerBadge = .none
        }

        return (s, summaryText)
    }

    /// Overload for backwards compatibility
    static func random() -> IconSpec {
        random(includeTextBar: false).spec
    }


    // MARK: - Official FolderLab App Icon Styles (Apple HIG & Icon Composer)

    /// Standard / Light appearance macOS App Icon (Paintbrush Glass Folder)
    static var appIconLight: IconSpec {
        var s = IconSpec()
        s.base = .folder
        s.shape = .squircle
        s.macMargin = true
        s.useGradient = true
        s.color1 = Color(hex: "#7C3AED") ?? .purple // Royal Violet / Purple
        s.color2 = Color(hex: "#3B82F6") ?? .blue   // Electric Blue
        s.gradientAngle = 135
        s.gloss = true
        s.innerRim = true
        s.dropShadow = true
        s.glyphKind = .symbol
        s.symbolName = "paintbrush.fill"
        s.glyphRotation = -20.0
        s.glyphColor = .white
        s.glyphScale = 0.48
        s.glyphShadow = true
        return s
    }

    /// Dark mode appearance macOS App Icon
    static var appIconDark: IconSpec {
        var s = IconSpec()
        s.base = .folder
        s.shape = .squircle
        s.macMargin = true
        s.useGradient = true
        s.color1 = Color(hex: "#1E222A") ?? .black // Obsidian Titanium
        s.color2 = Color(hex: "#0F1115") ?? .black // Deep Space Black
        s.gradientAngle = 90
        s.gloss = true
        s.innerRim = true
        s.dropShadow = true
        s.glyphKind = .symbol
        s.symbolName = "paintbrush.fill"
        s.glyphRotation = -20.0
        s.glyphColor = Color(hex: "#A78BFA") ?? .purple
        s.glyphScale = 0.48
        s.glyphShadow = true
        return s
    }

    /// Clear / Liquid Glass appearance macOS App Icon (Liquid Glass with crisp specular rim)
    static var appIconClear: IconSpec {
        var s = IconSpec()
        s.base = .folder
        s.shape = .squircle
        s.macMargin = true
        s.useGradient = true
        s.color1 = Color(white: 0.16, opacity: 0.45)
        s.color2 = Color(white: 0.05, opacity: 0.65)
        s.gradientAngle = 90
        s.gloss = true
        s.innerRim = true
        s.borderOn = true
        s.borderColor = Color.white.opacity(0.85)
        s.borderWidth = 0.005 // 1.5pt crisp specular rim
        s.dropShadow = true
        s.glyphKind = .symbol
        s.symbolName = "paintbrush.fill"
        s.glyphRotation = -20.0
        s.glyphColor = .white
        s.glyphScale = 0.48
        s.glyphShadow = true
        return s
    }

    /// Tinted appearance macOS App Icon (Dark glass plate with vibrant icon color)
    static var appIconTinted: IconSpec {
        var s = IconSpec()
        s.base = .folder
        s.shape = .squircle
        s.macMargin = true
        s.useGradient = true
        s.color1 = Color(hex: "#1E222A") ?? .black // Dark glass base
        s.color2 = Color(hex: "#0F1115") ?? .black
        s.gradientAngle = 90
        s.gloss = true
        s.innerRim = true
        s.borderOn = true
        let accent = NSColor.controlAccentColor.usingColorSpace(.sRGB) ?? NSColor.systemBlue
        s.borderColor = Color(nsColor: accent).opacity(0.65)
        s.borderWidth = 0.005
        s.dropShadow = true
        s.glyphKind = .symbol
        s.symbolName = "paintbrush.fill"
        s.glyphRotation = -20.0
        s.glyphScale = 0.48
        // Icon color in tinted: Radiant Cyan to Glowing Neon Violet gradient
        s.glyphGradient = true
        s.glyphColor = Color(hex: "#00F0FF") ?? .cyan
        s.glyphColor2 = Color(hex: "#A78BFA") ?? .purple
        s.glyphScale = 0.50
        s.glyphShadow = true
        return s
    }
}

// MARK: - Color Extension

extension Color {
    init?(hex: String) {
        var str = hex.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        if str.hasPrefix("#") { str.removeFirst() }
        guard str.count == 6, let rgb = UInt64(str, radix: 16) else { return nil }
        self.init(
            .sRGB,
            red: Double((rgb >> 16) & 0xFF) / 255.0,
            green: Double((rgb >> 8) & 0xFF) / 255.0,
            blue: Double(rgb & 0xFF) / 255.0,
            opacity: 1.0
        )
    }

    func darker(_ amount: Double) -> Color {
        Color(nsColor: NSColor(self).blended(withFraction: amount, of: .black) ?? NSColor(self))
    }

    var hexString: String {
        guard let components = NSColor(self).usingColorSpace(.sRGB) else { return "#FFFFFF" }
        let r = Int(round(components.redComponent * 255))
        let g = Int(round(components.greenComponent * 255))
        let b = Int(round(components.blueComponent * 255))
        return String(format: "#%02X%02X%02X", r, g, b)
    }
}


// MARK: - Preset Serialization

extension IconSpec {
    func toPreset(name: String = "Custom Theme") -> FolderLabPreset {
        FolderLabPreset(
            version: 1,
            name: name,
            color1Hex: color1.hexString,
            color2Hex: color2.hexString,
            useGradient: useGradient,
            gradientAngle: gradientAngle,
            gloss: gloss,
            innerRim: innerRim,
            liquidGlass: liquidGlass,
            glassOpacity: glassOpacity,
            specularRimWidth: specularRimWidth,
            glyphKind: glyphKind.rawValue,
            symbolName: symbolName,
            text: text,
            symbolMode: symbolMode.rawValue,
            glyphColorHex: glyphColor.hexString,
            glyphGradient: glyphGradient,
            glyphColor2Hex: glyphColor2.hexString,
            glyphOpacity: glyphOpacity,
            glyphScale: glyphScale,
            glyphYOffset: glyphYOffset,
            glyphRotation: glyphRotation,
            glyphShadow: glyphShadow,
            customImageData: customImageData,
            customImageTinted: customImageTinted,
            customImageName: customImageName,
            borderOn: borderOn,
            borderColorHex: borderColor.hexString,
            borderWidth: borderWidth,
            dropShadow: dropShadow,
            useThreeColorGradient: useThreeColorGradient,
            color3Hex: color3.hexString,
            texture: texture.rawValue,
            textureOpacity: textureOpacity,
            textFontFamily: textFontFamily.rawValue,
            textDepthStyle: textDepthStyle.rawValue,
            cornerBadge: cornerBadge.rawValue,
            cornerBadgeColorHex: cornerBadgeColor.hexString,
            nameplateEnabled: nameplateEnabled,
            nameplateText: nameplateText,
            nameplateStyle: nameplateStyle.rawValue,
            nameplateColorHex: nameplateColor.hexString,
            nameplateTextColorHex: nameplateTextColor.hexString,
            nameplateYOffset: nameplateYOffset,
            nameplateScale: nameplateScale,
            nameplateMoveIconAbove: nameplateMoveIconAbove,
            glyphEngravedFolderTint: glyphEngravedFolderTint
        )
    }

    static func fromPreset(_ preset: FolderLabPreset) -> IconSpec {
        var s = IconSpec()
        s.color1 = Color(hex: preset.color1Hex) ?? s.color1
        s.color2 = Color(hex: preset.color2Hex) ?? s.color2
        s.useGradient = preset.useGradient
        s.gradientAngle = preset.gradientAngle
        s.gloss = preset.gloss
        s.innerRim = preset.innerRim
        s.liquidGlass = preset.liquidGlass
        s.glassOpacity = preset.glassOpacity
        s.specularRimWidth = preset.specularRimWidth
        s.glyphKind = GlyphKind(rawValue: preset.glyphKind) ?? .symbol
        s.symbolName = preset.symbolName
        s.text = preset.text
        s.symbolMode = SymbolMode(rawValue: preset.symbolMode) ?? .monochrome
        s.glyphColor = Color(hex: preset.glyphColorHex) ?? s.glyphColor
        s.glyphGradient = preset.glyphGradient
        s.glyphColor2 = Color(hex: preset.glyphColor2Hex) ?? s.glyphColor2
        s.glyphOpacity = preset.glyphOpacity
        s.glyphScale = preset.glyphScale
        s.glyphYOffset = preset.glyphYOffset
        s.glyphRotation = preset.glyphRotation
        s.glyphShadow = preset.glyphShadow
        s.customImageData = preset.customImageData
        s.customImageTinted = preset.customImageTinted
        s.customImageName = preset.customImageName
        s.borderOn = preset.borderOn
        s.borderColor = Color(hex: preset.borderColorHex) ?? s.borderColor
        s.borderWidth = preset.borderWidth
        s.dropShadow = preset.dropShadow
        s.useThreeColorGradient = preset.useThreeColorGradient ?? false
        if let c3 = preset.color3Hex { s.color3 = Color(hex: c3) ?? s.color3 }
        if let tex = preset.texture { s.texture = SurfaceTexture(rawValue: tex) ?? .none }
        if let op = preset.textureOpacity { s.textureOpacity = op }
        if let tf = preset.textFontFamily { s.textFontFamily = TextFontFamily(rawValue: tf) ?? .rounded }
        if let td = preset.textDepthStyle { s.textDepthStyle = TextDepthStyle(rawValue: td) ?? .flat }
        if let cb = preset.cornerBadge { s.cornerBadge = CornerBadge(rawValue: cb) ?? .none }
        if let cbc = preset.cornerBadgeColorHex { s.cornerBadgeColor = Color(hex: cbc) ?? .white }
        if let ne = preset.nameplateEnabled { s.nameplateEnabled = ne }
        if let nt = preset.nameplateText { s.nameplateText = nt }
        if let ns = preset.nameplateStyle { s.nameplateStyle = NameplateStyle(rawValue: ns) ?? .retroTape }
        if let nch = preset.nameplateColorHex { s.nameplateColor = Color(hex: nch) ?? s.nameplateColor }
        if let ntch = preset.nameplateTextColorHex { s.nameplateTextColor = Color(hex: ntch) ?? s.nameplateTextColor }
        if let nyo = preset.nameplateYOffset { s.nameplateYOffset = nyo }
        if let nsc = preset.nameplateScale { s.nameplateScale = nsc }
        if let mv = preset.nameplateMoveIconAbove { s.nameplateMoveIconAbove = mv }
        if let gt = preset.glyphEngravedFolderTint { s.glyphEngravedFolderTint = gt }
        return s
    }
}
