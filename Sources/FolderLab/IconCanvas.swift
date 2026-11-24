import SwiftUI

/// Back of a folder: a body with a tab on the top-left.
struct FolderBackShape: Shape {
    func path(in r: CGRect) -> Path {
        let rad = r.height * 0.09
        let tabH = r.height * 0.10
        var p = Path()
        p.addRoundedRect(in: CGRect(x: r.minX, y: r.minY + tabH, width: r.width, height: r.height - tabH),
                         cornerSize: CGSize(width: rad, height: rad), style: .continuous)
        p.addRoundedRect(in: CGRect(x: r.minX, y: r.minY, width: r.width * 0.38, height: tabH + rad * 2),
                         cornerSize: CGSize(width: rad, height: rad), style: .continuous)
        return p
    }
}

/// Draws the icon at any size. All measurements are proportional, so the
/// preview and every exported size look identical and razor-sharp.
struct IconCanvas: View {
    let spec: IconSpec
    let size: CGFloat

    // MARK: Geometry

    private var tileSide: CGFloat { size * (spec.macMargin ? 824.0 / 1024.0 : 1.0) }
    private var folderW: CGFloat { size * 0.88 }
    private var folderH: CGFloat { folderW * 0.78 }
    private var folderShift: CGFloat { size * 0.02 }

    /// Side length the glyph is sized against.
    private var ref: CGFloat {
        switch spec.base {
        case .tile:   return tileSide
        case .folder: return folderH
        case .none:   return size * 0.95
        }
    }

    /// Vertical offset of the glyph's center from the canvas center.
    private var glyphBaseOffset: CGFloat {
        if spec.base == .folder {
            if spec.nameplateEnabled && !spec.nameplateText.isEmpty && spec.nameplateMoveIconAbove {
                // When nameplate is enabled, move the icon into the upper flap area so it sits gracefully above the nameplate!
                return folderShift - folderH * 0.06
            } else {
                return folderShift + folderH * 0.10
            }
        } else if spec.base == .tile {
            if spec.nameplateEnabled && !spec.nameplateText.isEmpty && spec.nameplateMoveIconAbove {
                return -tileSide * 0.12
            } else {
                return 0
            }
        }
        return 0
    }

    // MARK: Fills

    private func gradient(_ a: Color, _ b: Color, _ c: Color? = nil) -> AnyShapeStyle {
        guard spec.useGradient else { return AnyShapeStyle(a) }
        let rad = spec.gradientAngle * .pi / 180
        let dx = cos(rad), dy = sin(rad)
        let start = UnitPoint(x: 0.5 - dx / 2, y: 0.5 - dy / 2)
        let end = UnitPoint(x: 0.5 + dx / 2, y: 0.5 + dy / 2)

        if spec.useThreeColorGradient, let third = c {
            return AnyShapeStyle(LinearGradient(
                colors: [a, third, b],
                startPoint: start,
                endPoint: end
            ))
        }

        return AnyShapeStyle(LinearGradient(
            colors: [a, b],
            startPoint: start,
            endPoint: end
        ))
    }

    private var glyphFill: AnyShapeStyle {
        if spec.textDepthStyle == .engraved && spec.glyphEngravedFolderTint && spec.base == .folder {
            // Authentic macOS folder debossed translucent wash:
            // Darkens the folder plastic to look like a laser-etched deboss matching Finder folders
            return AnyShapeStyle(
                LinearGradient(
                    colors: [
                        Color.black.opacity(0.32),
                        Color.black.opacity(0.20)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
        } else if spec.glyphGradient {
            return AnyShapeStyle(LinearGradient(colors: [spec.glyphColor, spec.glyphColor2],
                                           startPoint: .top, endPoint: .bottom))
        } else {
            return AnyShapeStyle(spec.glyphColor)
        }
    }

    // MARK: Body

    var body: some View {
        ZStack {
            switch spec.base {
            case .tile:   tile
            case .folder: folder
            case .none:   EmptyView()
            }
            if spec.xlFolderEnabled {
                XLFolderGridPlateView(spec: spec, refSize: ref)
                    .offset(y: glyphBaseOffset + ref * spec.glyphYOffset)
            } else {
                glyph
                    .offset(y: glyphBaseOffset + ref * spec.glyphYOffset)
            }

            if spec.base == .tile && spec.nameplateEnabled && !spec.nameplateText.isEmpty {
                NameplateBannerView(spec: spec, folderW: tileSide, folderH: tileSide)
                    .offset(y: tileSide * CGFloat(spec.nameplateYOffset))
            }
        }
        .frame(width: size, height: size)
    }

    // MARK: Tile

    private var tileShape: AnyShape {
        switch spec.shape {
        case .squircle: return AnyShape(RoundedRectangle(cornerRadius: tileSide * 0.2237, style: .continuous))
        case .circle:   return AnyShape(Circle())
        case .rounded:  return AnyShape(RoundedRectangle(cornerRadius: tileSide * spec.cornerRadius, style: .continuous))
        case .square:   return AnyShape(Rectangle())
        }
    }

    private var tile: some View {
        ZStack {
            // Multi-tier realistic macOS drop shadow
            if spec.macMargin && spec.dropShadow {
                tileShape
                    .fill(Color.black.opacity(0.18))
                    .frame(width: tileSide, height: tileSide)
                    .blur(radius: size * 0.024)
                    .offset(y: size * 0.016)

                tileShape
                    .fill(Color.black.opacity(0.24))
                    .frame(width: tileSide, height: tileSide)
                    .blur(radius: size * 0.008)
                    .offset(y: size * 0.005)
            }

            // Main base fill (with Liquid Glass and 3-stop support)
            if spec.liquidGlass {
                tileShape
                    .fill(gradient(spec.color1.opacity(spec.glassOpacity), spec.color2.opacity(min(1.0, spec.glassOpacity + 0.15)), spec.color3.opacity(spec.glassOpacity)))
                    .frame(width: tileSide, height: tileSide)

                tileShape
                    .fill(LinearGradient(
                        colors: [.white.opacity(0.22), .white.opacity(0.05), .clear],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                    .frame(width: tileSide, height: tileSide)
            } else {
                tileShape
                    .fill(gradient(spec.color1, spec.color2, spec.color3))
                    .frame(width: tileSide, height: tileSide)
            }

            // Surface Texture Overlay
            if spec.texture != .none {
                FolderTextureOverlay(texture: spec.texture, opacity: spec.textureOpacity)
                    .frame(width: tileSide, height: tileSide)
                    .clipShape(tileShape)
            }

            // Specular gloss highlight (curved top sheen)
            if spec.gloss {
                tileShape
                    .fill(LinearGradient(
                        colors: [.white.opacity(spec.liquidGlass ? 0.45 : 0.32), .white.opacity(0.08), .white.opacity(0)],
                        startPoint: .top,
                        endPoint: UnitPoint(x: 0.5, y: 0.58)
                    ))
                    .frame(width: tileSide, height: tileSide)
            }

            // Subtle inner rim bevel / Specular glass chamfer
            if spec.innerRim {
                let rimColors = spec.liquidGlass ? [
                    Color.white.opacity(0.90),
                    Color.white.opacity(0.35),
                    Color(hex: "#338CFF")?.opacity(0.20) ?? Color.blue.opacity(0.20),
                    Color.white.opacity(0.65)
                ] : [
                    Color.white.opacity(0.42),
                    Color.white.opacity(0.08),
                    Color.black.opacity(0.22)
                ]

                tileShape
                    .stroke(
                        LinearGradient(
                            colors: rimColors,
                            startPoint: spec.liquidGlass ? .topLeading : .top,
                            endPoint: spec.liquidGlass ? .bottomTrailing : .bottom
                        ),
                        lineWidth: max(1, tileSide * (spec.liquidGlass ? spec.specularRimWidth * 2 : 0.009))
                    )
                    .frame(width: tileSide, height: tileSide)
                    .clipShape(tileShape)
            }

            // User-specified border
            if spec.borderOn {
                tileShape
                    .stroke(spec.borderColor, lineWidth: tileSide * spec.borderWidth * 2)
                    .frame(width: tileSide, height: tileSide)
                    .clipShape(tileShape)
            }
        }
    }

    // MARK: Folder

    private var folder: some View {
        let rad = folderH * 0.09
        let frontH = folderH * 0.80
        return ZStack {
            // 1. Back folder tab
            if spec.liquidGlass {
                FolderBackShape()
                    .fill(gradient(spec.color1.opacity(spec.glassOpacity * 0.75), spec.color2.opacity(spec.glassOpacity * 0.90), spec.color3.opacity(spec.glassOpacity * 0.8)))
            } else {
                FolderBackShape()
                    .fill(gradient(spec.color1.darker(0.25), spec.color2.darker(0.35), spec.color3.darker(0.30)))
            }

            // 2. Interior crease shadow between back tab and front flap
            RoundedRectangle(cornerRadius: rad, style: .continuous)
                .fill(Color.black.opacity(0.18))
                .frame(width: folderW * 0.98, height: frontH)
                .offset(y: -folderH * 0.015)
                .blur(radius: folderH * 0.012)

            // 2b. Peek Inside Pocket Contents (v0.5+)
            if spec.peekInsideEnabled {
                FolderPeekContentView(
                    contentType: spec.effectivePeekContentType,
                    folderW: folderW,
                    folderH: folderH,
                    frontH: frontH
                )
            }

            // 3. Front flap
            if spec.liquidGlass {
                RoundedRectangle(cornerRadius: rad, style: .continuous)
                    .fill(gradient(spec.color1.opacity(spec.glassOpacity), spec.color2.opacity(min(1.0, spec.glassOpacity + 0.15)), spec.color3.opacity(spec.glassOpacity)))
                    .frame(width: folderW, height: frontH)
                    .frame(width: folderW, height: folderH, alignment: .bottom)

                // Diagonal frosted glass diffusion sheen
                RoundedRectangle(cornerRadius: rad, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [.white.opacity(0.22), .white.opacity(0.04), .clear],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: folderW, height: frontH)
                    .frame(width: folderW, height: folderH, alignment: .bottom)
            } else {
                RoundedRectangle(cornerRadius: rad, style: .continuous)
                    .fill(gradient(spec.color1, spec.color2, spec.color3))
                    .frame(width: folderW, height: frontH)
                    .frame(width: folderW, height: folderH, alignment: .bottom)
            }

            // 3b. Front Flap Procedural Surface Texture (v0.2)
            if spec.texture != .none {
                FolderTextureOverlay(texture: spec.texture, opacity: spec.textureOpacity)
                    .frame(width: folderW, height: frontH)
                    .clipShape(RoundedRectangle(cornerRadius: rad, style: .continuous))
                    .frame(width: folderW, height: folderH, alignment: .bottom)
            }

            // 4. Highlight rim on flap (tactile specular glass/leather chamfer)
            if spec.innerRim {
                let rimColors = spec.liquidGlass ? [
                    Color.white.opacity(0.85),
                    Color.white.opacity(0.35),
                    Color(hex: "#338CFF")?.opacity(0.20) ?? Color.blue.opacity(0.20),
                    Color.white.opacity(0.65)
                ] : [
                    Color.white.opacity(0.60),
                    Color.white.opacity(0.15),
                    Color.clear
                ]

                RoundedRectangle(cornerRadius: rad, style: .continuous)
                    .strokeBorder(
                        LinearGradient(
                            colors: rimColors,
                            startPoint: spec.liquidGlass ? .topLeading : .top,
                            endPoint: spec.liquidGlass ? .bottomTrailing : UnitPoint(x: 0.5, y: 0.45)
                        ),
                        lineWidth: max(1, folderH * (spec.liquidGlass ? spec.specularRimWidth * 2 : 0.012))
                    )
                    .frame(width: folderW, height: frontH)
                    .frame(width: folderW, height: folderH, alignment: .bottom)
            }

            // 5. Corner Mini-Badge (v0.2)
            if spec.cornerBadge != .none, let badgeSymbol = spec.cornerBadge.symbolName {
                let badgeSize = folderH * 0.22
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color.black.opacity(0.75), Color.black.opacity(0.92)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .overlay(
                            Circle().strokeBorder(Color.white.opacity(0.35), lineWidth: max(0.8, badgeSize * 0.08))
                        )
                        .shadow(color: .black.opacity(0.45), radius: badgeSize * 0.18, y: badgeSize * 0.08)

                    Image(systemName: badgeSymbol)
                        .resizable()
                        .scaledToFit()
                        .frame(width: badgeSize * 0.52, height: badgeSize * 0.52)
                        .foregroundStyle(spec.cornerBadgeColor)
                        .shadow(color: .white.opacity(0.2), radius: 0.5, y: 0.5)
                }
                .frame(width: badgeSize, height: badgeSize)
                .offset(x: folderW * 0.36, y: -folderH * 0.06)
            }

            // 6. Folder Nameplate / Label Banner (v0.4)
            if spec.nameplateEnabled && !spec.nameplateText.isEmpty {
                NameplateBannerView(spec: spec, folderW: folderW, folderH: folderH)
                    .offset(y: folderH * 0.08 + folderH * CGFloat(spec.nameplateYOffset))
            }
        }
        .frame(width: folderW, height: folderH)
        .shadow(color: .black.opacity(spec.dropShadow ? 0.32 : 0),
                radius: size * 0.016, x: 0, y: size * 0.010)
        .shadow(color: .black.opacity(spec.dropShadow ? 0.16 : 0),
                radius: size * 0.005, x: 0, y: size * 0.003)
        .offset(y: folderShift)
    }

    // MARK: Glyph

    @ViewBuilder
    private var glyph: some View {
        let g = glyphContent
            .rotationEffect(.degrees(spec.glyphRotation))
            .opacity(spec.glyphOpacity)

        applyDepthStyle(to: g)
    }

    @ViewBuilder
    private func applyDepthStyle(to view: some View) -> some View {
        switch spec.textDepthStyle {
        case .flat:
            if spec.glyphShadow {
                if spec.base == .folder {
                    view
                        .shadow(color: .white.opacity(0.35), radius: 0.5, x: 0, y: 1.0)
                        .shadow(color: .black.opacity(0.45), radius: ref * 0.018, x: 0, y: ref * 0.010)
                        .shadow(color: .black.opacity(0.25), radius: ref * 0.005, x: 0, y: -0.5)
                } else {
                    view
                        .shadow(color: .black.opacity(0.40), radius: ref * 0.022, x: 0, y: ref * 0.014)
                        .shadow(color: .black.opacity(0.20), radius: ref * 0.006, x: 0, y: ref * 0.003)
                }
            } else {
                view
            }

        case .engraved:
            // macOS Folder Debossed / Engraved Inset:
            // Exact recreation of macOS native folder deboss:
            // 1. Dark top shadow inside groove: simulates overhead light casting a shadow into the recessed cut
            // 2. Bright white specular highlight on bottom lip: simulates overhead light catching the lower ledge
            // 3. Ambient depth shadow
            view
                .shadow(color: Color.black.opacity(0.70), radius: 0.8, x: 0, y: -1.0)
                .shadow(color: Color.white.opacity(0.75), radius: 0.6, x: 0, y: 1.2)
                .shadow(color: Color.black.opacity(0.20), radius: ref * 0.012, x: 0, y: ref * 0.008)

        case .embossed:
            // 3D Embossed (raised):
            view
                .shadow(color: Color.white.opacity(0.80), radius: 0.8, x: 0, y: -1.0)
                .shadow(color: Color.black.opacity(0.55), radius: ref * 0.016, x: 0, y: ref * 0.012)

        case .insetShadow:
            // Deep Inset:
            view
                .shadow(color: Color.black.opacity(0.90), radius: 1.2, x: 0, y: -1.5)
                .shadow(color: Color.white.opacity(0.45), radius: 0.5, x: 0, y: 0.8)
        }
    }

    @ViewBuilder
    private var glyphContent: some View {
        switch spec.glyphKind {
        case .symbol:
            let img = Image(systemName: spec.symbolName)
                .resizable()
                .scaledToFit()
            Group {
                switch spec.symbolMode {
                case .monochrome:
                    img.symbolRenderingMode(.monochrome).foregroundStyle(glyphFill)
                case .hierarchical:
                    img.symbolRenderingMode(.hierarchical).foregroundStyle(glyphFill)
                case .multicolor:
                    img.symbolRenderingMode(.multicolor)
                case .palette:
                    img.symbolRenderingMode(.palette).foregroundStyle(glyphFill, spec.glyphColor2)
                }
            }
            .frame(width: ref * spec.glyphScale, height: ref * spec.glyphScale)
        case .text:
            let fontDesign: Font.Design = {
                switch spec.textFontFamily {
                case .rounded: return .rounded
                case .monospaced: return .monospaced
                case .serif: return .serif
                case .standard: return .default
                }
            }()

            Text(spec.text)
                .font(.system(size: ref * spec.glyphScale, weight: .bold, design: fontDesign))
                .foregroundStyle(glyphFill)
                .lineLimit(1)
                .minimumScaleFactor(0.15)
                .frame(width: ref * 0.9, height: ref * 0.9)
        case .customImage:
            if let data = spec.customImageData, let nsImg = NSImage(data: data) {
                if spec.customImageTinted || (spec.textDepthStyle == .engraved && spec.glyphEngravedFolderTint) {
                    Image(nsImage: nsImg)
                        .renderingMode(.template)
                        .resizable()
                        .scaledToFit()
                        .foregroundStyle(glyphFill)
                        .frame(width: ref * spec.glyphScale, height: ref * spec.glyphScale)
                } else {
                    Image(nsImage: nsImg)
                        .resizable()
                        .scaledToFit()
                        .frame(width: ref * spec.glyphScale, height: ref * spec.glyphScale)
                }
            } else {
                Image(systemName: "photo.badge.plus")
                    .resizable()
                    .scaledToFit()
                    .foregroundStyle(glyphFill)
                    .frame(width: ref * spec.glyphScale, height: ref * spec.glyphScale)
            }
        }
    }
}

// MARK: - Procedural Surface Texture Overlay

struct FolderTextureOverlay: View {
    let texture: SurfaceTexture
    let opacity: Double

    var body: some View {
        Canvas { context, sz in
            switch texture {
            case .none:
                break
            case .carbon:
                let step: CGFloat = 8
                for x in stride(from: -sz.height, to: sz.width + sz.height, by: step) {
                    var p1 = Path()
                    p1.move(to: CGPoint(x: x, y: 0))
                    p1.addLine(to: CGPoint(x: x + sz.height, y: sz.height))
                    context.stroke(p1, with: .color(.black.opacity(0.40)), lineWidth: 1.5)

                    var p2 = Path()
                    p2.move(to: CGPoint(x: x + sz.height, y: 0))
                    p2.addLine(to: CGPoint(x: x, y: sz.height))
                    context.stroke(p2, with: .color(.white.opacity(0.18)), lineWidth: 1.0)
                }
            case .brushed:
                let step: CGFloat = 3
                for y in stride(from: 0, to: sz.height, by: step) {
                    var p = Path()
                    p.move(to: CGPoint(x: 0, y: y))
                    p.addLine(to: CGPoint(x: sz.width, y: y))
                    let alpha = (Int(y) % 2 == 0) ? 0.30 : 0.10
                    context.stroke(p, with: .color(.white.opacity(alpha)), lineWidth: 1.0)
                }
            case .leather:
                let step: CGFloat = 6
                for x in stride(from: 2, to: sz.width, by: step) {
                    for y in stride(from: 2, to: sz.height, by: step) {
                        let offset = (Int(x / step) % 2 == 0) ? step / 2 : 0
                        let dot = CGRect(x: x, y: y + offset, width: 2, height: 2)
                        context.fill(Path(ellipseIn: dot), with: .color(.black.opacity(0.35)))
                    }
                }
            case .grid:
                let step: CGFloat = 12
                for x in stride(from: step/2, to: sz.width, by: step) {
                    for y in stride(from: step/2, to: sz.height, by: step) {
                        let dot = CGRect(x: x - 1, y: y - 1, width: 2.2, height: 2.2)
                        context.fill(Path(ellipseIn: dot), with: .color(.white.opacity(0.40)))
                    }
                }
            case .stripes:
                let step: CGFloat = 10
                for x in stride(from: -sz.height, to: sz.width + sz.height, by: step) {
                    var p = Path()
                    p.move(to: CGPoint(x: x, y: 0))
                    p.addLine(to: CGPoint(x: x + sz.height, y: sz.height))
                    context.stroke(p, with: .color(.black.opacity(0.30)), lineWidth: 2.0)
                }
            }
        }
        .opacity(opacity)
    }
}


// MARK: - Folder Nameplate / Label Banner View (v0.4)

struct NameplateBannerView: View {
    let spec: IconSpec
    let folderW: CGFloat
    let folderH: CGFloat

    private var bannerWidth: CGFloat {
        folderW * CGFloat(spec.nameplateScale)
    }

    private var bannerHeight: CGFloat {
        max(12, folderH * 0.125)
    }

    var body: some View {
        ZStack {
            switch spec.nameplateStyle {
            case .textOnly:
                textOnlyView
            case .retroTape:
                retroTapeView
            case .folderEngraved:
                folderEngravedView
            case .glassCapsule:
                glassCapsuleView
            case .brassPlate:
                brassPlateView
            case .cyberRibbon:
                cyberRibbonView
            case .maskingTape:
                maskingTapeView
            case .cleanTag:
                cleanTagView
            }
        }
        .frame(width: bannerWidth, height: bannerHeight)
    }

    // 0. Text Only Nameplate (Direct Flap Typography)
    private var textOnlyView: some View {
        Group {
            if spec.textDepthStyle == .engraved {
                Text(spec.nameplateText.uppercased())
                    .font(.system(size: bannerHeight * 0.60, weight: .heavy, design: .rounded))
                    .tracking(1.4)
                    .lineLimit(1)
                    .minimumScaleFactor(0.4)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [
                                Color.black.opacity(0.38),
                                Color.black.opacity(0.24)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .shadow(color: Color.black.opacity(0.75), radius: 0.7, x: 0, y: -0.9)
                    .shadow(color: Color.white.opacity(0.75), radius: 0.6, x: 0, y: 1.1)
            } else {
                Text(spec.nameplateText.uppercased())
                    .font(.system(size: bannerHeight * 0.60, weight: .bold, design: .rounded))
                    .tracking(1.3)
                    .lineLimit(1)
                    .minimumScaleFactor(0.4)
                    .foregroundStyle(spec.nameplateTextColor)
                    .shadow(color: Color.black.opacity(0.45), radius: 1.2, x: 0, y: 1.0)
            }
        }
        .padding(.horizontal, bannerHeight * 0.2)
    }

    // 2. Folder Engraved / macOS Debossed Nameplate
    private var folderEngravedView: some View {
        ZStack {
            // Recessed groove plate in folder flap
            RoundedRectangle(cornerRadius: 4, style: .continuous)
                .fill(Color.black.opacity(0.14))

            // Inset groove bevel (dark top shadow, white bottom specular highlight)
            RoundedRectangle(cornerRadius: 4, style: .continuous)
                .strokeBorder(
                    LinearGradient(
                        colors: [
                            Color.black.opacity(0.40),
                            Color.black.opacity(0.12),
                            Color.white.opacity(0.55)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    ),
                    lineWidth: 0.9
                )

            // Engraved debossed text inside the plate
            Text(spec.nameplateText.uppercased())
                .font(.system(size: bannerHeight * 0.52, weight: .heavy, design: .rounded))
                .tracking(1.4)
                .lineLimit(1)
                .minimumScaleFactor(0.4)
                .foregroundStyle(
                    LinearGradient(
                        colors: [
                            Color.black.opacity(0.38),
                            Color.black.opacity(0.24)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .shadow(color: Color.black.opacity(0.75), radius: 0.7, x: 0, y: -0.9)
                .shadow(color: Color.white.opacity(0.75), radius: 0.6, x: 0, y: 1.1)
                .padding(.horizontal, bannerHeight * 0.35)
        }
        .shadow(color: Color.white.opacity(0.35), radius: 0.5, x: 0, y: 1.0)
        .shadow(color: Color.black.opacity(0.30), radius: 0.8, x: 0, y: -0.8)
    }

    // 1. Retro Embossed Dymo Label Tape
    private var retroTapeView: some View {
        ZStack {
            // Tape base
            RoundedRectangle(cornerRadius: 2, style: .continuous)
                .fill(spec.nameplateColor)

            // Top glossy tape reflection
            VStack(spacing: 0) {
                RoundedRectangle(cornerRadius: 2, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [.white.opacity(0.35), .white.opacity(0.08), .clear],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(height: bannerHeight * 0.48)
                Spacer()
            }

            // Cut edges on left & right
            HStack {
                Rectangle()
                    .fill(Color.white.opacity(0.18))
                    .frame(width: 1)
                Spacer()
                Rectangle()
                    .fill(Color.white.opacity(0.18))
                    .frame(width: 1)
            }

            // Embossed 3D White Stamped Text
            Text(spec.nameplateText.uppercased())
                .font(.system(size: bannerHeight * 0.58, weight: .heavy, design: .monospaced))
                .tracking(1.4)
                .lineLimit(1)
                .minimumScaleFactor(0.4)
                .foregroundStyle(spec.nameplateTextColor)
                .shadow(color: .white.opacity(0.85), radius: 0.5, x: 0, y: 0.8)
                .shadow(color: .black.opacity(0.75), radius: 0.6, x: 0, y: -0.8)
                .padding(.horizontal, bannerHeight * 0.3)
        }
        .clipShape(RoundedRectangle(cornerRadius: 2, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 2, style: .continuous)
                .strokeBorder(Color.white.opacity(0.20), lineWidth: 0.8)
        )
        .shadow(color: .black.opacity(0.40), radius: folderH * 0.016, x: 0, y: folderH * 0.008)
    }

    // 2. Modern Glass Capsule / Pill
    private var glassCapsuleView: some View {
        ZStack {
            Capsule()
                .fill(
                    LinearGradient(
                        colors: [spec.nameplateColor.opacity(0.45), spec.nameplateColor.opacity(0.75)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            // Specular highlight rim
            Capsule()
                .strokeBorder(
                    LinearGradient(
                        colors: [.white.opacity(0.85), .white.opacity(0.20)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: max(1, bannerHeight * 0.08)
                )

            Text(spec.nameplateText)
                .font(.system(size: bannerHeight * 0.52, weight: .bold, design: .rounded))
                .lineLimit(1)
                .minimumScaleFactor(0.4)
                .foregroundStyle(spec.nameplateTextColor)
                .shadow(color: .black.opacity(0.35), radius: 1, y: 1)
                .padding(.horizontal, bannerHeight * 0.4)
        }
        .shadow(color: .black.opacity(0.30), radius: folderH * 0.016, y: folderH * 0.008)
    }

    // 3. Engraved Brass Plaque
    private var brassPlateView: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 3, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(hex: "#FFE57F") ?? .yellow,
                            Color(hex: "#E5A93C") ?? .orange,
                            Color(hex: "#B87A14") ?? .brown
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )

            // Subtle beveled stroke
            RoundedRectangle(cornerRadius: 3, style: .continuous)
                .strokeBorder(
                    LinearGradient(
                        colors: [.white.opacity(0.85), Color(hex: "#5A3A00") ?? .black],
                        startPoint: .top,
                        endPoint: .bottom
                    ),
                    lineWidth: 1
                )

            // 4 Corner screws/rivets
            HStack {
                Circle()
                    .fill(Color(hex: "#5C3B00") ?? .black)
                    .frame(width: max(2, bannerHeight * 0.16), height: max(2, bannerHeight * 0.16))
                    .overlay(Circle().stroke(Color.white.opacity(0.5), lineWidth: 0.5))
                    .padding(.leading, bannerHeight * 0.2)
                Spacer()
                Circle()
                    .fill(Color(hex: "#5C3B00") ?? .black)
                    .frame(width: max(2, bannerHeight * 0.16), height: max(2, bannerHeight * 0.16))
                    .overlay(Circle().stroke(Color.white.opacity(0.5), lineWidth: 0.5))
                    .padding(.trailing, bannerHeight * 0.2)
            }

            // Engraved inset typography
            Text(spec.nameplateText)
                .font(.system(size: bannerHeight * 0.50, weight: .bold, design: .serif))
                .lineLimit(1)
                .minimumScaleFactor(0.4)
                .foregroundStyle(Color(hex: "#3D2400") ?? .black)
                .shadow(color: .white.opacity(0.65), radius: 0.5, x: 0, y: 0.8)
                .shadow(color: .black.opacity(0.6), radius: 0.5, x: 0, y: -0.5)
                .padding(.horizontal, bannerHeight * 0.45)
        }
        .clipShape(RoundedRectangle(cornerRadius: 3, style: .continuous))
        .shadow(color: .black.opacity(0.40), radius: folderH * 0.018, y: folderH * 0.010)
    }

    // 4. Cyber Neon Banner
    private var cyberRibbonView: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 4, style: .continuous)
                .fill(Color(hex: "#090D16") ?? .black)

            RoundedRectangle(cornerRadius: 4, style: .continuous)
                .strokeBorder(spec.nameplateColor, lineWidth: 1.5)
                .shadow(color: spec.nameplateColor.opacity(0.85), radius: 3)

            Text(spec.nameplateText.uppercased())
                .font(.system(size: bannerHeight * 0.52, weight: .heavy, design: .monospaced))
                .tracking(1.2)
                .lineLimit(1)
                .minimumScaleFactor(0.4)
                .foregroundStyle(spec.nameplateTextColor)
                .shadow(color: spec.nameplateTextColor.opacity(0.9), radius: 3)
                .padding(.horizontal, bannerHeight * 0.3)
        }
        .shadow(color: .black.opacity(0.50), radius: folderH * 0.018, y: folderH * 0.010)
    }

    // 5. Paper Masking Tape
    private var maskingTapeView: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 1, style: .continuous)
                .fill(Color(hex: "#F8F4E8")?.opacity(0.92) ?? Color.white.opacity(0.9))

            // Fiber grain
            Rectangle()
                .strokeBorder(Color.black.opacity(0.08), lineWidth: 0.5)

            Text(spec.nameplateText)
                .font(.system(size: bannerHeight * 0.52, weight: .semibold, design: .monospaced))
                .lineLimit(1)
                .minimumScaleFactor(0.4)
                .foregroundStyle(Color(hex: "#262626") ?? .black)
                .padding(.horizontal, bannerHeight * 0.3)
        }
        .shadow(color: .black.opacity(0.22), radius: folderH * 0.014, y: folderH * 0.008)
    }

    // 6. Minimal Clean Badge
    private var cleanTagView: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .fill(spec.nameplateColor)

            Text(spec.nameplateText)
                .font(.system(size: bannerHeight * 0.52, weight: .bold, design: .default))
                .lineLimit(1)
                .minimumScaleFactor(0.4)
                .foregroundStyle(spec.nameplateTextColor)
                .padding(.horizontal, bannerHeight * 0.35)
        }
        .overlay(
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .strokeBorder(Color.white.opacity(0.18), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.28), radius: folderH * 0.015, y: folderH * 0.008)
    }
}


// MARK: - Peek Inside Pocket Content View (v0.5+)

struct FolderPeekContentView: View {
    let contentType: PeekContentType
    let folderW: CGFloat
    let folderH: CGFloat
    let frontH: CGFloat

    private var pocketW: CGFloat { folderW * 0.76 }
    private var pocketH: CGFloat { folderH * 0.46 }

    var body: some View {
        ZStack {
            switch contentType {
            case .documents, .autoDetect:
                documentsStack
            case .code:
                codeEditorStack
            case .photos:
                photosStack
            case .music:
                musicVinylStack
            }
        }
        .frame(width: pocketW, height: pocketH)
        .offset(x: folderW * 0.02, y: -folderH * 0.23)
    }

    // 1. Documents Stack: Crisp A4 sheets with folded corner tips & lined text
    private var documentsStack: some View {
        ZStack {
            // Sheet 1 (back left)
            RoundedRectangle(cornerRadius: max(2, pocketH * 0.03), style: .continuous)
                .fill(Color(white: 0.92))
                .frame(width: pocketW * 0.48, height: pocketH * 0.88)
                .rotationEffect(.degrees(-6))
                .offset(x: -pocketW * 0.16, y: pocketH * 0.02)
                .shadow(color: .black.opacity(0.12), radius: 2, y: 1)

            // Sheet 2 (back right)
            RoundedRectangle(cornerRadius: max(2, pocketH * 0.03), style: .continuous)
                .fill(Color(white: 0.96))
                .frame(width: pocketW * 0.50, height: pocketH * 0.90)
                .rotationEffect(.degrees(5))
                .offset(x: pocketW * 0.15, y: 0)
                .shadow(color: .black.opacity(0.14), radius: 2, y: 1)

            // Sheet 3 (front center - A4 document with folded dog-ear corner tip)
            ZStack(alignment: .topTrailing) {
                RoundedRectangle(cornerRadius: max(2, pocketH * 0.03), style: .continuous)
                    .fill(Color.white)

                // Dog-ear corner fold
                Path { path in
                    let foldSize = max(5, pocketH * 0.14)
                    path.move(to: CGPoint(x: 0, y: 0))
                    path.addLine(to: CGPoint(x: foldSize, y: foldSize))
                    path.addLine(to: CGPoint(x: 0, y: foldSize))
                    path.closeSubpath()
                }
                .fill(Color(white: 0.86))
                .frame(width: max(5, pocketH * 0.14), height: max(5, pocketH * 0.14))
                .shadow(color: .black.opacity(0.20), radius: 1, x: -0.5, y: 0.5)

                // Document text lines
                VStack(alignment: .leading, spacing: max(2, pocketH * 0.045)) {
                    // Document colored header banner
                    RoundedRectangle(cornerRadius: 1.5)
                        .fill(Color.blue.opacity(0.75))
                        .frame(width: pocketW * 0.28, height: max(2, pocketH * 0.04))

                    // Lined paragraphs
                    ForEach(0..<4) { i in
                        let widths: [CGFloat] = [0.42, 0.38, 0.44, 0.26]
                        RoundedRectangle(cornerRadius: 1.0)
                            .fill(Color.black.opacity(0.22))
                            .frame(width: pocketW * widths[i], height: max(1.5, pocketH * 0.025))
                    }
                }
                .padding(.top, pocketH * 0.10)
                .padding(.leading, pocketH * 0.08)
                .frame(maxWidth: .infinity, alignment: .topLeading)
            }
            .frame(width: pocketW * 0.54, height: pocketH * 0.96)
            .rotationEffect(.degrees(-1.5))
            .offset(x: -pocketW * 0.02, y: -pocketH * 0.02)
            .shadow(color: .black.opacity(0.20), radius: 3, y: 1.5)
        }
    }

    // 2. Code / Dev: Dark-mode terminal & IDE editor cards with colored syntax bars
    private var codeEditorStack: some View {
        ZStack {
            // Background terminal card
            RoundedRectangle(cornerRadius: max(3, pocketH * 0.04), style: .continuous)
                .fill(Color(hex: "#0F141C") ?? .black)
                .frame(width: pocketW * 0.50, height: pocketH * 0.86)
                .rotationEffect(.degrees(4.5))
                .offset(x: pocketW * 0.18, y: pocketH * 0.02)
                .shadow(color: .black.opacity(0.25), radius: 3, y: 1)

            // Main IDE editor card
            ZStack(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: max(3, pocketH * 0.04), style: .continuous)
                    .fill(Color(hex: "#161B22") ?? .black)

                VStack(alignment: .leading, spacing: max(2.5, pocketH * 0.04)) {
                    // Window traffic lights
                    HStack(spacing: max(2, pocketH * 0.03)) {
                        Circle().fill(Color(hex: "#FF5F56") ?? .red)
                            .frame(width: max(3, pocketH * 0.05), height: max(3, pocketH * 0.05))
                        Circle().fill(Color(hex: "#FFBD2E") ?? .yellow)
                            .frame(width: max(3, pocketH * 0.05), height: max(3, pocketH * 0.05))
                        Circle().fill(Color(hex: "#27C93F") ?? .green)
                            .frame(width: max(3, pocketH * 0.05), height: max(3, pocketH * 0.05))
                    }
                    .padding(.bottom, max(1, pocketH * 0.02))

                    // Syntax line 1: keyword + function + bracket
                    HStack(spacing: 3) {
                        RoundedRectangle(cornerRadius: 1).fill(Color(hex: "#FF7B72") ?? .pink)
                            .frame(width: pocketW * 0.09, height: max(2, pocketH * 0.035))
                        RoundedRectangle(cornerRadius: 1).fill(Color(hex: "#79C0FF") ?? .blue)
                            .frame(width: pocketW * 0.16, height: max(2, pocketH * 0.035))
                        RoundedRectangle(cornerRadius: 1).fill(Color.white.opacity(0.6))
                            .frame(width: pocketW * 0.06, height: max(2, pocketH * 0.035))
                    }

                    // Syntax line 2: indent + let + var + string
                    HStack(spacing: 3) {
                        Spacer().frame(width: pocketW * 0.04)
                        RoundedRectangle(cornerRadius: 1).fill(Color(hex: "#FF7B72") ?? .pink)
                            .frame(width: pocketW * 0.07, height: max(2, pocketH * 0.035))
                        RoundedRectangle(cornerRadius: 1).fill(Color(hex: "#7EE787") ?? .green)
                            .frame(width: pocketW * 0.12, height: max(2, pocketH * 0.035))
                        RoundedRectangle(cornerRadius: 1).fill(Color(hex: "#A5D6FF") ?? .cyan)
                            .frame(width: pocketW * 0.14, height: max(2, pocketH * 0.035))
                    }

                    // Syntax line 3: indent + return + call
                    HStack(spacing: 3) {
                        Spacer().frame(width: pocketW * 0.04)
                        RoundedRectangle(cornerRadius: 1).fill(Color(hex: "#FFA657") ?? .orange)
                            .frame(width: pocketW * 0.10, height: max(2, pocketH * 0.035))
                        RoundedRectangle(cornerRadius: 1).fill(Color(hex: "#79C0FF") ?? .blue)
                            .frame(width: pocketW * 0.15, height: max(2, pocketH * 0.035))
                    }
                }
                .padding(pocketH * 0.08)
            }
            .overlay(
                RoundedRectangle(cornerRadius: max(3, pocketH * 0.04), style: .continuous)
                    .strokeBorder(Color.white.opacity(0.14), lineWidth: 0.8)
            )
            .frame(width: pocketW * 0.58, height: pocketH * 0.96)
            .rotationEffect(.degrees(-2))
            .offset(x: -pocketW * 0.03, y: -pocketH * 0.02)
            .shadow(color: .black.opacity(0.35), radius: 3, y: 1.5)
        }
    }

    // 3. Photos / Polaroids: Tilted photographic prints with white border margins
    private var photosStack: some View {
        ZStack {
            // Photo 1 (back right)
            ZStack {
                RoundedRectangle(cornerRadius: 3, style: .continuous)
                    .fill(Color.white)
                VStack(spacing: 0) {
                    LinearGradient(colors: [Color(hex: "#00C0FF") ?? .cyan, Color(hex: "#00E676") ?? .green],
                                   startPoint: .topLeading, endPoint: .bottomTrailing)
                        .clipShape(RoundedRectangle(cornerRadius: 2))
                    Spacer().frame(height: pocketH * 0.18)
                }
                .padding(pocketH * 0.04)
            }
            .frame(width: pocketW * 0.44, height: pocketH * 0.88)
            .rotationEffect(.degrees(6.5))
            .offset(x: pocketW * 0.16, y: 0)
            .shadow(color: .black.opacity(0.20), radius: 2.5, y: 1)

            // Photo 2 (front left)
            ZStack {
                RoundedRectangle(cornerRadius: 3, style: .continuous)
                    .fill(Color.white)
                VStack(spacing: 0) {
                    LinearGradient(colors: [Color(hex: "#FF2A6D") ?? .pink, Color(hex: "#FF9F1C") ?? .orange, Color(hex: "#FFD166") ?? .yellow],
                                   startPoint: .topLeading, endPoint: .bottomTrailing)
                        .clipShape(RoundedRectangle(cornerRadius: 2))
                        .overlay(
                            Image(systemName: "sun.max.fill")
                                .font(.system(size: max(6, pocketH * 0.12)))
                                .foregroundStyle(Color.white.opacity(0.85))
                                .offset(x: pocketW * 0.08, y: -pocketH * 0.06)
                        )
                    Spacer().frame(height: pocketH * 0.20)
                }
                .padding(pocketH * 0.045)
            }
            .frame(width: pocketW * 0.46, height: pocketH * 0.94)
            .rotationEffect(.degrees(-4.5))
            .offset(x: -pocketW * 0.10, y: -pocketH * 0.02)
            .shadow(color: .black.opacity(0.25), radius: 3, y: 1.5)
        }
    }

    // 4. Music / Vinyl: Vinyl record sleeve with concentric grooves & audio waveform sheet
    private var musicVinylStack: some View {
        ZStack {
            // Waveform equalizer card (left)
            ZStack {
                RoundedRectangle(cornerRadius: 4, style: .continuous)
                    .fill(Color(hex: "#1A1D24") ?? .black)
                HStack(alignment: .bottom, spacing: max(1.5, pocketW * 0.015)) {
                    ForEach([0.35, 0.70, 0.95, 0.55, 0.85, 0.60, 0.40], id: \.self) { h in
                        RoundedRectangle(cornerRadius: 1)
                            .fill(LinearGradient(colors: [.purple, .cyan], startPoint: .bottom, endPoint: .top))
                            .frame(width: max(2, pocketW * 0.028), height: pocketH * 0.45 * h)
                    }
                }
                .padding(.bottom, pocketH * 0.12)
            }
            .frame(width: pocketW * 0.44, height: pocketH * 0.90)
            .rotationEffect(.degrees(-5))
            .offset(x: -pocketW * 0.14, y: 0)
            .shadow(color: .black.opacity(0.25), radius: 2.5, y: 1)

            // Vinyl disc (right)
            ZStack {
                Circle().fill(Color(hex: "#141414") ?? .black)
                Circle().stroke(Color.white.opacity(0.12), lineWidth: 1)
                    .padding(pocketH * 0.08)
                Circle().stroke(Color.white.opacity(0.08), lineWidth: 0.8)
                    .padding(pocketH * 0.18)
                Circle().fill(Color(hex: "#FF3B30") ?? .red)
                    .frame(width: pocketH * 0.32, height: pocketH * 0.32)
                Circle().fill(Color.black)
                    .frame(width: pocketH * 0.09, height: pocketH * 0.09)
            }
            .frame(width: pocketH * 0.95, height: pocketH * 0.95)
            .rotationEffect(.degrees(12))
            .offset(x: pocketW * 0.18, y: -pocketH * 0.04)
            .shadow(color: .black.opacity(0.35), radius: 3, y: 1.5)
        }
    }
}


// MARK: - XL Folder (iOS 2x2 App Grid) View

struct XLFolderGridPlateView: View {
    let spec: IconSpec
    let refSize: CGFloat

    private var items: [XLFolderItem] {
        if spec.xlFolderPreset == .custom {
            if spec.xlFolderCustomItems.count >= 4 {
                return Array(spec.xlFolderCustomItems.prefix(4))
            }
            return spec.xlFolderPreset.items
        }
        return spec.xlFolderPreset.items
    }

    private var traySize: CGFloat {
        refSize * CGFloat(spec.xlFolderScale)
    }

    private var trayCornerRadius: CGFloat {
        traySize * 0.2237 // Apple continuous squircle
    }

    private var innerPadding: CGFloat {
        traySize * 0.08
    }

    private var tileSpacing: CGFloat {
        traySize * 0.065
    }

    private var tileSize: CGFloat {
        (traySize - (innerPadding * 2) - tileSpacing) / 2
    }

    private var tileCornerRadius: CGFloat {
        tileSize * 0.2237
    }

    var body: some View {
        ZStack {
            // Frosted Glass Squircle Tray
            if spec.xlFolderFrostedTray {
                // Background shadow
                RoundedRectangle(cornerRadius: trayCornerRadius, style: .continuous)
                    .fill(Color.black.opacity(0.20))
                    .blur(radius: traySize * 0.04)
                    .offset(y: traySize * 0.02)

                // Frosted Glass Fill
                RoundedRectangle(cornerRadius: trayCornerRadius, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.32),
                                Color.white.opacity(0.16),
                                Color.white.opacity(0.10)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                // Ambient contrast tint
                RoundedRectangle(cornerRadius: trayCornerRadius, style: .continuous)
                    .fill(Color.black.opacity(0.08))

                // Diagonal specular sheen
                RoundedRectangle(cornerRadius: trayCornerRadius, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.28),
                                Color.white.opacity(0.04),
                                Color.clear
                            ],
                            startPoint: .topLeading,
                            endPoint: UnitPoint(x: 0.65, y: 0.65)
                        )
                    )

                // Specular rim chamfer
                RoundedRectangle(cornerRadius: trayCornerRadius, style: .continuous)
                    .strokeBorder(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.80),
                                Color.white.opacity(0.25),
                                Color.white.opacity(0.55)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: max(1.0, traySize * 0.016)
                    )
            }

            // 2x2 Grid of App Tiles
            VStack(spacing: tileSpacing) {
                HStack(spacing: tileSpacing) {
                    if items.count > 0 {
                        tileView(item: items[0])
                    }
                    if items.count > 1 {
                        tileView(item: items[1])
                    }
                }
                HStack(spacing: tileSpacing) {
                    if items.count > 2 {
                        tileView(item: items[2])
                    }
                    if items.count > 3 {
                        tileView(item: items[3])
                    }
                }
            }
            .padding(innerPadding)
        }
        .frame(width: traySize, height: traySize)
    }

    @ViewBuilder
    private func tileView(item: XLFolderItem) -> some View {
        let bgStart = Color(hex: item.bgGradientStart) ?? .blue
        let bgEnd = Color(hex: item.bgGradientEnd) ?? .indigo
        let iconCol = Color(hex: item.iconColorHex) ?? .white

        ZStack {
            // Drop shadow for tactile squircle depth
            RoundedRectangle(cornerRadius: tileCornerRadius, style: .continuous)
                .fill(Color.black.opacity(0.30))
                .blur(radius: tileSize * 0.08)
                .offset(y: tileSize * 0.04)

            // Vibrant Linear Gradient Background
            RoundedRectangle(cornerRadius: tileCornerRadius, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [bgStart, bgEnd],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            // Specular Gloss Highlight (top sheen)
            RoundedRectangle(cornerRadius: tileCornerRadius, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.38),
                            Color.white.opacity(0.06),
                            Color.clear
                        ],
                        startPoint: .top,
                        endPoint: UnitPoint(x: 0.5, y: 0.54)
                    )
                )

            // Subtle perimeter border
            RoundedRectangle(cornerRadius: tileCornerRadius, style: .continuous)
                .strokeBorder(Color.white.opacity(0.24), lineWidth: max(0.5, tileSize * 0.022))

            // Central Icon Symbol
            Image(systemName: item.symbol)
                .resizable()
                .scaledToFit()
                .frame(width: tileSize * 0.50, height: tileSize * 0.50)
                .foregroundStyle(iconCol)
                .shadow(color: Color.black.opacity(0.35), radius: max(0.5, tileSize * 0.03), y: max(0.5, tileSize * 0.02))
        }
        .frame(width: tileSize, height: tileSize)
    }
}
