import Cocoa

// MARK: - Zone Definition

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
    }

    // MARK: - Get Screen Frame (Excluding Menu Bar)

    func getVisibleScreenFrame() -> CGRect {
        guard let screen = getTargetScreen() else {
            return CGRect(x: 0, y: 0, width: 1920, height: 1080)
        }
        return screen.visibleFrame
    }

    // MARK: - Calculate Zone Boundaries for Current Screen

    func getZoneBoundaries() -> [SnapZone: CGRect] {
        let screenFrame = getVisibleScreenFrame()
        let thirdWidth = screenFrame.width / 3

        var zones: [SnapZone: CGRect] = [:]

        zones[.leftThird] = CGRect(
            x: screenFrame.origin.x,
            y: screenFrame.origin.y,
            width: thirdWidth,
            height: screenFrame.height
        )

        zones[.centerThird] = CGRect(
            x: screenFrame.origin.x + thirdWidth,
            y: screenFrame.origin.y,
            width: thirdWidth,
            height: screenFrame.height
        )

        zones[.rightThird] = CGRect(
            x: screenFrame.origin.x + (thirdWidth * 2),
            y: screenFrame.origin.y,
            width: thirdWidth,
            height: screenFrame.height
        )

        return zones
    }

    // MARK: - Get Trigger Regions (Top of each zone)

    func getTriggerRegions() -> [SnapZone: CGRect] {
        guard let screen = getTargetScreen() else { return [:] }

        let screenFrame = screen.frame // Full frame including menu bar
        let thirdWidth = screenFrame.width / 3
        let topY = screenFrame.maxY - triggerRegionHeight

        var triggers: [SnapZone: CGRect] = [:]

        triggers[.leftThird] = CGRect(
            x: screenFrame.origin.x,
            y: topY,
            width: thirdWidth,
            height: triggerRegionHeight
        )

        triggers[.centerThird] = CGRect(
            x: screenFrame.origin.x + thirdWidth,
            y: topY,
            width: thirdWidth,
            height: triggerRegionHeight
        )

        triggers[.rightThird] = CGRect(
            x: screenFrame.origin.x + (thirdWidth * 2),
            y: topY,
            width: thirdWidth,
            height: triggerRegionHeight
        )

        return triggers
    }

    // MARK: - Determine Zone from Mouse Position

    func zoneForMousePosition(_ mouseLocation: CGPoint) -> SnapZone? {
        // Update which screen we're targeting based on mouse position
        updateCurrentScreen(for: mouseLocation)

        let triggers = getTriggerRegions()

        for (zone, triggerRect) in triggers {
            if triggerRect.contains(mouseLocation) {
                return zone
            }
        }

        return nil
    }

    // MARK: - Get Frame for Zone

    func frameForZone(_ zone: SnapZone) -> CGRect {
        let zones = getZoneBoundaries()
        return zones[zone] ?? .zero
    }

    // MARK: - Snap Window to Zone

    func snapWindowToZone(_ window: AXUIElement, zone: SnapZone) -> Bool {
        let frame = frameForZone(zone)

        print("[SnapEngine] Snapping to zone \(zone.name)")
        print("  Target screen: \(getTargetScreen()?.localizedName ?? "unknown")")
        print("  Zone frame (Cocoa): \(frame)")

        return AccessibilityManager.shared.setWindowFrame(window, frame: frame)
    }

    // MARK: - Snap Frontmost Window to Zone

    func snapFrontmostWindowToZone(_ zone: SnapZone) -> Bool {
        guard let window = AccessibilityManager.shared.getFrontmostWindow() else {
            print("[SnapEngine] No frontmost window found")
            return false
        }

        // CRITICAL: Re-validate screen from current mouse position before snapping
        // This ensures we use fresh screen info, not stale cached data
        let mouseLocation = NSEvent.mouseLocation
        updateCurrentScreen(for: mouseLocation)

        print("[SnapEngine] snapFrontmostWindowToZone called")
        print("  Mouse location: \(mouseLocation)")
        print("  Current screen: \(currentScreen?.localizedName ?? "nil")")

        let success = snapWindowToZone(window, zone: zone)

        if success {
            print("[SnapEngine] Snapped window to \(zone.name)")
        } else {
            print("[SnapEngine] Failed to snap window to \(zone.name)")
        }

        return success
    }

    // MARK: - Debug: Print Screen Info

    func debugPrintScreenInfo() {
        print("[SnapEngine] Screen Configuration:")
        for (index, screen) in ScreenManager.shared.screens.enumerated() {
            print("  Screen \(index): \(screen.localizedName)")
            print("    Frame: \(screen.frame)")
            print("    Visible: \(screen.visibleFrame)")
            print("    Is Main: \(screen == ScreenManager.shared.mainScreen)")
        }
    }
}
