import Cocoa

// MARK: - Zone Definition (DEPRECATED - Use Int indices)

@available(*, deprecated, message: "Use Int zone indices instead. Zones are now represented as 0-indexed positions matching DefaultLayouts.zones() array.")
enum SnapZone: Int, CaseIterable {
    case leftThird = 0
    case centerThird = 1
    case rightThird = 2

    var name: String {
        switch self {
        case .leftThird: return "Left Third"
        case .centerThird: return "Center Third"
        case .rightThird: return "Right Third"
        }
    }
}

// MARK: - Snap Engine
// Handles zone calculation and window snapping for ultrawide displays

class SnapEngine {

    // Trigger region: top portion of screen where dragging activates zones
    private let triggerRegionHeight: CGFloat = 100

    // Track which screen the user is currently interacting with
    private var currentScreen: NSScreen?

    // Track display identifier for current screen (Phase 1B)
    private var currentDisplayIdentifier: DisplayIdentifier?

    // Configuration manager for per-display presets (Phase 1C)
    private let configManager = ConfigurationManager.shared

    // MARK: - Get Screen Containing Point

    func screenContaining(point: CGPoint) -> NSScreen? {
        // Use cached screens to avoid XPC churn
        return ScreenManager.shared.screenContaining(point: point)
    }

    // MARK: - Get Current Target Screen

    func getTargetScreen() -> NSScreen? {
        return currentScreen ?? ScreenManager.shared.mainScreen ?? ScreenManager.shared.primaryScreen
    }

    // MARK: - Set Current Screen from Mouse Location

    func updateCurrentScreen(for mouseLocation: CGPoint) {
        currentScreen = screenContaining(point: mouseLocation)
        
        // Track display identifier for current screen
        if let screen = currentScreen {
            currentDisplayIdentifier = ScreenManager.shared.getDisplayIdentifier(for: screen)
        }
    }

    // MARK: - Get Screen Frame (Excluding Menu Bar)

    func getVisibleScreenFrame() -> CGRect {
        guard let screen = getTargetScreen() else {
            return CGRect(x: 0, y: 0, width: 1920, height: 1080)
        }
        return screen.visibleFrame
    }

    // MARK: - Get Zone Frames for Current Screen

    /// Get zone frames for current screen based on preset
    /// Returns array of frames ordered by zone index (0, 1, 2, ...)
    func getZoneFrames() -> [CGRect] {
        guard let screen = getTargetScreen() else {
            return []
        }

        let displayIdentifier = ScreenManager.shared.getDisplayIdentifier(for: screen)
        let preset = configManager.getPreset(for: displayIdentifier)

        // Returns array of 2-6 frames depending on preset
        return DefaultLayouts.zones(for: preset, on: screen)
    }
    

    // MARK: - Get Trigger Regions (Top of each zone)

    /// Get trigger regions (top of screen) for each zone
    /// Returns array of trigger rects matching zone count
    func getTriggerRegions() -> [CGRect] {
        guard let screen = getTargetScreen() else { return [] }

        let zoneFrames = getZoneFrames()
        let screenFrame = screen.frame
        let topY = screenFrame.maxY - triggerRegionHeight

        // Create trigger for each zone, maintaining same width/position
        return zoneFrames.map { zoneFrame in
            CGRect(
                x: zoneFrame.origin.x,
                y: topY,
                width: zoneFrame.width,
                height: triggerRegionHeight
            )
        }
    }

    // MARK: - Determine Zone from Mouse Position

    /// Determine which zone index (0, 1, 2...) contains mouse position
    /// Returns nil if mouse not in any trigger region
    func zoneIndexForMousePosition(_ mouseLocation: CGPoint) -> Int? {
        updateCurrentScreen(for: mouseLocation)

        let triggers = getTriggerRegions()

        for (index, triggerRect) in triggers.enumerated() {
            if triggerRect.contains(mouseLocation) {
                return index
            }
        }

        return nil
    }

    // MARK: - Get Frame for Zone

    /// Get frame for zone at given index
    func frameForZone(at index: Int) -> CGRect {
        let frames = getZoneFrames()
        guard index >= 0 && index < frames.count else {
            print("[SnapEngine] ERROR: Invalid zone index \(index), valid range 0..<\(frames.count)")
            return .zero
        }
        return frames[index]
    }

    // MARK: - Snap Window to Zone

    func snapWindowToZone(_ window: AXUIElement, zoneIndex: Int) -> Bool {
        let frame = frameForZone(at: zoneIndex)

        guard frame != .zero else {
            print("[SnapEngine] ERROR: Cannot snap to invalid frame")
            return false
        }

        print("[SnapEngine] Snapping to zone \(zoneIndex)")
        print("  Target screen: \(getTargetScreen()?.localizedName ?? "unknown")")
        print("  Zone frame (Cocoa): \(frame)")

        if let identifier = currentDisplayIdentifier {
            print("  Display: \(identifier.shortID)")
        }

        return AccessibilityManager.shared.setWindowFrame(window, frame: frame)
    }

    // MARK: - Snap Frontmost Window to Zone

    func snapFrontmostWindowToZone(at zoneIndex: Int) -> Bool {
        guard let window = AccessibilityManager.shared.getFrontmostWindow() else {
            print("[SnapEngine] No frontmost window found")
            return false
        }

        let mouseLocation = NSEvent.mouseLocation
        updateCurrentScreen(for: mouseLocation)

        print("[SnapEngine] snapFrontmostWindowToZone called")
        print("  Mouse location: \(mouseLocation)")
        print("  Current screen: \(currentScreen?.localizedName ?? "nil")")
        print("  Zone index: \(zoneIndex)")

        let success = snapWindowToZone(window, zoneIndex: zoneIndex)

        if success {
            print("[SnapEngine] Snapped window to zone \(zoneIndex)")
        } else {
            print("[SnapEngine] Failed to snap window to zone \(zoneIndex)")
        }

        return success
    }
    
    // MARK: - Display Identifier Access (Phase 1B)
    
    /// Get the current display identifier being operated on
    /// - Returns: DisplayIdentifier for the current screen, or nil if none set
    func getCurrentDisplayIdentifier() -> DisplayIdentifier? {
        return currentDisplayIdentifier
    }

    // MARK: - Debug: Print Screen Info

    func debugPrintScreenInfo() {
        print("[SnapEngine] Screen Configuration:")
        for (index, screen) in ScreenManager.shared.screens.enumerated() {
            let identifier = ScreenManager.shared.getDisplayIdentifier(for: screen)
            print("  Screen \(index): \(screen.localizedName)")
            print("    Frame: \(screen.frame)")
            print("    Visible: \(screen.visibleFrame)")
            print("    Is Main: \(screen == ScreenManager.shared.mainScreen)")
            print("    Display ID: \(identifier.shortID)")
        }
    }
}