import AppKit

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

func drawIcon(size: CGFloat) -> NSImage {
    let image = NSImage(size: NSSize(width: size, height: size))
    image.lockFocus()

    let bounds = NSRect(x: 0, y: 0, width: size, height: size)
    let radius = size * 0.22
    let path = NSBezierPath(roundedRect: bounds.insetBy(dx: size * 0.06, dy: size * 0.06), xRadius: radius, yRadius: radius)

    NSColor(calibratedRed: 0.08, green: 0.09, blue: 0.12, alpha: 1).setFill()
    path.fill()

    NSColor(calibratedRed: 1.0, green: 0.69, blue: 0.13, alpha: 0.85).setStroke()
    path.lineWidth = max(1.5, size * 0.035)
    path.stroke()

    let pixel = size * 0.16
    let pixelRect = NSRect(
        x: (size - pixel) / 2,
        y: (size - pixel) / 2 + size * 0.04,
        width: pixel,
        height: pixel
    )
    let pixelPath = NSBezierPath(roundedRect: pixelRect, xRadius: pixel * 0.18, yRadius: pixel * 0.18)
    NSColor(calibratedRed: 1.0, green: 0.78, blue: 0.22, alpha: 1).setFill()
    pixelPath.fill()

    let glow = NSBezierPath(ovalIn: pixelRect.insetBy(dx: -pixel * 0.55, dy: -pixel * 0.55))
    NSColor(calibratedRed: 1.0, green: 0.69, blue: 0.13, alpha: 0.22).setFill()
    glow.fill()

    image.unlockFocus()
    return image
}

let outputDir = CommandLine.arguments.count > 1
    ? CommandLine.arguments[1]
    : FileManager.default.currentDirectoryPath

for item in sizes {
    let image = drawIcon(size: CGFloat(item.px))
    guard let tiff = image.tiffRepresentation,
          let bitmap = NSBitmapImageRep(data: tiff),
          let png = bitmap.representation(using: .png, properties: [:]) else {
        fputs("Failed to encode \(item.name)\n", stderr)
        exit(1)
    }
    let url = URL(fileURLWithPath: outputDir).appendingPathComponent("\(item.name).png")
    try png.write(to: url)
    print("Wrote \(url.path)")
}
