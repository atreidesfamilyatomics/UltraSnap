import Cocoa

// MARK: - Preview Overlay
// Semi-transparent window that shows zone preview during drag

class PreviewOverlay {

    private var overlayWindow: NSWindow?
    private var overlayView: OverlayView?

    // MARK: - Preview Colors

    private let previewColor = NSColor.systemBlue.withAlphaComponent(0.3)
    private let previewBorderColor = NSColor.systemBlue.withAlphaComponent(0.8)

    // MARK: - Show Preview

    func show(for frame: CGRect, zone: SnapZone) {
        // Find which screen contains this frame
        let targetScreen = screenContaining(frame: frame) ?? NSScreen.main ?? NSScreen.screens.first

        guard let screen = targetScreen else { return }

        // Create or recreate window for the correct screen
        if overlayWindow == nil || overlayWindow?.screen != screen {
            createOverlayWindow(for: screen)
        }

        guard let window = overlayWindow, let view = overlayView else { return }

        // Update view with zone info and screen reference
        view.zoneFrame = frame
        view.targetScreen = screen
        view.zoneColor = previewColor
        view.borderColor = previewBorderColor
        view.zoneName = zone.name
        view.needsDisplay = true

        // Position window to cover the target screen
        window.setFrame(screen.frame, display: false)

        // Show the window
        window.orderFront(nil)
    }

    // MARK: - Find Screen Containing Frame

    private func screenContaining(frame: CGRect) -> NSScreen? {
        for screen in NSScreen.screens {
            if screen.frame.intersects(frame) {
                return screen
            }
        }
        return nil
    }

    // MARK: - Hide Preview

    func hide() {
        overlayWindow?.orderOut(nil)
    }

    // MARK: - Create Overlay Window

    private func createOverlayWindow(for screen: NSScreen) {
        // Create a borderless, transparent window
        let window = NSWindow(
            contentRect: screen.frame,
            styleMask: .borderless,
            backing: .buffered,
            defer: false
        )

        window.level = .floating
        window.backgroundColor = .clear
        window.isOpaque = false
        window.hasShadow = false
        window.ignoresMouseEvents = true // Click-through
        window.collectionBehavior = [.canJoinAllSpaces, .stationary]

        // Create the overlay view
        let view = OverlayView(frame: screen.frame)
        view.targetScreen = screen
        view.zoneColor = previewColor
        view.borderColor = previewBorderColor
        window.contentView = view

        overlayWindow = window
        overlayView = view
    }
}

// MARK: - Overlay View

class OverlayView: NSView {

    var zoneFrame: CGRect = .zero
    var targetScreen: NSScreen?
    var zoneColor: NSColor = .systemBlue.withAlphaComponent(0.3)
    var borderColor: NSColor = .systemBlue.withAlphaComponent(0.8)
    var zoneName: String = ""

    private let borderWidth: CGFloat = 3

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        guard zoneFrame != .zero else { return }

        // Convert screen coordinates to view coordinates
        // Use the target screen, not NSScreen.main
        guard let screen = targetScreen ?? NSScreen.main else { return }

        let viewFrame = CGRect(
            x: zoneFrame.origin.x - screen.frame.origin.x,
            y: zoneFrame.origin.y - screen.frame.origin.y,
            width: zoneFrame.width,
            height: zoneFrame.height
        )

        // Draw filled rectangle
        let path = NSBezierPath(roundedRect: viewFrame, xRadius: 8, yRadius: 8)
        zoneColor.setFill()
        path.fill()

        // Draw border
        borderColor.setStroke()
        path.lineWidth = borderWidth
        path.stroke()

        // Draw zone name label
        drawZoneLabel(in: viewFrame)
    }

    private func drawZoneLabel(in frame: CGRect) {
        let attributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 24, weight: .semibold),
            .foregroundColor: NSColor.white
        ]

        let labelSize = zoneName.size(withAttributes: attributes)
        let labelOrigin = CGPoint(
            x: frame.midX - labelSize.width / 2,
            y: frame.midY - labelSize.height / 2
        )

        // Draw background for label
        let labelRect = CGRect(
            x: labelOrigin.x - 12,
            y: labelOrigin.y - 8,
            width: labelSize.width + 24,
            height: labelSize.height + 16
        )

        let labelBackground = NSBezierPath(roundedRect: labelRect, xRadius: 6, yRadius: 6)
        NSColor.black.withAlphaComponent(0.5).setFill()
        labelBackground.fill()

        // Draw label text
        zoneName.draw(at: labelOrigin, withAttributes: attributes)
    }
}
