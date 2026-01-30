import os.log

/// Centralized logging utility for UltraSnap
/// Uses Apple's unified logging system (os.Logger) for efficient, categorized logging
///
/// Usage:
///   AppLogger.snapEngine.debug("Snapping to zone 0")
///   AppLogger.accessibility.error("Failed to get window frame")
///
/// View logs in Console.app by filtering for "UltraSnap" subsystem
enum AppLogger {
    private static let subsystem = "com.michaelgrady.UltraSnap"

    /// Logging for SnapEngine operations (zone calculation, window snapping)
    static let snapEngine = Logger(subsystem: subsystem, category: "SnapEngine")

    /// Logging for DragMonitor events (mouse tracking, drag detection)
    static let dragMonitor = Logger(subsystem: subsystem, category: "DragMonitor")

    /// Logging for AccessibilityManager operations (window manipulation via AX API)
    static let accessibility = Logger(subsystem: subsystem, category: "Accessibility")

    /// Logging for ScreenManager operations (display configuration, caching)
    static let screenManager = Logger(subsystem: subsystem, category: "ScreenManager")

    /// Logging for Settings views and configuration changes
    static let settings = Logger(subsystem: subsystem, category: "Settings")

    /// Logging for MenuBarController operations
    static let menuBar = Logger(subsystem: subsystem, category: "MenuBar")

    /// Logging for AppDelegate lifecycle events
    static let appDelegate = Logger(subsystem: subsystem, category: "AppDelegate")

    /// General purpose logging for miscellaneous operations
    static let general = Logger(subsystem: subsystem, category: "General")
}
