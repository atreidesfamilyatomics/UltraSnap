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

    private func showAccessibilityAlert() {
        let alert = NSAlert()
        alert.messageText = "Accessibility Permission Required"
        alert.informativeText = "UltraSnap needs accessibility permissions to manage your windows.\n\nClick 'Open System Settings' to grant permission, then restart UltraSnap."
        alert.alertStyle = .warning
        alert.addButton(withTitle: "Open System Settings")
        alert.addButton(withTitle: "Quit")

        let response = alert.runModal()

        if response == .alertFirstButtonReturn {
            // Open System Settings to Accessibility
            let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!
            NSWorkspace.shared.open(url)
        }

        // Quit app - user needs to restart after granting permission
        NSApplication.shared.terminate(nil)
    }

    private func setupApplication() {
        AppLogger.appDelegate.debug("setupApplication starting...")

        // Initialize core components
        snapEngine = SnapEngine()
        AppLogger.appDelegate.debug("snapEngine created")

        // Initialize global keyboard shortcuts
        ShortcutManager.shared.configure(with: snapEngine!)
        AppLogger.appDelegate.debug("ShortcutManager configured with snapEngine")

        previewOverlay = PreviewOverlay()
        AppLogger.appDelegate.debug("previewOverlay created")

        dragMonitor = DragMonitor(snapEngine: snapEngine!, previewOverlay: previewOverlay!)
        AppLogger.appDelegate.debug("dragMonitor created")

        menuBarController = MenuBarController(snapEngine: snapEngine!)
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
