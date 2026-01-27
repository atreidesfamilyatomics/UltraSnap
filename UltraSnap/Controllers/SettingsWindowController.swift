import Cocoa

class SettingsWindowController: NSWindowController {

    // Singleton pattern
    static let shared = SettingsWindowController()

    private var tabView: NSTabView!

    private init() {
        // Create window (increased height to accommodate permissions section)
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 600, height: 600),
            styleMask: [.titled, .closable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        window.title = "UltraSnap Settings"
        window.center()
        window.isReleasedWhenClosed = false  // Keep window around

        super.init(window: window)

        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) not implemented")
    }

    private func setupUI() {
        tabView = NSTabView()
        tabView.tabViewType = .topTabsBezelBorder

        // Tab 1: Zone Presets
        let zoneTab = NSTabViewItem(identifier: "zones")
        zoneTab.label = "Zone Presets"
        let zoneView = ZoneSettingsView()
        zoneTab.view = zoneView
        tabView.addTabViewItem(zoneTab)

        // Tab 2: Keyboard Shortcuts
        let keyboardTab = NSTabViewItem(identifier: "keyboard")
        keyboardTab.label = "Keyboard"
        let keyboardView = KeyboardSettingsView()
        keyboardTab.view = keyboardView
        tabView.addTabViewItem(keyboardTab)

        // Tab 3: General
        let generalTab = NSTabViewItem(identifier: "general")
        generalTab.label = "General"
        let generalView = GeneralSettingsView()
        generalTab.view = generalView
        tabView.addTabViewItem(generalTab)

        window?.contentView = tabView
    }

    func showWindow() {
        showWindow(nil)
        NSApp.activate(ignoringOtherApps: true)
        window?.makeKeyAndOrderFront(nil)
    }
}
