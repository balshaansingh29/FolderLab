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
    case embossed = "Embossed 3D"
    case engraved = "Engraved Inset"
    public var id: String { rawValue }
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
    case retroTape = "Retro Embossed Tape"
    case glassCapsule = "Modern Glass Capsule"
    case brassPlate = "Engraved Brass Plaque"
    case cyberRibbon = "Cyber Neon Banner"
    case maskingTape = "Paper Masking Tape"
    case cleanTag = "Minimal Clean Badge"

    public var id: String { rawValue }

    public var iconName: String {
        switch self {
        case .retroTape: return "rectangle.fill"
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

    /// Generates an inspiring randomized icon with harmonious palette and aesthetic symbol.
    /// Generates an inspiring randomized icon with harmonious palette, procedural surface textures, and aesthetic symbols.
    static func random() -> IconSpec {
        func c(_ hex: String) -> Color { Color(hex: hex) ?? .blue }

        // Curated 3-color harmonious gradient design palettes with matching glyph colors
        let palettes: [(c1: String, c2: String, c3: String, glyph1: String, glyph2: String)] = [
            ("#36D1DC", "#5B86E5", "#1E3C72", "#FFFFFF", "#E0F2FE"), // Hyper Blue
            ("#FF8A5B", "#EA3B7A", "#6A11CB", "#FFFFFF", "#FFE4E6"), // Sunset Flame
            ("#FF007F", "#7928CA", "#00F0FF", "#00F0FF", "#FFFFFF"), // Cyber Neon
            ("#11998E", "#38EF7D", "#059669", "#FFFFFF", "#D1FAE5"), // Mint Emerald
            ("#F7971E", "#FFD200", "#FF512F", "#FFFFFF", "#FEF3C7"), // Solar Amber
            ("#3A3D45", "#141518", "#0B0C10", "#FFFFFF", "#94A3B8"), // Obsidian Titanium
            ("#8E54E9", "#4776E6", "#141E30", "#FFFFFF", "#DDD6FE"), // Deep Nebula
            ("#FC5C7D", "#6A82FB", "#A78BFA", "#FFFFFF", "#FBCFE8"), // Cotton Candy
            ("#30CFD0", "#330867", "#1CB5E0", "#FFFFFF", "#CFFAFE"), // Nordic Ice
            ("#ED213A", "#93291E", "#4B1212", "#FFFFFF", "#FECDD3"), // Crimson Ruby
            ("#FF7E5F", "#FEB47B", "#7F00FF", "#FFFFFF", "#FED7AA"), // Vaporwave Dusk
            ("#0D1117", "#161B22", "#00FF66", "#00FF66", "#FFFFFF"), // Hacker Matrix
            ("#F5AF19", "#E65C00", "#FFE000", "#FFFFFF", "#FEF08A"), // Prestige Gold
            ("#654EA3", "#EAAFC8", "#3B185F", "#FFFFFF", "#F3E8FF"), // Royal Amethyst
            ("#6CD0FF", "#2F9DF4", "#0A84FF", "#FFFFFF", "#E0F2FE"), // Apple Finder Blue
            ("#134E5E", "#71B280", "#0B3C49", "#FFFFFF", "#D1FAE5"), // Forest Moss
            ("#0F2027", "#203A43", "#2C5364", "#FFFFFF", "#93C5FD"), // Midnight Oceanic
            ("#485563", "#29323C", "#1E293B", "#FFFFFF", "#E2E8F0"), // Titanium Slate
            ("#7F00FF", "#E100FF", "#3B0764", "#FFFFFF", "#F5D0FE"), // Electric Violet
            ("#ED4264", "#FFEDBC", "#F43F5E", "#FFFFFF", "#FFE4E6"), // Peach Cream
            ("#43E97B", "#38F9D7", "#10B981", "#FFFFFF", "#A7F3D0"), // Toxic Lime
            ("#8A2387", "#E94057", "#F27121", "#FFFFFF", "#FED7AA"), // Bronze Copper
            ("#2C3E50", "#3498DB", "#1A252F", "#FFFFFF", "#BAE6FD"), // Minimal Chalk
            ("#18191C", "#23272A", "#7289DA", "#7289DA", "#FFFFFF")  // Stealth Discord
        ]

        let symbols = [
            // Developer & Tech
            "terminal.fill", "cpu.fill", "gearshape.2.fill", "macbook", "chevron.left.forwardslash.chevron.right",
            "server.rack", "swift", "waveform.path.ecg", "network", "externaldrive.fill",
            // Creative & Design
            "paintpalette.fill", "wand.and.stars", "sparkles", "cube.transparent.fill", "camera.fill",
            "pencil.and.outline", "eyeglasses", "slider.horizontal.3", "circle.hexagongrid.fill",
            // Energy & Nature
            "flame.fill", "bolt.fill", "drop.fill", "leaf.fill", "sun.max.fill", "moon.stars.fill",
            // Power & Status
            "star.fill", "crown.fill", "shield.checkerboard", "trophy.fill", "diamond.fill", "rosette",
            // Media & Sound
            "music.note", "headphones", "film.fill", "mic.fill", "bubble.left.and.bubble.right.fill",
            // Exploration & Tools
            "rocket.fill", "globe.americas.fill", "airplane", "paperplane.fill", "magnifyingglass",
            "folder.badge.gearshape.fill", "chart.xyaxis.line", "lock.shield.fill", "key.fill", "heart.fill"
        ]

        let textMonograms = [
            "A", "B", "C", "D", "E", "F", "G", "H", "J", "K", "L", "M", "N", "P", "Q", "R", "S", "T", "V", "W", "X", "Y", "Z",
            "🚀", "⚡️", "💎", "🔥", "🪐", "💡", "🎨", "👾", "🦊", "🎧", "☕️", "✨", "🛡️", "🔮", "🍀", "🍎", "🧬", "🕹️"
        ]

        var s = IconSpec()
        s.base = .folder
        s.shape = .squircle

        // Pick palette
        let pal = palettes.randomElement() ?? palettes[0]
        s.color1 = c(pal.c1)
        s.color2 = c(pal.c2)
        s.color3 = c(pal.c3)

        // 3-Color Gradient (~38% probability)
        let use3Stop = Double.random(in: 0...1) < 0.38
        s.useThreeColorGradient = use3Stop

        // Dynamic Angles
        s.gradientAngle = [0.0, 45.0, 90.0, 120.0, 135.0, 180.0, 225.0, 270.0].randomElement() ?? 90.0

        // Procedural Surface Textures (~58% probability)
        let textureChance = Double.random(in: 0...1)
        if textureChance < 0.58 {
            let textures: [SurfaceTexture] = [.carbon, .brushed, .leather, .grid, .stripes]
            s.texture = textures.randomElement() ?? .carbon
            switch s.texture {
            case .carbon:
                s.textureOpacity = Double.random(in: 0.18...0.36)
            case .brushed:
                s.textureOpacity = Double.random(in: 0.22...0.42)
            case .leather:
                s.textureOpacity = Double.random(in: 0.18...0.34)
            case .grid:
                s.textureOpacity = Double.random(in: 0.18...0.32)
            case .stripes:
                s.textureOpacity = Double.random(in: 0.16...0.30)
            case .none:
                s.textureOpacity = 0.22
            }
        } else {
            s.texture = .none
        }

        // Liquid Glass Mode (~18% probability)
        let isGlass = Double.random(in: 0...1) < 0.18
        if isGlass {
            s.liquidGlass = true
            s.glassOpacity = Double.random(in: 0.38...0.55)
            s.specularRimWidth = 0.007
        } else {
            s.liquidGlass = false
        }

        // Corner Badges (~22% probability)
        let badgeChance = Double.random(in: 0...1)
        if badgeChance < 0.22 {
            let badges: [CornerBadge] = [.lock, .star, .checkmark, .warning, .cloud, .heart, .tag, .bookmark, .pin]
            s.cornerBadge = badges.randomElement() ?? .star
            let badgeColors: [Color] = [.white, c("#FFD700"), c("#00F0FF"), c("#FF3B30"), c("#30D158")]
            s.cornerBadgeColor = badgeColors.randomElement() ?? .white
        } else {
            s.cornerBadge = .none
        }

        // Glyph Kind: ~22% Monogram / Emoji, ~78% SF Symbol
        let glyphKindChance = Double.random(in: 0...1)
        if glyphKindChance < 0.22 {
            s.glyphKind = .text
            s.text = textMonograms.randomElement() ?? "A"
            s.textFontFamily = TextFontFamily.allCases.randomElement() ?? .rounded
            s.textDepthStyle = TextDepthStyle.allCases.randomElement() ?? .embossed
            s.glyphScale = Double.random(in: 0.36...0.46)
        } else {
            s.glyphKind = .symbol
            s.symbolName = symbols.randomElement() ?? "sparkles"
            s.glyphScale = Double.random(in: 0.34...0.44)
        }

        // Glyph Gradient & Coloring
        let glyphGradientChance = Double.random(in: 0...1)
        if glyphGradientChance < 0.35 {
            s.glyphGradient = true
            s.glyphColor = c(pal.glyph1)
            s.glyphColor2 = c(pal.glyph2)
        } else {
            s.glyphGradient = false
            s.glyphColor = c(pal.glyph1)
        }

        // Occasional slight playful tilt (-6...6 deg) on symbols
        if Double.random(in: 0...1) < 0.15 {
            s.glyphRotation = Double(Int.random(in: -6...6))
        } else {
            s.glyphRotation = 0.0
        }

        s.glyphOpacity = Double.random(in: 0.90...1.0)
        s.glyphShadow = true
        s.gloss = true
        s.innerRim = true
        s.dropShadow = true
        return s
    }

    // MARK: - Official FolderLab App Icon Styles (Apple HIG & Icon Composer)

    /// Standard / Light appearance macOS App Icon
    static var appIconLight: IconSpec {
        var s = IconSpec()
        s.base = .folder
        s.shape = .squircle
        s.macMargin = true
        s.useGradient = true
        s.color1 = Color(hex: "#2563EB") ?? .blue // Electric Sapphire
        s.color2 = Color(hex: "#7C3AED") ?? .purple // Royal Violet
        s.gradientAngle = 135
        s.gloss = true
        s.innerRim = true
        s.dropShadow = true
        s.glyphKind = .symbol
        s.symbolName = "folder.fill"
        s.glyphColor = .white
        s.glyphScale = 0.50
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
        s.symbolName = "folder.fill"
        s.glyphColor = Color(hex: "#A78BFA") ?? .purple // Glowing Neon Violet
        s.glyphScale = 0.50
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
        s.symbolName = "folder.fill"
        s.glyphColor = .white
        s.glyphScale = 0.50
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
        s.symbolName = "folder.fill"
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
            nameplateScale: nameplateScale
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
        return s
    }
}
