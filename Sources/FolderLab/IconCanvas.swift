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
        spec.base == .folder ? folderShift + folderH * 0.10 : 0
    }

    // MARK: Fills

    private func gradient(_ a: Color, _ b: Color) -> AnyShapeStyle {
        guard spec.useGradient else { return AnyShapeStyle(a) }
        let rad = spec.gradientAngle * .pi / 180
        let dx = cos(rad), dy = sin(rad)
        return AnyShapeStyle(LinearGradient(
            colors: [a, b],
            startPoint: UnitPoint(x: 0.5 - dx / 2, y: 0.5 - dy / 2),
            endPoint: UnitPoint(x: 0.5 + dx / 2, y: 0.5 + dy / 2)))
    }

    private var glyphFill: AnyShapeStyle {
        spec.glyphGradient
            ? AnyShapeStyle(LinearGradient(colors: [spec.glyphColor, spec.glyphColor2],
                                           startPoint: .top, endPoint: .bottom))
            : AnyShapeStyle(spec.glyphColor)
    }

    // MARK: Body

    var body: some View {
        ZStack {
            switch spec.base {
            case .tile:   tile
            case .folder: folder
            case .none:   EmptyView()
            }
            glyph
                .offset(y: glyphBaseOffset + ref * spec.glyphYOffset)
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

            // Main base fill (with Liquid Glass support)
            if spec.liquidGlass {
                tileShape
                    .fill(gradient(spec.color1.opacity(spec.glassOpacity), spec.color2.opacity(min(1.0, spec.glassOpacity + 0.15))))
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
                    .fill(gradient(spec.color1, spec.color2))
                    .frame(width: tileSide, height: tileSide)
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
                    .fill(gradient(spec.color1.opacity(spec.glassOpacity * 0.75), spec.color2.opacity(spec.glassOpacity * 0.90)))
            } else {
                FolderBackShape()
                    .fill(gradient(spec.color1.darker(0.25), spec.color2.darker(0.35)))
            }

            // 2. Interior crease shadow between back tab and front flap
            RoundedRectangle(cornerRadius: rad, style: .continuous)
                .fill(Color.black.opacity(0.18))
                .frame(width: folderW * 0.98, height: frontH)
                .offset(y: -folderH * 0.015)
                .blur(radius: folderH * 0.012)

            // 3. Front flap
            if spec.liquidGlass {
                RoundedRectangle(cornerRadius: rad, style: .continuous)
                    .fill(gradient(spec.color1.opacity(spec.glassOpacity), spec.color2.opacity(min(1.0, spec.glassOpacity + 0.15))))
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
                    .fill(gradient(spec.color1, spec.color2))
                    .frame(width: folderW, height: frontH)
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
        if spec.glyphShadow {
            if spec.base == .folder {
                g
                    .shadow(color: .white.opacity(0.35), radius: 0.5, x: 0, y: 1.0)
                    .shadow(color: .black.opacity(0.45), radius: ref * 0.018, x: 0, y: ref * 0.010)
                    .shadow(color: .black.opacity(0.25), radius: ref * 0.005, x: 0, y: -0.5)
            } else {
                g
                    .shadow(color: .black.opacity(0.40), radius: ref * 0.022, x: 0, y: ref * 0.014)
                    .shadow(color: .black.opacity(0.20), radius: ref * 0.006, x: 0, y: ref * 0.003)
            }
        } else {
            g
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
                }
            }
            .frame(width: ref * spec.glyphScale, height: ref * spec.glyphScale)
        case .text:
            Text(spec.text)
                .font(.system(size: ref * spec.glyphScale, weight: .bold, design: .rounded))
                .foregroundStyle(glyphFill)
                .lineLimit(1)
                .minimumScaleFactor(0.2)
                .frame(width: ref * 0.9, height: ref * 0.9)
        case .customImage:
            if let data = spec.customImageData, let nsImg = NSImage(data: data) {
                if spec.customImageTinted {
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
