import Cocoa
import os.log

// MARK: - Snap Engine
// Handles zone calculation and window snapping for ultrawide displays

class SnapEngine {

    // MARK: - Constants

    /// Height in points of the trigger region at the top of each screen
    /// where dragging activates zone snapping
    private let triggerRegionHeight: CGFloat = 100
    
    /// Width in points of the trigger region at the left/right edges of the screen
    private let triggerRegionWidth: CGFloat = 100
    
    /// Height in points of the trigger region at the bottom of the screen
    private let bottomTriggerHeight: CGFloat = 100
    
    /// Size in points of corner trigger regions (square)
    private let cornerSize: CGFloat = 80

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
    /// 
    /// Checks trigger regions in this priority order:
    /// 1. Corners (for grid-based presets)
    /// 2. Bottom edge (for grid-based presets)
    /// 3. Left edge (for grid-based presets)
    /// 4. Right edge (for grid-based presets)
    /// 5. Top edge (all presets with zones)
    func zoneIndexForMousePosition(_ mouseLocation: CGPoint) -> Int? {
        updateCurrentScreen(for: mouseLocation)

        guard let screen = getTargetScreen() else { return nil }
        let displayIdentifier = ScreenManager.shared.getDisplayIdentifier(for: screen)
        let preset = configManager.getPreset(for: displayIdentifier)
        let visibleFrame = screen.visibleFrame
        
        // Get grid shape if this preset supports edge/corner triggers
        if let gridShape = preset.gridShape {
            // Check corners first (highest priority to avoid ambiguity)
            if let cornerZone = checkCorners(mouseLocation, visibleFrame: visibleFrame, gridShape: gridShape) {
                return cornerZone
            }
            
            // Check bottom edge
            if let bottomZone = checkBottomEdge(mouseLocation, visibleFrame: visibleFrame, gridShape: gridShape) {
                return bottomZone
            }
            
            // Check left edge
            if let leftZone = checkLeftEdge(mouseLocation, visibleFrame: visibleFrame, gridShape: gridShape) {
                return leftZone
            }
            
            // Check right edge
            if let rightZone = checkRightEdge(mouseLocation, visibleFrame: visibleFrame, gridShape: gridShape) {
                return rightZone
            }
        }
        
        // Fall back to top triggers (works for all presets)
        let triggers = getTriggerRegions()
        for (index, triggerRect) in triggers.enumerated() {
            if triggerRect.contains(mouseLocation) {
                return index
            }
        }

        return nil
    }
    
    // MARK: - Corner Detection
    
    /// Check if mouse is in a corner trigger region and return the corresponding zone index
    private func checkCorners(_ mouseLocation: CGPoint, visibleFrame: CGRect, gridShape: (columns: Int, rows: Int)) -> Int? {
        // Bottom-left corner
        let bottomLeftRect = CGRect(
            x: visibleFrame.minX,
            y: visibleFrame.minY,
            width: cornerSize,
            height: cornerSize
        )
        if bottomLeftRect.contains(mouseLocation) {
            // Last row, first column
            return (gridShape.rows - 1) * gridShape.columns + 0
        }
        
        // Bottom-right corner
        let bottomRightRect = CGRect(
            x: visibleFrame.maxX - cornerSize,
            y: visibleFrame.minY,
            width: cornerSize,
            height: cornerSize
        )
        if bottomRightRect.contains(mouseLocation) {
            // Last row, last column
            return (gridShape.rows - 1) * gridShape.columns + (gridShape.columns - 1)
        }
        
        // Top-left corner
        let topLeftRect = CGRect(
            x: visibleFrame.minX,
            y: visibleFrame.maxY - cornerSize,
            width: cornerSize,
            height: cornerSize
        )
        if topLeftRect.contains(mouseLocation) {
            // First row, first column
            return 0
        }
        
        // Top-right corner
        let topRightRect = CGRect(
            x: visibleFrame.maxX - cornerSize,
            y: visibleFrame.maxY - cornerSize,
            width: cornerSize,
            height: cornerSize
        )
        if topRightRect.contains(mouseLocation) {
            // First row, last column
            return gridShape.columns - 1
        }
        
        return nil
    }
    
    // MARK: - Bottom Edge Detection
    
    /// Check if mouse is in bottom edge trigger region and return the corresponding zone index
    private func checkBottomEdge(_ mouseLocation: CGPoint, visibleFrame: CGRect, gridShape: (columns: Int, rows: Int)) -> Int? {
        let bottomBand = CGRect(
            x: visibleFrame.minX,
            y: visibleFrame.minY,
            width: visibleFrame.width,
            height: bottomTriggerHeight
        )
        
        guard bottomBand.contains(mouseLocation) else { return nil }
        
        // Calculate column based on x position
        let relativeX = mouseLocation.x - visibleFrame.minX
        let columnWidth = visibleFrame.width / CGFloat(gridShape.columns)
        let column = Int(floor(relativeX / columnWidth))
        let clampedColumn = min(max(column, 0), gridShape.columns - 1)
        
        // Bottom row
        let zoneIndex = (gridShape.rows - 1) * gridShape.columns + clampedColumn
        return zoneIndex
    }
    
    // MARK: - Left Edge Detection
    
    /// Check if mouse is in left edge trigger region and return the corresponding zone index
    private func checkLeftEdge(_ mouseLocation: CGPoint, visibleFrame: CGRect, gridShape: (columns: Int, rows: Int)) -> Int? {
        let leftBand = CGRect(
            x: visibleFrame.minX,
            y: visibleFrame.minY,
            width: triggerRegionWidth,
            height: visibleFrame.height
        )
        
        guard leftBand.contains(mouseLocation) else { return nil }
        
        // Calculate row based on y position (Cocoa coordinates: origin at bottom-left)
        let relativeY = mouseLocation.y - visibleFrame.minY
        let rowHeight = visibleFrame.height / CGFloat(gridShape.rows)
        let rowFromBottom = Int(floor(relativeY / rowHeight))
        let clampedRow = min(max(rowFromBottom, 0), gridShape.rows - 1)
        
        // Convert to row from top (zone indices are ordered top-to-bottom)
        let row = gridShape.rows - 1 - clampedRow
        
        // First column
        let zoneIndex = row * gridShape.columns + 0
        return zoneIndex
    }
    
    // MARK: - Right Edge Detection
    
    /// Check if mouse is in right edge trigger region and return the corresponding zone index
    private func checkRightEdge(_ mouseLocation: CGPoint, visibleFrame: CGRect, gridShape: (columns: Int, rows: Int)) -> Int? {
        let rightBand = CGRect(
            x: visibleFrame.maxX - triggerRegionWidth,
            y: visibleFrame.minY,
            width: triggerRegionWidth,
            height: visibleFrame.height
        )
        
        guard rightBand.contains(mouseLocation) else { return nil }
        
        // Calculate row based on y position (Cocoa coordinates: origin at bottom-left)
        let relativeY = mouseLocation.y - visibleFrame.minY
        let rowHeight = visibleFrame.height / CGFloat(gridShape.rows)
        let rowFromBottom = Int(floor(relativeY / rowHeight))
        let clampedRow = min(max(rowFromBottom, 0), gridShape.rows - 1)
        
        // Convert to row from top (zone indices are ordered top-to-bottom)
        let row = gridShape.rows - 1 - clampedRow
        
        // Last column
        let zoneIndex = row * gridShape.columns + (gridShape.columns - 1)
        return zoneIndex
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