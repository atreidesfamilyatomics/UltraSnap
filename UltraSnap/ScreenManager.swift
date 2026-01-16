import Cocoa

// MARK: - Screen Manager
// Singleton that caches screen information to reduce XPC calls to UIIntelligenceSupport
// Refreshes only when display configuration actually changes

class ScreenManager {

    static let shared = ScreenManager()

    // MARK: - Cached Screen Data

    private var _cachedScreens: [NSScreen] = []
    private var _cachedMainScreen: NSScreen?
    private var _cachedPrimaryScreen: NSScreen?
    private var _lastUpdateTime: Date = .distantPast

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
        print("[ScreenManager] Display configuration changed - refreshing cache")
        refreshCache()
    }

    /// Force refresh the screen cache (called automatically on display changes)
    func refreshCache() {
        _cachedScreens = NSScreen.screens
        _cachedMainScreen = NSScreen.main
        _cachedPrimaryScreen = NSScreen.screens.first
        _lastUpdateTime = Date()

        print("[ScreenManager] Cache refreshed: \(_cachedScreens.count) screen(s)")
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
}
