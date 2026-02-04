import Cocoa

class ZonePreviewView: NSView {

    private var zones: [CGRect] = []
    private var aspectRatio: CGFloat = 16.0 / 9.0

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        wantsLayer = true
        layer?.backgroundColor = NSColor.controlBackgroundColor.cgColor
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        wantsLayer = true
        layer?.backgroundColor = NSColor.controlBackgroundColor.cgColor
    }

    func updateZones(for preset: ZonePreset, on screen: NSScreen) {
        // Calculate zones
        let screenFrame = screen.visibleFrame
        zones = DefaultLayouts.zones(for: preset, on: screen)

        // Store aspect ratio for scaling
        aspectRatio = screenFrame.width / screenFrame.height

        setNeedsDisplay(bounds)
    }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        // Draw background
        NSColor.controlBackgroundColor.setFill()
        bounds.fill()

        // Handle "Off" preset (empty zones)
        if zones.isEmpty {
            drawDisabledState()
            return
        }

        // Calculate preview area (maintain aspect ratio)
        let padding: CGFloat = 20
        let availableWidth = bounds.width - (padding * 2)
        let availableHeight = bounds.height - (padding * 2)

        var previewWidth = availableWidth
        var previewHeight = previewWidth / aspectRatio

        if previewHeight > availableHeight {
            previewHeight = availableHeight
            previewWidth = previewHeight * aspectRatio
        }

        let previewX = (bounds.width - previewWidth) / 2
        let previewY = (bounds.height - previewHeight) / 2
        let previewRect = CGRect(x: previewX, y: previewY, width: previewWidth, height: previewHeight)

        // Draw screen border
        NSColor.separatorColor.setStroke()
        let borderPath = NSBezierPath(rect: previewRect)
        borderPath.lineWidth = 2
        borderPath.stroke()

        // Get screen bounds for scaling
        guard let screenBounds = calculateScreenBounds() else { return }

        // Draw zones
        for (index, zone) in zones.enumerated() {
            // Scale zone to preview rect
            let scaledZone = scaleRect(zone, from: screenBounds, to: previewRect)

            // Draw zone with alternating colors
            let color = index % 2 == 0 ? NSColor.systemBlue.withAlphaComponent(0.3) : NSColor.systemGreen.withAlphaComponent(0.3)
            color.setFill()

            let zonePath = NSBezierPath(rect: scaledZone)
            zonePath.fill()

            // Draw zone border
            NSColor.labelColor.withAlphaComponent(0.5).setStroke()
            zonePath.lineWidth = 1
            zonePath.stroke()

            // Draw zone label
            let label = "Zone \(index + 1)"
            let attrs: [NSAttributedString.Key: Any] = [
                .font: NSFont.systemFont(ofSize: 12, weight: .medium),
                .foregroundColor: NSColor.labelColor
            ]
            let labelSize = label.size(withAttributes: attrs)
            let labelX = scaledZone.midX - (labelSize.width / 2)
            let labelY = scaledZone.midY - (labelSize.height / 2)
            label.draw(at: NSPoint(x: labelX, y: labelY), withAttributes: attrs)
        }
    }

    private func calculateScreenBounds() -> CGRect? {
        guard !zones.isEmpty else { return nil }

        var minX = CGFloat.infinity
        var minY = CGFloat.infinity
        var maxX = -CGFloat.infinity
        var maxY = -CGFloat.infinity

        for zone in zones {
            minX = min(minX, zone.minX)
            minY = min(minY, zone.minY)
            maxX = max(maxX, zone.maxX)
            maxY = max(maxY, zone.maxY)
        }

        return CGRect(x: minX, y: minY, width: maxX - minX, height: maxY - minY)
    }

    private func scaleRect(_ rect: CGRect, from sourceBounds: CGRect, to targetBounds: CGRect) -> CGRect {
        let xScale = targetBounds.width / sourceBounds.width
        let yScale = targetBounds.height / sourceBounds.height

        let scaledX = targetBounds.minX + ((rect.minX - sourceBounds.minX) * xScale)
        let scaledY = targetBounds.minY + ((rect.minY - sourceBounds.minY) * yScale)
        let scaledWidth = rect.width * xScale
        let scaledHeight = rect.height * yScale

        return CGRect(x: scaledX, y: scaledY, width: scaledWidth, height: scaledHeight)
    }

    private func drawDisabledState() {
        // Calculate preview area (maintain aspect ratio)
        let padding: CGFloat = 20
        let availableWidth = bounds.width - (padding * 2)
        let availableHeight = bounds.height - (padding * 2)

        var previewWidth = availableWidth
        var previewHeight = previewWidth / aspectRatio

        if previewHeight > availableHeight {
            previewHeight = availableHeight
            previewWidth = previewHeight * aspectRatio
        }

        let previewX = (bounds.width - previewWidth) / 2
        let previewY = (bounds.height - previewHeight) / 2
        let previewRect = CGRect(x: previewX, y: previewY, width: previewWidth, height: previewHeight)

        // Draw screen border with disabled style
        NSColor.separatorColor.setStroke()
        let borderPath = NSBezierPath(rect: previewRect)
        borderPath.lineWidth = 2
        borderPath.stroke()

        // Fill with disabled gray
        NSColor.systemGray.withAlphaComponent(0.2).setFill()
        previewRect.fill()

        // Draw diagonal lines to indicate disabled
        NSColor.separatorColor.setStroke()
        let diagonalPath = NSBezierPath()
        diagonalPath.lineWidth = 1

        // Draw subtle diagonal pattern
        let spacing: CGFloat = 30
        var x = previewRect.minX
        while x < previewRect.maxX + previewRect.height {
            diagonalPath.move(to: NSPoint(x: x, y: previewRect.minY))
            diagonalPath.line(to: NSPoint(x: x - previewRect.height, y: previewRect.maxY))
            x += spacing
        }
        diagonalPath.stroke()

        // Draw "Disabled" label
        let label = "Snapping Disabled"
        let attrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 16, weight: .semibold),
            .foregroundColor: NSColor.secondaryLabelColor
        ]
        let labelSize = label.size(withAttributes: attrs)
        let labelX = previewRect.midX - (labelSize.width / 2)
        let labelY = previewRect.midY - (labelSize.height / 2)

        // Draw label background for readability
        let labelPadding: CGFloat = 8
        let labelBgRect = CGRect(
            x: labelX - labelPadding,
            y: labelY - labelPadding / 2,
            width: labelSize.width + (labelPadding * 2),
            height: labelSize.height + labelPadding
        )
        NSColor.controlBackgroundColor.withAlphaComponent(0.9).setFill()
        let labelBgPath = NSBezierPath(roundedRect: labelBgRect, xRadius: 4, yRadius: 4)
        labelBgPath.fill()

        label.draw(at: NSPoint(x: labelX, y: labelY), withAttributes: attrs)
    }
}
