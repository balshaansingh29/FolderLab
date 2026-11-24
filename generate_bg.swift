import AppKit
import Foundation

func createBackground(outputPath: String) {
    let width = 660
    let height = 440
    let image = NSImage(size: NSSize(width: width, height: height))
    image.lockFocus()

    guard let ctx = NSGraphicsContext.current?.cgContext else {
        print("Failed to get graphics context")
        exit(1)
    }

    // 1. Sleek Modern Dark Gradient Canvas
    let colorSpace = CGColorSpaceCreateDeviceRGB()
    let startColor = CGColor(srgbRed: 0.08, green: 0.10, blue: 0.16, alpha: 1.0)
    let endColor = CGColor(srgbRed: 0.04, green: 0.05, blue: 0.08, alpha: 1.0)
    let colors = [startColor, endColor] as CFArray
    let gradient = CGGradient(colorsSpace: colorSpace, colors: colors, locations: [0.0, 1.0])!
    ctx.drawLinearGradient(gradient, start: CGPoint(x: 0, y: height), end: CGPoint(x: width, y: 0), options: [])

    // Subtle Outer Border Frame
    ctx.setStrokeColor(CGColor(srgbRed: 1.0, green: 1.0, blue: 1.0, alpha: 0.10))
    ctx.setLineWidth(1.0)
    ctx.stroke(CGRect(x: 0.5, y: 0.5, width: Double(width) - 1.0, height: Double(height) - 1.0))

    // 2. Ambient Colorful Under-Glows
    // Left Glow (Purple/Cyan under FolderLab.app at x: 180, y: 220)
    let leftGlow = [
        CGColor(srgbRed: 0.55, green: 0.35, blue: 0.95, alpha: 0.32),
        CGColor(srgbRed: 0.20, green: 0.60, blue: 0.95, alpha: 0.12),
        CGColor(srgbRed: 0.10, green: 0.50, blue: 0.90, alpha: 0.0)
    ] as CFArray
    let leftGrad = CGGradient(colorsSpace: colorSpace, colors: leftGlow, locations: [0.0, 0.5, 1.0])!
    ctx.drawRadialGradient(leftGrad, startCenter: CGPoint(x: 180, y: 220), startRadius: 0, endCenter: CGPoint(x: 180, y: 220), endRadius: 130, options: [])

    // Right Glow (Emerald/Cyan under /Applications at x: 480, y: 220)
    let rightGlow = [
        CGColor(srgbRed: 0.22, green: 0.85, blue: 0.65, alpha: 0.30),
        CGColor(srgbRed: 0.15, green: 0.70, blue: 0.85, alpha: 0.10),
        CGColor(srgbRed: 0.10, green: 0.60, blue: 0.80, alpha: 0.0)
    ] as CFArray
    let rightGrad = CGGradient(colorsSpace: colorSpace, colors: rightGlow, locations: [0.0, 0.5, 1.0])!
    ctx.drawRadialGradient(rightGrad, startCenter: CGPoint(x: 480, y: 220), startRadius: 0, endCenter: CGPoint(x: 480, y: 220), endRadius: 130, options: [])

    // 3. Dynamic Center Drag-and-Drop Arc & Arrow
    ctx.saveGState()
    ctx.setStrokeColor(CGColor(srgbRed: 0.40, green: 0.75, blue: 1.0, alpha: 0.85))
    ctx.setLineWidth(3.0)
    ctx.setLineCap(.round)
    ctx.setLineJoin(.round)

    let arrowPath = CGMutablePath()
    arrowPath.move(to: CGPoint(x: 275, y: 220))
    arrowPath.addCurve(to: CGPoint(x: 385, y: 220), control1: CGPoint(x: 310, y: 250), control2: CGPoint(x: 350, y: 250))
    ctx.addPath(arrowPath)
    ctx.strokePath()

    // Arrow Head
    let headPath = CGMutablePath()
    headPath.move(to: CGPoint(x: 370, y: 232))
    headPath.addLine(to: CGPoint(x: 387, y: 220))
    headPath.addLine(to: CGPoint(x: 370, y: 208))
    ctx.addPath(headPath)
    ctx.strokePath()
    ctx.restoreGState()

    // 4. Branded Header & Personality Typography
    let titleAttrs: [NSAttributedString.Key: Any] = [
        .font: NSFont.systemFont(ofSize: 24, weight: .heavy),
        .foregroundColor: NSColor.white
    ]
    let titleStr = "FolderLab" as NSString
    let titleSize = titleStr.size(withAttributes: titleAttrs)
    titleStr.draw(at: NSPoint(x: (CGFloat(width) - titleSize.width) / 2.0, y: CGFloat(height) - 58), withAttributes: titleAttrs)

    let subtitleAttrs: [NSAttributedString.Key: Any] = [
        .font: NSFont.systemFont(ofSize: 12.5, weight: .semibold),
        .foregroundColor: NSColor(srgbRed: 0.65, green: 0.75, blue: 0.90, alpha: 0.90)
    ]
    let subtitleStr = "Drop into Applications to give your Mac folders instant personality ✨" as NSString
    let subtitleSize = subtitleStr.size(withAttributes: subtitleAttrs)
    subtitleStr.draw(at: NSPoint(x: (CGFloat(width) - subtitleSize.width) / 2.0, y: CGFloat(height) - 84), withAttributes: subtitleAttrs)

    // Step Pill Label in Center
    let stepAttrs: [NSAttributedString.Key: Any] = [
        .font: NSFont.systemFont(ofSize: 10, weight: .bold),
        .foregroundColor: NSColor(srgbRed: 0.40, green: 0.80, blue: 1.0, alpha: 0.95)
    ]
    let stepStr = "DRAG & INSTALL" as NSString
    let stepSize = stepStr.size(withAttributes: stepAttrs)
    stepStr.draw(at: NSPoint(x: (CGFloat(width) - stepSize.width) / 2.0, y: 195), withAttributes: stepAttrs)

    // Slot labels below icons
    let slotAttrs: [NSAttributedString.Key: Any] = [
        .font: NSFont.systemFont(ofSize: 11, weight: .semibold),
        .foregroundColor: NSColor(white: 0.90, alpha: 0.95)
    ]
    let leftLabel = "FolderLab.app" as NSString
    let leftSize = leftLabel.size(withAttributes: slotAttrs)
    leftLabel.draw(at: NSPoint(x: 180.0 - leftSize.width / 2.0, y: 105), withAttributes: slotAttrs)

    let rightLabel = "Applications" as NSString
    let rightSize = rightLabel.size(withAttributes: slotAttrs)
    rightLabel.draw(at: NSPoint(x: 480.0 - rightSize.width / 2.0, y: 105), withAttributes: slotAttrs)

    // Bottom Personality Tagline
    let tipAttrs: [NSAttributedString.Key: Any] = [
        .font: NSFont.systemFont(ofSize: 10, weight: .medium),
        .foregroundColor: NSColor(white: 0.55, alpha: 1.0)
    ]
    let tipStr = "Designed with love for macOS • 100% Native SwiftUI & AppKit Studio 🎨" as NSString
    let tipSize = tipStr.size(withAttributes: tipAttrs)
    tipStr.draw(at: NSPoint(x: (CGFloat(width) - tipSize.width) / 2.0, y: 22), withAttributes: tipAttrs)

    image.unlockFocus()

    guard let tiffData = image.tiffRepresentation,
          let bitmap = NSBitmapImageRep(data: tiffData),
          let pngData = bitmap.representation(using: .png, properties: [:]) else {
        print("Failed to encode PNG")
        exit(1)
    }

    do {
        try pngData.write(to: URL(fileURLWithPath: outputPath))
        print("Background saved to \(outputPath)")
    } catch {
        print("Failed to write image: \(error)")
        exit(1)
    }
}

let args = CommandLine.arguments
if args.count > 1 {
    createBackground(outputPath: args[1])
} else {
    createBackground(outputPath: "background.png")
}
