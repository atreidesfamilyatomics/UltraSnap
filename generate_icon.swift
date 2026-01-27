#!/usr/bin/env swift
// Generate UltraSnap app icon

import Cocoa

// Icon sizes needed for macOS app icon
let sizes: [(size: Int, scale: Int, name: String)] = [
    (16, 1, "icon_16x16.png"),
    (16, 2, "icon_16x16@2x.png"),
    (32, 1, "icon_32x32.png"),
    (32, 2, "icon_32x32@2x.png"),
    (128, 1, "icon_128x128.png"),
    (128, 2, "icon_128x128@2x.png"),
    (256, 1, "icon_256x256.png"),
    (256, 2, "icon_256x256@2x.png"),
    (512, 1, "icon_512x512.png"),
    (512, 2, "icon_512x512@2x.png")
]

func createIcon(size: Int, scale: Int) -> NSImage? {
    let pixelSize = size * scale
    let image = NSImage(size: NSSize(width: pixelSize, height: pixelSize))

    image.lockFocus()

    // Background: rounded rectangle with gradient
    let bounds = NSRect(x: 0, y: 0, width: pixelSize, height: pixelSize)
    let cornerRadius = CGFloat(pixelSize) * 0.22
    let path = NSBezierPath(roundedRect: bounds.insetBy(dx: 1, dy: 1), xRadius: cornerRadius, yRadius: cornerRadius)

    // Gradient background (dark blue to lighter blue)
    let gradient = NSGradient(starting: NSColor(red: 0.1, green: 0.15, blue: 0.35, alpha: 1.0),
                              ending: NSColor(red: 0.25, green: 0.35, blue: 0.55, alpha: 1.0))
    gradient?.draw(in: path, angle: -90)

    // Draw three rectangles representing window thirds
    let margin = CGFloat(pixelSize) * 0.18
    let spacing = CGFloat(pixelSize) * 0.05
    let rectHeight = CGFloat(pixelSize) * 0.52
    let rectWidth = (CGFloat(pixelSize) - 2 * margin - 2 * spacing) / 3
    let rectY = (CGFloat(pixelSize) - rectHeight) / 2

    // Left third
    NSColor.white.withAlphaComponent(0.85).setFill()
    let leftRect = NSRect(x: margin, y: rectY, width: rectWidth, height: rectHeight)
    let leftPath = NSBezierPath(roundedRect: leftRect, xRadius: CGFloat(pixelSize) * 0.03, yRadius: CGFloat(pixelSize) * 0.03)
    leftPath.fill()

    // Center third (slightly taller to show "focus")
    NSColor.white.withAlphaComponent(0.95).setFill()
    let centerRect = NSRect(x: margin + rectWidth + spacing, y: rectY - CGFloat(pixelSize) * 0.04,
                           width: rectWidth, height: rectHeight + CGFloat(pixelSize) * 0.08)
    let centerPath = NSBezierPath(roundedRect: centerRect, xRadius: CGFloat(pixelSize) * 0.03, yRadius: CGFloat(pixelSize) * 0.03)
    centerPath.fill()

    // Right third
    NSColor.white.withAlphaComponent(0.85).setFill()
    let rightRect = NSRect(x: margin + 2 * rectWidth + 2 * spacing, y: rectY, width: rectWidth, height: rectHeight)
    let rightPath = NSBezierPath(roundedRect: rightRect, xRadius: CGFloat(pixelSize) * 0.03, yRadius: CGFloat(pixelSize) * 0.03)
    rightPath.fill()

    image.unlockFocus()

    return image
}

func saveImage(_ image: NSImage, to url: URL) -> Bool {
    guard let tiffData = image.tiffRepresentation,
          let bitmap = NSBitmapImageRep(data: tiffData),
          let pngData = bitmap.representation(using: .png, properties: [:]) else {
        return false
    }

    do {
        try pngData.write(to: url)
        return true
    } catch {
        print("Error saving \(url.path): \(error)")
        return false
    }
}

// Use current working directory
let cwd = FileManager.default.currentDirectoryPath
let iconsetURL = URL(fileURLWithPath: cwd).appendingPathComponent("AppIcon.iconset")

// Create directory
try? FileManager.default.createDirectory(at: iconsetURL, withIntermediateDirectories: true)

print("Generating icons in \(iconsetURL.path)...")

for (size, scale, name) in sizes {
    if let icon = createIcon(size: size, scale: scale) {
        let outputURL = iconsetURL.appendingPathComponent(name)
        if saveImage(icon, to: outputURL) {
            print("✓ Generated \(name)")
        } else {
            print("✗ Failed to generate \(name)")
        }
    }
}

print("\nDone! Now run:")
print("  iconutil -c icns AppIcon.iconset")
