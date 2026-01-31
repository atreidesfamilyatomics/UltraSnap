import Cocoa

/// Displays a semi-transparent overlay showing the target zone during window drag operations
///
/// PreviewOverlay creates a borderless, transparent window that sits above other windows
/// but allows click-through. When the user drags a window into a snap zone's trigger region,
/// this overlay highlights where the window will be positioned when released.
///
/// ## Architecture
/// The overlay consists of two components:
/// - `PreviewOverlay`: Controller that manages window lifecycle and positioning
/// - `OverlayView`: Custom NSView that draws the zone highlight and label
///
/// ## Usage
/// ```swift
/// let overlay = PreviewOverlay()
/// overlay.show(zoneIndex: 0, frame: zoneFrame)  // Show preview
/// overlay.hide()  // Hide when drag ends or leaves zone
/// ```
///
/// ## Visual Design
/// - Blue-tinted semi-transparent fill with 30% opacity
/// - Rounded corners (8pt radius)
/// - Darker blue border (80% opacity, 3pt width)
/// - Centered zone label ("Zone 1", "Zone 2", etc.)
class PreviewOverlay {

    private var overlayWindow: NSWindow?
    private var overlayView: OverlayView?

    // MARK: - Preview Colors

    private let previewColor = NSColor.systemBlue.withAlphaComponent(0.3)
    private let previewBorderColor = NSColor.systemBlue.withAlphaComponent(0.8)

    // MARK: - Show Preview

    func show(zoneIndex: Int, frame: CGRect) {
        // Find which screen contains this frame (using cached screens)
        let targetScreen = ScreenManager.shared.screenContaining(frame: frame)
            ?? ScreenManager.shared.mainScreen
            ?? ScreenManager.shared.primaryScreen

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
        view.zoneName = "Zone \(zoneIndex + 1)"  // "Zone 1", "Zone 2", etc.
        view.needsDisplay = true

        // Position window to cover the target screen
        window.setFrame(screen.frame, display: false)

        // Show the window
        window.orderFront(nil)
    }

    // MARK: - Hide Preview

    func hide() {
        overlayWindow?.orderOut(nil)
        // Extra safety: ensure window is not accepting events
        overlayWindow?.ignoresMouseEvents = true
    }
    
    // MARK: - Check Visibility
    
    var isVisible: Bool {
        return overlayWindow?.isVisible ?? false
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

        // Use a lower window level to avoid interfering with dropdowns/menus
        // .popUpMenu is just below system UI elements but above normal windows
        let popUpLevel = Int(CGWindowLevelForKey(.popUpMenuWindow))
        let normalLevel = Int(CGWindowLevelForKey(.normalWindow))
        let overlayLevel = max(popUpLevel - 1, normalLevel)
        window.level = NSWindow.Level(rawValue: overlayLevel)
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
