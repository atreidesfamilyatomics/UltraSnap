import Cocoa
import os.log

// MARK: - Screen Manager
// Singleton that caches screen information to reduce XPC calls to UIIntelligenceSupport
// Refreshes only when display configuration actually changes

class ScreenManager {

    static let shared = ScreenManager()

    // MARK: - Cached Screen Data

    private var _cachedScreens: [NSScreen] = []
    private var _cachedMainScreen: NSScreen?
    private var _cachedPrimaryScreen: NSScreen?

    // MARK: - Public Accessors (Cached)

    /// All screens (cached, refreshed on display config changes)
    var screens: [NSScreen] {
        return _cachedScreens
    }

    /// Main screen - the one with keyboard focus (cached)
    var mainScreen: NSScreen? {
        return _cachedMainScreen
    }

    /// Primary screen - first screen, origin of global coordinate system (cached)
    var primaryScreen: NSScreen? {
        return _cachedPrimaryScreen
    }

    // MARK: - Initialization

    private init() {
        // Initial cache population
        refreshCache()

        // Listen for display configuration changes
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(screenConfigurationDidChange),
            name: NSApplication.didChangeScreenParametersNotification,
            object: nil
        )
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: - Cache Management

    @objc private func screenConfigurationDidChange(_ notification: Notification) {
        AppLogger.screenManager.info("Screen configuration changed - refreshing cache")
        refreshCache()

        // Log display identifiers for debugging
        for (index, screen) in screens.enumerated() {
            let identifier = getDisplayIdentifier(for: screen)
            AppLogger.screenManager.debug("Display \(index): \(identifier.shortID), Origin=(\(identifier.originX), \(identifier.originY))")
        }
    }

    /// Force refresh the screen cache (called automatically on display changes)
    func refreshCache() {
        _cachedScreens = NSScreen.screens
        _cachedMainScreen = NSScreen.main
        _cachedPrimaryScreen = NSScreen.screens.first

        let screenCount = _cachedScreens.count
        AppLogger.screenManager.debug("Cache refreshed: \(screenCount) screen(s)")
    }

    // MARK: - Helper Methods

    /// Find screen containing a point (uses cached screens)
    func screenContaining(point: CGPoint) -> NSScreen? {
        for screen in _cachedScreens {
            if screen.frame.contains(point) {
                return screen
            }
        }
        return _cachedMainScreen ?? _cachedPrimaryScreen
    }

    /// Find screen containing/intersecting a frame (uses cached screens)
    func screenContaining(frame: CGRect) -> NSScreen? {
        for screen in _cachedScreens {
            if screen.frame.intersects(frame) {
                return screen
            }
        }
        return nil
    }

    /// Get display ID for a screen
    func getDisplayID(for screen: NSScreen) -> CGDirectDisplayID? {
        guard let screenNumber = screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? NSNumber else {
            return nil
        }
        return CGDirectDisplayID(screenNumber.uint32Value)
    }

    // MARK: - Display Identification (Phase 1B)

    /// Get DisplayIdentifier for a screen
    /// - Parameter screen: The NSScreen to identify
    /// - Returns: DisplayIdentifier that uniquely identifies this screen
    func getDisplayIdentifier(for screen: NSScreen) -> DisplayIdentifier {
        return DisplayIdentifier(from: screen)
    }

    /// Find screen matching a DisplayIdentifier
    /// - Parameters:
    ///   - identifier: The DisplayIdentifier to match
    ///   - tolerance: Position tolerance in points for identical monitors
    /// - Returns: NSScreen that matches the identifier, or nil if not found
    func findScreen(matching identifier: DisplayIdentifier, tolerance: CGFloat = 10.0) -> NSScreen? {
        return screens.first { identifier.matches($0, tolerance: tolerance) }
    }

}

// MARK: - ScreenProviding Protocol Conformance
extension ScreenManager: ScreenProviding {
    func refreshScreenCache() {
        refreshCache()
    }
}