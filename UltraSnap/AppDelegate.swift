import Cocoa
import ApplicationServices
import os.log

class AppDelegate: NSObject, NSApplicationDelegate {

    private var menuBarController: MenuBarController?
    private var dragMonitor: DragMonitor?
    private var previewOverlay: PreviewOverlay?
    private var snapEngine: SnapEngine?

    func applicationDidFinishLaunching(_ notification: Notification) {
        AppLogger.appDelegate.info("applicationDidFinishLaunching called")

        // Load configuration early
        _ = ConfigurationManager.shared.loadConfiguration()
        AppLogger.appDelegate.debug("Configuration loaded")

        // Check accessibility permissions - this will show native prompt if not granted
        let hasPermission = checkAccessibilityPermissions()
        AppLogger.appDelegate.debug("accessibility permission check: \(hasPermission)")

        if !hasPermission {
            AppLogger.appDelegate.warning("Accessibility permission not yet granted - user needs to enable in System Settings")
            // Still set up the app so menu bar appears - features won't work until permission granted
        }

        setupApplication()
        AppLogger.appDelegate.info("applicationDidFinishLaunching complete")
    }

    private func checkAccessibilityPermissions() -> Bool {
        // prompt: true will show the native macOS permission dialog
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true]
        return AXIsProcessTrustedWithOptions(options as CFDictionary)
    }

    private func setupApplication() {
        AppLogger.appDelegate.debug("setupApplication starting...")

        // Initialize core components
        snapEngine = SnapEngine()
        AppLogger.appDelegate.debug("snapEngine created")

        guard let engine = snapEngine else {
            AppLogger.appDelegate.error("Failed to create snapEngine")
            return
        }

        // Initialize global keyboard shortcuts
        ShortcutManager.shared.configure(with: engine)
        AppLogger.appDelegate.debug("ShortcutManager configured with snapEngine")

        previewOverlay = PreviewOverlay()
        AppLogger.appDelegate.debug("previewOverlay created")

        guard let overlay = previewOverlay else {
            AppLogger.appDelegate.error("Failed to create previewOverlay")
            return
        }

        dragMonitor = DragMonitor(snapEngine: engine, previewOverlay: overlay)
        AppLogger.appDelegate.debug("dragMonitor created")

        menuBarController = MenuBarController(snapEngine: engine)
        let menuBarCreated = menuBarController != nil
        AppLogger.appDelegate.debug("menuBarController created and retained: \(menuBarCreated)")

        // Start monitoring for window drags
        dragMonitor?.startMonitoring()
        AppLogger.appDelegate.debug("dragMonitor started")

        AppLogger.appDelegate.info("UltraSnap initialized successfully - check menu bar for icon!")
    }

    func applicationWillTerminate(_ notification: Notification) {
        dragMonitor?.stopMonitoring()
    }

    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
        return true
    }
}
