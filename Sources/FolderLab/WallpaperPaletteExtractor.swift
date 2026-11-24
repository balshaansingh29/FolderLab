import SwiftUI
import AppKit

// MARK: - Wallpaper Theme Suggestion Model

struct WallpaperThemeSuggestion: Identifiable, Equatable {
    let id = UUID()
    let name: String
    let subtitle: String
    let iconName: String
    let gradientColors: [Color]
    let gradientAngle: Double
    let useThreeColor: Bool
    let color3: Color?
    let glyphColor: Color
    let liquidGlass: Bool
    let glassOpacity: Double
    let texture: SurfaceTexture
    let glyphEngraved: Bool

    var previewSpec: IconSpec {
        var spec = IconSpec()
        spec.color1 = gradientColors.first ?? .blue
        spec.color2 = gradientColors.count > 1 ? gradientColors[1] : (gradientColors.first ?? .blue)
        spec.useGradient = true
        spec.gradientAngle = gradientAngle
        spec.useThreeColorGradient = useThreeColor
        if let c3 = color3 { spec.color3 = c3 }
        spec.glyphColor = glyphColor
        spec.liquidGlass = liquidGlass
        spec.glassOpacity = glassOpacity
        spec.texture = texture
        spec.glyphEngravedFolderTint = glyphEngraved
        return spec
    }

    @MainActor
    func apply(to store: IconStore) {
        store.snapshotUndo()
        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
            store.spec.color1 = gradientColors.first ?? .blue
            store.spec.color2 = gradientColors.count > 1 ? gradientColors[1] : (gradientColors.first ?? .blue)
            store.spec.useGradient = true
            store.spec.gradientAngle = gradientAngle
            store.spec.useThreeColorGradient = useThreeColor
            if let c3 = color3 { store.spec.color3 = c3 }
            store.spec.glyphColor = glyphColor
            store.spec.liquidGlass = liquidGlass
            if liquidGlass {
                store.spec.glassOpacity = glassOpacity
                store.spec.innerRim = true
            }
            store.spec.texture = texture
            store.spec.glyphEngravedFolderTint = glyphEngraved
        }
        store.notify("Applied '\(name)' wallpaper theme! 🖥️✨")
    }

    static func == (lhs: WallpaperThemeSuggestion, rhs: WallpaperThemeSuggestion) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Wallpaper Palette Extractor

@MainActor
final class WallpaperPaletteExtractor: ObservableObject {
    static let shared = WallpaperPaletteExtractor()

    @Published var wallpaperThumbnail: NSImage? = nil
    @Published var wallpaperURL: URL? = nil
    @Published var wallpaperName: String = "Desktop Picture"
    @Published var isDarkWallpaper: Bool = false
    @Published var averageLuminance: Double = 0.5
    @Published var dominantColor1: Color = Color(hex: "#2F9DF4") ?? .blue
    @Published var dominantColor2: Color = Color(hex: "#6CD0FF") ?? .blue
    @Published var accentColor: Color = Color(hex: "#FF9F0A") ?? .orange
    @Published var highlightColor: Color = Color(hex: "#E0F2FE") ?? .white
    @Published var shadowColor: Color = Color(hex: "#1E293B") ?? .black
    @Published var paletteSwatches: [Color] = []
    @Published var paletteHexes: [String] = []
    @Published var themeSuggestions: [WallpaperThemeSuggestion] = []
    @Published var isExtracting: Bool = false
    @Published var lastExtractedDate: Date? = nil

    private init() {
        extractPalette()
        setupNotificationObserver()
    }

    private func setupNotificationObserver() {
        NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.activeSpaceDidChangeNotification,
            object: nil,
            queue: .main
        ) { _ in
            Task { @MainActor in
                WallpaperPaletteExtractor.shared.extractPalette()
            }
        }
    }

    func refresh() {
        extractPalette()
    }

    // MARK: - Core Extraction Algorithm

    func extractPalette() {
        isExtracting = true
        defer { isExtracting = false }

        let screen = NSScreen.main ?? NSScreen.screens.first
        var url: URL? = nil

        if let scr = screen {
            url = NSWorkspace.shared.desktopImageURL(for: scr)
        }

        // Fallbacks if desktopImageURL is nil or file doesn't exist
        if url == nil || !(FileManager.default.fileExists(atPath: url!.path)) {
            let possiblePaths = [
                NSHomeDirectory() + "/Library/Safari Shared Data/Safari Desktop Picture.jpg",
                "/System/Library/CoreServices/DefaultDesktop.heic",
                "/System/Library/Wallpapers/.default/DefaultAerial.heic"
            ]
            for path in possiblePaths {
                if FileManager.default.fileExists(atPath: path) {
                    url = URL(fileURLWithPath: path)
                    break
                }
            }
        }

        guard let imageURL = url, let sourceImage = NSImage(contentsOf: imageURL) else {
            generateFallbackSuggestions()
            return
        }

        wallpaperURL = imageURL
        wallpaperName = imageURL.lastPathComponent

        // Generate thumbnail
        generateThumbnail(from: sourceImage)

        // Downsample to 48x48 for fast, accurate pixel clustering
        let sampleSize = NSSize(width: 48, height: 48)
        guard let rep = NSBitmapImageRep(
            bitmapDataPlanes: nil,
            pixelsWide: Int(sampleSize.width),
            pixelsHigh: Int(sampleSize.height),
            bitsPerSample: 8,
            samplesPerPixel: 4,
            hasAlpha: true,
            isPlanar: false,
            colorSpaceName: .deviceRGB,
            bytesPerRow: 0,
            bitsPerPixel: 0
        ) else {
            generateFallbackSuggestions()
            return
        }

        NSGraphicsContext.saveGraphicsState()
        let ctx = NSGraphicsContext(bitmapImageRep: rep)
        NSGraphicsContext.current = ctx
        sourceImage.draw(in: NSRect(origin: .zero, size: sampleSize))
        NSGraphicsContext.restoreGraphicsState()

        // Cluster pixels into quantized HSB buckets
        var buckets: [Int: (count: Int, rSum: Double, gSum: Double, bSum: Double, sSum: Double, briSum: Double)] = [:]
        var totalLum = 0.0
        var totalPixels = 0

        for y in 0..<48 {
            for x in 0..<48 {
                guard let col = rep.colorAt(x: x, y: y)?.usingColorSpace(.sRGB) else { continue }
                let r = Double(col.redComponent)
                let g = Double(col.greenComponent)
                let b = Double(col.blueComponent)
                let h = Double(col.hueComponent)
                let s = Double(col.saturationComponent)
                let bri = Double(col.brightnessComponent)

                // Relative luminance (BT.709 standard)
                let lum = 0.2126 * r + 0.7152 * g + 0.0722 * b
                totalLum += lum
                totalPixels += 1

                let hBin = min(11, Int(h * 12))
                let sBin = min(3, Int(s * 4))
                let bBin = min(3, Int(bri * 4))
                let key = (hBin << 4) | (sBin << 2) | bBin

                if let existing = buckets[key] {
                    buckets[key] = (existing.count + 1, existing.rSum + r, existing.gSum + g, existing.bSum + b, existing.sSum + s, existing.briSum + bri)
                } else {
                    buckets[key] = (1, r, g, b, s, bri)
                }
            }
        }

        let avgLum = totalPixels > 0 ? (totalLum / Double(totalPixels)) : 0.5
        self.averageLuminance = avgLum
        self.isDarkWallpaper = avgLum < 0.48

        func nsColor(from bucket: (count: Int, rSum: Double, gSum: Double, bSum: Double, sSum: Double, briSum: Double)) -> NSColor {
            let c = Double(bucket.count)
            return NSColor(srgbRed: bucket.rSum / c, green: bucket.gSum / c, blue: bucket.bSum / c, alpha: 1.0)
        }

        func hex(from color: NSColor) -> String {
            guard let rgb = color.usingColorSpace(.sRGB) else { return "#3B82F6" }
            return String(
                format: "#%02X%02X%02X",
                Int(round(rgb.redComponent * 255)),
                Int(round(rgb.greenComponent * 255)),
                Int(round(rgb.blueComponent * 255))
            )
        }

        let sortedByCount = buckets.values.sorted { $0.count > $1.count }

        let nsDom1 = sortedByCount.count > 0 ? nsColor(from: sortedByCount[0]) : NSColor(srgbRed: 0.18, green: 0.55, blue: 0.88, alpha: 1.0)
        let nsDom2 = sortedByCount.count > 1 ? nsColor(from: sortedByCount[1]) : nsDom1

        // Saturated Accent
        let accents = buckets.values
            .filter { $0.count >= 4 && ($0.briSum / Double($0.count)) > 0.25 }
            .sorted { ($0.sSum / Double($0.count)) > ($1.sSum / Double($1.count)) }
        let nsAccent = accents.first.map(nsColor) ?? nsDom1

        // Bright Highlight
        let highlights = buckets.values
            .filter { $0.count >= 4 && ($0.briSum / Double($0.count)) > 0.65 }
            .sorted { ($0.briSum / Double($0.count)) > ($1.briSum / Double($1.count)) }
        let nsHighlight = highlights.first.map(nsColor) ?? nsDom2

        // Deep Shadow
        let shadows = buckets.values
            .filter { $0.count >= 4 && ($0.briSum / Double($0.count)) < 0.45 }
            .sorted { ($0.briSum / Double($0.count)) < ($1.briSum / Double($1.count)) }
        let nsShadow = shadows.first.map(nsColor) ?? NSColor(srgbRed: 0.08, green: 0.10, blue: 0.14, alpha: 1.0)

        let cDom1 = Color(nsColor: nsDom1)
        let cDom2 = Color(nsColor: nsDom2)
        let cAccent = Color(nsColor: nsAccent)
        let cHighlight = Color(nsColor: nsHighlight)
        let cShadow = Color(nsColor: nsShadow)

        self.dominantColor1 = cDom1
        self.dominantColor2 = cDom2
        self.accentColor = cAccent
        self.highlightColor = cHighlight
        self.shadowColor = cShadow

        self.paletteSwatches = [cDom1, cDom2, cAccent, cHighlight, cShadow]
        self.paletteHexes = [hex(from: nsDom1), hex(from: nsDom2), hex(from: nsAccent), hex(from: nsHighlight), hex(from: nsShadow)]

        buildSuggestions(cDom1: cDom1, cDom2: cDom2, cAccent: cAccent, cHighlight: cHighlight, cShadow: cShadow, isDark: isDarkWallpaper)
        lastExtractedDate = Date()
    }

    private func generateThumbnail(from image: NSImage) {
        let thumbSize = NSSize(width: 140, height: 90)
        let thumb = NSImage(size: thumbSize)
        thumb.lockFocus()
        image.draw(in: NSRect(origin: .zero, size: thumbSize), from: .zero, operation: .copy, fraction: 1.0)
        thumb.unlockFocus()
        self.wallpaperThumbnail = thumb
    }

    private func buildSuggestions(cDom1: Color, cDom2: Color, cAccent: Color, cHighlight: Color, cShadow: Color, isDark: Bool) {
        let whiteGlyph = Color.white.opacity(0.95)
        let darkGlyph = Color(hex: "#1E222A")?.opacity(0.92) ?? Color.black

        themeSuggestions = [
            // 1. Desktop Blend (Seamless Ambient)
            WallpaperThemeSuggestion(
                name: "Desktop Blend",
                subtitle: "Seamlessly matches your desktop background's dominant tones",
                iconName: "desktopcomputer",
                gradientColors: [cDom2, cDom1],
                gradientAngle: 90.0,
                useThreeColor: false,
                color3: nil,
                glyphColor: whiteGlyph,
                liquidGlass: false,
                glassOpacity: 0.45,
                texture: .none,
                glyphEngraved: false
            ),

            // 2. Vibrant Accent (Punchy Pop)
            WallpaperThemeSuggestion(
                name: "Vibrant Accent",
                subtitle: "Highlights your folder with the wallpaper's richest pop color",
                iconName: "sparkles",
                gradientColors: [cAccent, cDom1],
                gradientAngle: 120.0,
                useThreeColor: false,
                color3: nil,
                glyphColor: whiteGlyph,
                liquidGlass: false,
                glassOpacity: 0.45,
                texture: .none,
                glyphEngraved: false
            ),

            // 3. Frosted Glass (Translucent Ambient)
            WallpaperThemeSuggestion(
                name: "Frosted Glass",
                subtitle: "Translucent modern glass tinted by your active wallpaper",
                iconName: "circle.hexagongrid.fill",
                gradientColors: [cHighlight, cDom1],
                gradientAngle: 90.0,
                useThreeColor: false,
                color3: nil,
                glyphColor: whiteGlyph,
                liquidGlass: true,
                glassOpacity: 0.42,
                texture: .none,
                glyphEngraved: false
            ),

            // 4. Deep Midnight (Dark & Moody)
            WallpaperThemeSuggestion(
                name: "Deep Midnight",
                subtitle: "Dark obsidian aesthetic glowing with wallpaper accent",
                iconName: "moon.stars.fill",
                gradientColors: [cShadow, Color(hex: "#0D1117") ?? .black],
                gradientAngle: 90.0,
                useThreeColor: false,
                color3: nil,
                glyphColor: cAccent,
                liquidGlass: false,
                glassOpacity: 0.45,
                texture: .none,
                glyphEngraved: false
            ),

            // 5. Ambient Horizon (Soft Highlights)
            WallpaperThemeSuggestion(
                name: isDark ? "Ambient Horizon" : "Daylight Glow",
                subtitle: "Soft daylight atmosphere extracted from horizon highlights",
                iconName: "sun.max.fill",
                gradientColors: [cHighlight, cDom2],
                gradientAngle: 60.0,
                useThreeColor: false,
                color3: nil,
                glyphColor: isDark ? whiteGlyph : darkGlyph,
                liquidGlass: false,
                glassOpacity: 0.45,
                texture: .none,
                glyphEngraved: false
            ),

            // 6. Tri-Tone Spectrum (Full Range)
            WallpaperThemeSuggestion(
                name: "Tri-Tone Spectrum",
                subtitle: "Dynamic 3-stop gradient from highlights to deep shadows",
                iconName: "paintpalette.fill",
                gradientColors: [cHighlight, cAccent],
                gradientAngle: 135.0,
                useThreeColor: true,
                color3: cShadow,
                glyphColor: whiteGlyph,
                liquidGlass: false,
                glassOpacity: 0.45,
                texture: .none,
                glyphEngraved: false
            ),

            // 7. Tactile Deboss (Engraved Craft)
            WallpaperThemeSuggestion(
                name: "Tactile Deboss",
                subtitle: "Subtle tactile grain with authentic debossed glyph stamp",
                iconName: "square.grid.3x3.topleft.filled",
                gradientColors: [cDom1, cShadow],
                gradientAngle: 90.0,
                useThreeColor: false,
                color3: nil,
                glyphColor: whiteGlyph.opacity(0.85),
                liquidGlass: false,
                glassOpacity: 0.45,
                texture: .leather,
                glyphEngraved: true
            )
        ]
    }

    private func generateFallbackSuggestions() {
        let c1 = Color(hex: "#6CD0FF") ?? .blue
        let c2 = Color(hex: "#2F9DF4") ?? .blue
        let cAccent = Color(hex: "#FF9F0A") ?? .orange
        let cHighlight = Color(hex: "#E0F2FE") ?? .white
        let cShadow = Color(hex: "#1E293B") ?? .black

        self.dominantColor1 = c1
        self.dominantColor2 = c2
        self.accentColor = cAccent
        self.highlightColor = cHighlight
        self.shadowColor = cShadow
        self.paletteSwatches = [c1, c2, cAccent, cHighlight, cShadow]
        self.paletteHexes = ["#6CD0FF", "#2F9DF4", "#FF9F0A", "#E0F2FE", "#1E293B"]
        self.isDarkWallpaper = false
        self.averageLuminance = 0.5

        buildSuggestions(cDom1: c1, cDom2: c2, cAccent: cAccent, cHighlight: cHighlight, cShadow: cShadow, isDark: false)
    }

    // MARK: - Direct Application Helper

    func applyPrimaryTheme(to store: IconStore) {
        if let first = themeSuggestions.first {
            first.apply(to: store)
        }
    }
}
