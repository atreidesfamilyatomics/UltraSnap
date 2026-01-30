import Cocoa
import os.log

// MARK: - Snap Engine
// Handles zone calculation and window snapping for ultrawide displays

class SnapEngine {

    // MARK: - Constants

    /// Height in points of the trigger region at the top of each screen
    /// where dragging activates zone snapping
    private let triggerRegionHeight: CGFloat = 100

    // MARK: - State

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
            AppLogger.snapEngine.error("Invalid zone index \(index), valid range 0..<\(frames.count)")
            return .zero
        }
        return frames[index]
    }

    // MARK: - Snap Window to Zone

    func snapWindowToZone(_ window: AXUIElement, zoneIndex: Int) -> Bool {
        let frame = frameForZone(at: zoneIndex)

        guard frame != .zero else {
            AppLogger.snapEngine.error("Cannot snap to invalid frame")
            return false
        }

        let targetScreenName = getTargetScreen()?.localizedName ?? "unknown"
        AppLogger.snapEngine.debug("Snapping to zone \(zoneIndex)")
        AppLogger.snapEngine.debug("  Target screen: \(targetScreenName)")
        AppLogger.snapEngine.debug("  Zone frame (Cocoa): \(frame.debugDescription)")

        if let identifier = currentDisplayIdentifier {
            AppLogger.snapEngine.debug("  Display: \(identifier.shortID)")
        }

        return AccessibilityManager.shared.setWindowFrame(window, frame: frame)
    }

    // MARK: - Snap Frontmost Window to Zone

    func snapFrontmostWindowToZone(at zoneIndex: Int) -> Bool {
        guard let window = AccessibilityManager.shared.getFrontmostWindow() else {
            AppLogger.snapEngine.debug("No frontmost window found")
            return false
        }

        let mouseLocation = NSEvent.mouseLocation
        updateCurrentScreen(for: mouseLocation)

        let currentScreenName = currentScreen?.localizedName ?? "nil"
        AppLogger.snapEngine.debug("snapFrontmostWindowToZone called")
        AppLogger.snapEngine.debug("  Mouse location: \(mouseLocation.debugDescription)")
        AppLogger.snapEngine.debug("  Current screen: \(currentScreenName)")
        AppLogger.snapEngine.debug("  Zone index: \(zoneIndex)")

        let success = snapWindowToZone(window, zoneIndex: zoneIndex)

        if success {
            AppLogger.snapEngine.debug("Snapped window to zone \(zoneIndex)")
        } else {
            AppLogger.snapEngine.warning("Failed to snap window to zone \(zoneIndex)")
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
        AppLogger.snapEngine.debug("Screen Configuration:")
        for (index, screen) in ScreenManager.shared.screens.enumerated() {
            let identifier = ScreenManager.shared.getDisplayIdentifier(for: screen)
            AppLogger.snapEngine.debug("  Screen \(index): \(screen.localizedName)")
            AppLogger.snapEngine.debug("    Frame: \(screen.frame.debugDescription)")
            AppLogger.snapEngine.debug("    Visible: \(screen.visibleFrame.debugDescription)")
            AppLogger.snapEngine.debug("    Is Main: \(screen == ScreenManager.shared.mainScreen)")
            AppLogger.snapEngine.debug("    Display ID: \(identifier.shortID)")
        }
    }
}