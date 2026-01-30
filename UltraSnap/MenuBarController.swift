import Cocoa
import os.log
import KeyboardShortcuts

// MARK: - Menu Bar Controller
// Manages the status bar item and dropdown menu

class MenuBarController {

    private var statusItem: NSStatusItem?
    private let snapEngine: SnapEngine

    init(snapEngine: SnapEngine) {
        self.snapEngine = snapEngine
        AppLogger.menuBar.debug("init called")

        // Ensure status item is created on main thread
        if Thread.isMainThread {
            setupStatusItem()
        } else {
            DispatchQueue.main.sync {
                setupStatusItem()
            }
        }

        let statusItemDesc = String(describing: statusItem)
        AppLogger.menuBar.debug("init complete, statusItem: \(statusItemDesc)")
    }

    // MARK: - Setup Status Item

    private func setupStatusItem() {
        AppLogger.menuBar.debug("setupStatusItem starting on thread: \(Thread.isMainThread ? "main" : "background")")

        // Create the status item
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        let statusItemCreated = statusItem != nil
        AppLogger.menuBar.debug("statusItem created: \(statusItemCreated ? "success" : "FAILED")")

        guard let item = statusItem else {
            AppLogger.menuBar.error("Failed to create status item!")
            return
        }

        guard let button = item.button else {
            AppLogger.menuBar.error("Status item button is nil!")
            return
        }

        AppLogger.menuBar.debug("button obtained successfully")

        // Use SF Symbol for the icon
        if let image = NSImage(systemSymbolName: "rectangle.split.3x1", accessibilityDescription: "UltraSnap") {
            image.isTemplate = true
            button.image = image
            AppLogger.menuBar.debug("SF Symbol 'rectangle.split.3x1' set successfully")
        } else {
            // Fallback text if symbol not available
            button.title = "US"
            AppLogger.menuBar.debug("SF Symbol not available, using text fallback 'US'")
        }

        button.toolTip = "UltraSnap - Window Manager"

        setupMenu()
        AppLogger.menuBar.debug("setupStatusItem complete - menu bar icon should be visible")
    }

    // MARK: - Setup Menu

    private func setupMenu() {
        let menu = NSMenu()

        // Header
        let headerItem = NSMenuItem(title: "UltraSnap", action: nil, keyEquivalent: "")
        headerItem.isEnabled = false
        menu.addItem(headerItem)

        menu.addItem(NSMenuItem.separator())

        // Quick Snap Section
        let snapHeader = NSMenuItem(title: "Snap Active Window", action: nil, keyEquivalent: "")
        snapHeader.isEnabled = false
        menu.addItem(snapHeader)

        // Left Third
        let leftItem = NSMenuItem(
            title: "← Left Third",
            action: #selector(snapLeftThird),
            keyEquivalent: "1"
        )
        leftItem.keyEquivalentModifierMask = [.control, .option]
        leftItem.target = self
        menu.addItem(leftItem)

        // Center Third
        let centerItem = NSMenuItem(
            title: "↔ Center Third",
            action: #selector(snapCenterThird),
            keyEquivalent: "2"
        )
        centerItem.keyEquivalentModifierMask = [.control, .option]
        centerItem.target = self
        menu.addItem(centerItem)

        // Right Third
        let rightItem = NSMenuItem(
            title: "→ Right Third",
            action: #selector(snapRightThird),
            keyEquivalent: "3"
        )
        rightItem.keyEquivalentModifierMask = [.control, .option]
        rightItem.target = self
        menu.addItem(rightItem)

        menu.addItem(NSMenuItem.separator())

        // Info
        let infoItem = NSMenuItem(title: "Drag windows to top of screen to snap", action: nil, keyEquivalent: "")
        infoItem.isEnabled = false
        menu.addItem(infoItem)

        menu.addItem(NSMenuItem.separator())

        // Settings
        let settingsItem = NSMenuItem(
            title: "Settings...",
            action: #selector(openSettings),
            keyEquivalent: ","
        )
        settingsItem.target = self
        menu.addItem(settingsItem)

        menu.addItem(NSMenuItem.separator())

        // Quit
        let quitItem = NSMenuItem(
            title: "Quit UltraSnap",
            action: #selector(quitApp),
            keyEquivalent: "q"
        )
        quitItem.target = self
        menu.addItem(quitItem)

        statusItem?.menu = menu
    }

    // MARK: - Menu Actions

    @objc private func snapLeftThird() {
        _ = snapEngine.snapFrontmostWindowToZone(at: 0)
    }

    @objc private func snapCenterThird() {
        _ = snapEngine.snapFrontmostWindowToZone(at: 1)
    }

    @objc private func snapRightThird() {
        _ = snapEngine.snapFrontmostWindowToZone(at: 2)
    }

    @objc private func openSettings() {
        SettingsWindowController.shared.showWindow()
    }

    @objc private func quitApp() {
        NSApplication.shared.terminate(nil)
    }
}
