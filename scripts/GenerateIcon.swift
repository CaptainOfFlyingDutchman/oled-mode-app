import AppKit
import CoreText
import Foundation

let sizes: [(name: String, px: Int)] = [
    ("icon_16x16", 16),
    ("icon_16x16@2x", 32),
    ("icon_32x32", 32),
    ("icon_32x32@2x", 64),
    ("icon_128x128", 128),
    ("icon_128x128@2x", 256),
    ("icon_256x256", 256),
    ("icon_256x256@2x", 512),
    ("icon_512x512", 512),
    ("icon_512x512@2x", 1024)
]

private let chassis = NSColor(calibratedRed: 0.10, green: 0.11, blue: 0.14, alpha: 1)
private let chassisDeep = NSColor(calibratedRed: 0.07, green: 0.08, blue: 0.10, alpha: 1)
private let chassisHi = NSColor(calibratedRed: 0.18, green: 0.19, blue: 0.23, alpha: 1)
private let well = NSColor(calibratedRed: 0.045, green: 0.05, blue: 0.06, alpha: 1)
private let plateTop = NSColor(calibratedRed: 0.16, green: 0.17, blue: 0.21, alpha: 1)
private let plateBot = NSColor(calibratedRed: 0.09, green: 0.10, blue: 0.13, alpha: 1)
private let amber = NSColor(calibratedRed: 1.00, green: 0.69, blue: 0.13, alpha: 1)
private let amberHot = NSColor(calibratedRed: 1.00, green: 0.86, blue: 0.42, alpha: 1)
private let amberDim = NSColor(calibratedRed: 0.42, green: 0.26, blue: 0.04, alpha: 1)
private let ink = NSColor(calibratedRed: 0.07, green: 0.08, blue: 0.10, alpha: 1)

func roundedRect(_ rect: NSRect, radius: CGFloat) -> NSBezierPath {
    NSBezierPath(roundedRect: rect, xRadius: min(radius, rect.width / 2), yRadius: min(radius, rect.height / 2))
}

func fillGradient(path: NSBezierPath, top: NSColor, bottom: NSColor) {
    guard let gradient = NSGradient(starting: top, ending: bottom) else { return }
    gradient.draw(in: path, angle: 270)
}

func drawIcon(pixelSize: Int) -> NSBitmapImageRep {
    let s = CGFloat(pixelSize)
    guard let rep = NSBitmapImageRep(
        bitmapDataPlanes: nil,
        pixelsWide: pixelSize,
        pixelsHigh: pixelSize,
        bitsPerSample: 8,
        samplesPerPixel: 4,
        hasAlpha: true,
        isPlanar: false,
        colorSpaceName: .calibratedRGB,
        bytesPerRow: 0,
        bitsPerPixel: 0
    ) else {
        fatalError("Could not allocate bitmap")
    }
    rep.size = NSSize(width: s, height: s)

    NSGraphicsContext.saveGraphicsState()
    guard let ctx = NSGraphicsContext(bitmapImageRep: rep) else {
        fatalError("Could not create graphics context")
    }
    ctx.shouldAntialias = true
    ctx.imageInterpolation = .high
    NSGraphicsContext.current = ctx
    ctx.cgContext.setFillColor(NSColor.clear.cgColor)
    ctx.cgContext.fill(CGRect(x: 0, y: 0, width: s, height: s))

    let showText = pixelSize >= 128
    let simplify = pixelSize <= 64

    let inset: CGFloat = simplify ? max(0.5, s * 0.04) : s * 0.045
    let chassisRect = NSRect(x: inset, y: inset, width: s - inset * 2, height: s - inset * 2)
    let chassisRadius = s * (simplify ? 0.22 : 0.20)

    // Drop shadow under the panel
    if pixelSize >= 64 {
        let shadow = roundedRect(chassisRect.offsetBy(dx: 0, dy: -s * 0.012), radius: chassisRadius)
        NSColor.black.withAlphaComponent(0.45).setFill()
        shadow.fill()
    }

    let chassisPath = roundedRect(chassisRect, radius: chassisRadius)
    fillGradient(path: chassisPath, top: chassisHi, bottom: chassisDeep)

    // Outer rim highlight
    chassisPath.lineWidth = max(1, s * 0.012)
    NSColor.white.withAlphaComponent(pixelSize >= 128 ? 0.16 : 0.10).setStroke()
    chassisPath.stroke()

    if !simplify {
        let wellInset = s * 0.085
        let wellRect = chassisRect.insetBy(dx: wellInset, dy: wellInset)
        let wellPath = roundedRect(wellRect, radius: chassisRadius * 0.72)
        fillGradient(path: wellPath, top: well, bottom: chassisDeep)
        NSColor.black.withAlphaComponent(0.55).setStroke()
        wellPath.lineWidth = max(1, s * 0.01)
        wellPath.stroke()

        let plateInset = s * 0.035
        let plateRect = wellRect.insetBy(dx: plateInset, dy: plateInset)
        let platePath = roundedRect(plateRect, radius: chassisRadius * 0.62)
        fillGradient(path: platePath, top: plateTop, bottom: plateBot)
        NSColor.white.withAlphaComponent(0.08).setStroke()
        platePath.lineWidth = max(0.8, s * 0.006)
        platePath.stroke()
    }

    // LED
    let ledD: CGFloat
    if pixelSize <= 16 {
        ledD = 2.5
    } else if pixelSize <= 32 {
        ledD = max(4, s * 0.13)
    } else if pixelSize <= 64 {
        ledD = s * 0.09
    } else {
        ledD = s * 0.055
    }

    let pillHeight: CGFloat
    let pillWidth: CGFloat
    if pixelSize <= 16 {
        pillHeight = 4.5
        pillWidth = 11
    } else if pixelSize <= 32 {
        pillHeight = s * 0.30
        pillWidth = s * 0.72
    } else if pixelSize <= 64 {
        pillHeight = s * 0.28
        pillWidth = s * 0.68
    } else {
        pillHeight = s * 0.26
        pillWidth = s * 0.62
    }

    let pillY: CGFloat
    if pixelSize <= 16 {
        pillY = s * 0.28
    } else if simplify {
        pillY = (s - pillHeight) / 2 - s * 0.04
    } else {
        pillY = (s - pillHeight) / 2 - s * 0.03
    }

    let pillRect = NSRect(
        x: (s - pillWidth) / 2,
        y: pillY,
        width: pillWidth,
        height: pillHeight
    )

    let ledY = pillRect.maxY + (pixelSize <= 16 ? 1.2 : (simplify ? s * 0.06 : s * 0.055))
    let ledRect = NSRect(
        x: (s - ledD) / 2,
        y: min(ledY, chassisRect.maxY - ledD - s * 0.06),
        width: ledD,
        height: ledD
    )

    // LED glow
    if pixelSize >= 32 {
        let glowPad = ledD * (pixelSize >= 128 ? 1.6 : 1.1)
        let glowRect = ledRect.insetBy(dx: -glowPad, dy: -glowPad)
        let glow = NSBezierPath(ovalIn: glowRect)
        amber.withAlphaComponent(pixelSize >= 128 ? 0.28 : 0.35).setFill()
        glow.fill()
    }

    let ledWell = NSBezierPath(ovalIn: ledRect.insetBy(dx: -ledD * 0.12, dy: -ledD * 0.12))
    well.setFill()
    ledWell.fill()

    let led = NSBezierPath(ovalIn: ledRect)
    fillGradient(path: led, top: amberHot, bottom: amber)
    if pixelSize >= 64 {
        let spark = NSBezierPath(ovalIn: NSRect(
            x: ledRect.midX - ledD * 0.18,
            y: ledRect.maxY - ledD * 0.42,
            width: ledD * 0.32,
            height: ledD * 0.22
        ))
        NSColor.white.withAlphaComponent(0.75).setFill()
        spark.fill()
    }

    // Button glow
    if pixelSize >= 32 {
        let glowRect = pillRect.insetBy(dx: -s * 0.04, dy: -s * 0.035)
        let glowPath = roundedRect(glowRect, radius: glowRect.height / 2)
        amber.withAlphaComponent(pixelSize >= 128 ? 0.32 : 0.40).setFill()
        glowPath.fill()
    }

    let pillPath = roundedRect(pillRect, radius: pillRect.height / 2)
    fillGradient(path: pillPath, top: amberHot, bottom: amber)

    // Inner highlight on the pill
    let hiRect = pillRect.insetBy(dx: max(1, s * 0.012), dy: max(1, s * 0.018))
    let hi = roundedRect(
        NSRect(x: hiRect.minX, y: hiRect.midY, width: hiRect.width, height: hiRect.height / 2),
        radius: hiRect.height / 3
    )
    NSColor.white.withAlphaComponent(pixelSize >= 128 ? 0.18 : 0.12).setFill()
    hi.fill()

    if pixelSize >= 64 {
        pillPath.lineWidth = max(1, s * 0.01)
        amberDim.withAlphaComponent(0.55).setStroke()
        pillPath.stroke()
    }

    if showText {
        let fontSize = pillHeight * 0.28
        let font = NSFont.monospacedSystemFont(ofSize: fontSize, weight: .heavy)
        let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = .center
        let attrs: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: ink,
            .paragraphStyle: paragraph,
            .kern: fontSize * 0.12
        ]
        let lineH = fontSize * 1.15
        let blockH = lineH * 2
        let textOriginY = pillRect.midY - blockH / 2 + fontSize * 0.08
        let oled = NSAttributedString(string: "OLED", attributes: attrs)
        let mode = NSAttributedString(string: "MODE", attributes: attrs)
        oled.draw(in: NSRect(x: pillRect.minX, y: textOriginY + lineH, width: pillRect.width, height: lineH))
        mode.draw(in: NSRect(x: pillRect.minX, y: textOriginY, width: pillRect.width, height: lineH))
    }

    NSGraphicsContext.restoreGraphicsState()
    return rep
}

let outputDir = CommandLine.arguments.count > 1
    ? CommandLine.arguments[1]
    : FileManager.default.currentDirectoryPath

let scriptDir = URL(fileURLWithPath: #filePath).deletingLastPathComponent()
let masterURL = scriptDir.appendingPathComponent("oled-mode-icon-1024.png")
let master = NSImage(contentsOf: masterURL)

for item in sizes {
    let png: Data
    if item.px >= 128, let master, let scaled = rasterize(master, pixelSize: item.px) {
        png = scaled
        print("Master \(item.name)")
    } else {
        guard let encoded = drawIcon(pixelSize: item.px).representation(using: .png, properties: [:]) else {
            fputs("Failed to encode \(item.name)\n", stderr)
            exit(1)
        }
        png = encoded
    }
    let url = URL(fileURLWithPath: outputDir).appendingPathComponent("\(item.name).png")
    try png.write(to: url)
    print("Wrote \(url.path)")
}

func rasterize(_ image: NSImage, pixelSize: Int) -> Data? {
    guard let rep = NSBitmapImageRep(
        bitmapDataPlanes: nil,
        pixelsWide: pixelSize,
        pixelsHigh: pixelSize,
        bitsPerSample: 8,
        samplesPerPixel: 4,
        hasAlpha: true,
        isPlanar: false,
        colorSpaceName: .calibratedRGB,
        bytesPerRow: 0,
        bitsPerPixel: 0
    ) else { return nil }
    rep.size = NSSize(width: pixelSize, height: pixelSize)
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
    NSGraphicsContext.current?.imageInterpolation = .high
    image.draw(
        in: NSRect(x: 0, y: 0, width: pixelSize, height: pixelSize),
        from: .zero,
        operation: .copy,
        fraction: 1
    )
    NSGraphicsContext.restoreGraphicsState()
    return rep.representation(using: .png, properties: [:])
}
