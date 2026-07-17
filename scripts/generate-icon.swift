import AppKit
import Foundation

let output = CommandLine.arguments.dropFirst().first ?? "dist/AppIcon.icns"
let outputURL = URL(fileURLWithPath: output)
let iconsetURL = outputURL.deletingPathExtension().appendingPathExtension("iconset")
try? FileManager.default.removeItem(at: iconsetURL)
try FileManager.default.createDirectory(at: iconsetURL, withIntermediateDirectories: true)

let sizes: [(String, CGFloat)] = [
    ("icon_16x16.png", 16),
    ("icon_16x16@2x.png", 32),
    ("icon_32x32.png", 32),
    ("icon_32x32@2x.png", 64),
    ("icon_128x128.png", 128),
    ("icon_128x128@2x.png", 256),
    ("icon_256x256.png", 256),
    ("icon_256x256@2x.png", 512),
    ("icon_512x512.png", 512),
    ("icon_512x512@2x.png", 1024)
]

for (name, size) in sizes {
    let image = NSImage(size: NSSize(width: size, height: size))
    image.lockFocus()
    drawIcon(in: CGRect(x: 0, y: 0, width: size, height: size))
    image.unlockFocus()

    guard let tiff = image.tiffRepresentation,
          let bitmap = NSBitmapImageRep(data: tiff),
          let png = bitmap.representation(using: .png, properties: [:])
    else {
        fatalError("Failed to render \(name)")
    }
    try png.write(to: iconsetURL.appendingPathComponent(name))
}

let process = Process()
process.executableURL = URL(fileURLWithPath: "/usr/bin/iconutil")
process.arguments = ["-c", "icns", iconsetURL.path, "-o", outputURL.path]
try process.run()
process.waitUntilExit()
guard process.terminationStatus == 0 else {
    fatalError("iconutil failed")
}

func drawIcon(in rect: CGRect) {
    let scale = rect.width / 1024
    let bounds = rect

    NSColor.clear.setFill()
    bounds.fill()

    let shadow = NSShadow()
    shadow.shadowColor = NSColor.black.withAlphaComponent(0.34)
    shadow.shadowBlurRadius = 48 * scale
    shadow.shadowOffset = NSSize(width: 0, height: -22 * scale)

    let orbRect = bounds.insetBy(dx: 110 * scale, dy: 110 * scale)
    let orbPath = NSBezierPath(ovalIn: orbRect)
    NSGraphicsContext.current?.saveGraphicsState()
    shadow.set()
    NSGradient(colors: [
        NSColor(calibratedRed: 0.18, green: 0.23, blue: 0.3, alpha: 1),
        NSColor(calibratedRed: 0.04, green: 0.06, blue: 0.1, alpha: 1)
    ])!.draw(in: orbPath, angle: -45)
    NSGraphicsContext.current?.restoreGraphicsState()

    let waterRect = orbRect.insetBy(dx: 58 * scale, dy: 58 * scale)
    let water = NSBezierPath()
    let baseY = waterRect.minY + waterRect.height * 0.42
    water.move(to: CGPoint(x: waterRect.minX, y: waterRect.minY))
    water.line(to: CGPoint(x: waterRect.minX, y: baseY))
    water.curve(
        to: CGPoint(x: waterRect.maxX, y: baseY),
        controlPoint1: CGPoint(x: waterRect.minX + waterRect.width * 0.28, y: baseY + 64 * scale),
        controlPoint2: CGPoint(x: waterRect.minX + waterRect.width * 0.72, y: baseY - 54 * scale)
    )
    water.line(to: CGPoint(x: waterRect.maxX, y: waterRect.minY))
    water.close()

    NSGraphicsContext.current?.saveGraphicsState()
    orbPath.addClip()
    NSGradient(colors: [
        NSColor(calibratedRed: 0.04, green: 0.82, blue: 0.94, alpha: 0.88),
        NSColor(calibratedRed: 0.02, green: 0.32, blue: 0.48, alpha: 0.72)
    ])!.draw(in: water, angle: 90)
    NSGraphicsContext.current?.restoreGraphicsState()

    NSColor.white.withAlphaComponent(0.72).setStroke()
    let ring = NSBezierPath(ovalIn: orbRect.insetBy(dx: 30 * scale, dy: 30 * scale))
    ring.lineWidth = 22 * scale
    ring.stroke()

    NSColor(calibratedRed: 0.05, green: 0.78, blue: 0.9, alpha: 0.92).setStroke()
    let progress = NSBezierPath()
    progress.appendArc(
        withCenter: CGPoint(x: orbRect.midX, y: orbRect.midY),
        radius: orbRect.width * 0.44,
        startAngle: 120,
        endAngle: 360,
        clockwise: false
    )
    progress.lineWidth = 42 * scale
    progress.lineCapStyle = .round
    progress.stroke()

    NSColor.white.withAlphaComponent(0.38).setFill()
    NSBezierPath(ovalIn: CGRect(x: orbRect.minX + 170 * scale, y: orbRect.maxY - 255 * scale, width: 230 * scale, height: 82 * scale)).fill()

    let paragraph = NSMutableParagraphStyle()
    paragraph.alignment = .center
    let attrs: [NSAttributedString.Key: Any] = [
        .font: NSFont.systemFont(ofSize: 168 * scale, weight: .heavy),
        .foregroundColor: NSColor.white,
        .paragraphStyle: paragraph
    ]
    NSString(string: "Q").draw(in: CGRect(x: orbRect.minX, y: orbRect.midY - 120 * scale, width: orbRect.width, height: 210 * scale), withAttributes: attrs)
}
