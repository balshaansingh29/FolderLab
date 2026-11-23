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

// MARK: - Shareable Theme Preset (.folderlab)

struct FolderLabPreset: Codable {
    var version: Int = 1
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
}

enum SymbolMode: String, CaseIterable, Identifiable {
    case monochrome = "Monochrome"
    case hierarchical = "Hierarchical"
    case multicolor = "Multicolor"
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
    static func random() -> IconSpec {
        func c(_ hex: String) -> Color { Color(hex: hex) ?? .blue }

        let palettes: [(String, String)] = [
            ("#36D1DC", "#5B86E5"),
            ("#FF8A5B", "#EA3B7A"),
            ("#8E54E9", "#4776E6"),
            ("#43E97B", "#38F9D7"),
            ("#F7971E", "#FFD200"),
            ("#0BA360", "#3CBA92"),
            ("#667EEA", "#764BA2"),
            ("#FC5C7D", "#6A82FB"),
            ("#30CFD0", "#330867"),
            ("#F857A6", "#FF5858"),
            ("#4FACFE", "#00F2FE"),
            ("#2E3192", "#1BFFFF"),
            ("#B92B27", "#1565C0"),
            ("#24243E", "#0F0C20")
        ]

        let symbols = [
            "star.fill", "bolt.fill", "sparkles", "flame.fill", "heart.fill",
            "terminal.fill", "gearshape.fill", "wand.and.stars", "macbook",
            "cpu.fill", "cube.transparent.fill", "waveform.path.ecg",
            "paintpalette.fill", "rocket.fill", "globe.americas.fill",
            "shield.checkerboard", "crown.fill", "music.note", "camera.fill"
        ]

        var s = IconSpec()
        s.base = .folder
        s.shape = [.squircle, .squircle, .squircle, .circle].randomElement() ?? .squircle
        let pair = palettes.randomElement() ?? palettes[0]
        s.color1 = c(pair.0)
        s.color2 = c(pair.1)
        s.gradientAngle = [45.0, 90.0, 135.0, 180.0].randomElement() ?? 90.0
        s.gloss = true
        s.innerRim = true
        s.symbolName = symbols.randomElement() ?? "star.fill"
        s.glyphColor = .white
        s.glyphScale = Double.random(in: 0.46...0.56)
        s.glyphShadow = true
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
            dropShadow: dropShadow
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
        return s
    }
}
