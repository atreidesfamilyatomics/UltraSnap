import Cocoa
import os.log

class ZoneSettingsView: NSView {

    private var displayPopup: NSPopUpButton!
    private var presetPopup: NSPopUpButton!
    private var previewView: ZonePreviewView!
    private var descriptionLabel: NSTextField!

    // Permissions status UI
    private var permissionStatusIndicator: NSTextField!
    private var permissionStatusLabel: NSTextField!
    private var bundlePathField: NSTextField!
    private var openSettingsButton: NSButton!
    private var copyPathButton: NSButton!
    private var permissionCheckTimer: Timer?

    private var selectedDisplayIdentifier: DisplayIdentifier?

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setupUI()
        loadDisplays()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
        loadDisplays()
    }

    private func setupUI() {
        // MARK: - Permissions Status Section (Top Priority)

        // Section header
        let permissionsHeader = NSTextField(labelWithString: "Accessibility Permissions")
        permissionsHeader.frame = NSRect(x: 20, y: 520, width: 560, height: 20)
        permissionsHeader.font = .systemFont(ofSize: 13, weight: .semibold)
        addSubview(permissionsHeader)

        // Status indicator (colored circle)
        permissionStatusIndicator = NSTextField(labelWithString: "●")
        permissionStatusIndicator.frame = NSRect(x: 20, y: 492, width: 20, height: 20)
        permissionStatusIndicator.font = .systemFont(ofSize: 16)
        permissionStatusIndicator.alignment = .center
        addSubview(permissionStatusIndicator)

        // Status label
        permissionStatusLabel = NSTextField(labelWithString: "Checking permissions...")
        permissionStatusLabel.frame = NSRect(x: 45, y: 495, width: 300, height: 16)
        permissionStatusLabel.font = .systemFont(ofSize: 12)
        addSubview(permissionStatusLabel)

        // Open Settings button
        openSettingsButton = NSButton(frame: NSRect(x: 360, y: 490, width: 160, height: 24))
        openSettingsButton.title = "Open System Settings"
        openSettingsButton.bezelStyle = .rounded
        openSettingsButton.target = self
        openSettingsButton.action = #selector(openSystemSettings)
        addSubview(openSettingsButton)

        // Bundle path label
        let pathLabel = NSTextField(labelWithString: "App Location:")
        pathLabel.frame = NSRect(x: 20, y: 468, width: 100, height: 16)
        pathLabel.font = .systemFont(ofSize: 11)
        pathLabel.textColor = .secondaryLabelColor
        addSubview(pathLabel)

        // Bundle path field (selectable, copyable)
        bundlePathField = NSTextField(labelWithString: Bundle.main.bundlePath)
        bundlePathField.frame = NSRect(x: 120, y: 468, width: 340, height: 16)
        bundlePathField.font = .systemFont(ofSize: 10, weight: .regular)
        bundlePathField.textColor = .secondaryLabelColor
        bundlePathField.isSelectable = true
        bundlePathField.isEditable = false
        bundlePathField.isBordered = false
        bundlePathField.backgroundColor = .clear
        addSubview(bundlePathField)

        // Copy path button
        copyPathButton = NSButton(frame: NSRect(x: 470, y: 465, width: 50, height: 20))
        copyPathButton.title = "Copy"
        copyPathButton.bezelStyle = .rounded
        copyPathButton.font = .systemFont(ofSize: 10)
        copyPathButton.target = self
        copyPathButton.action = #selector(copyBundlePath)
        addSubview(copyPathButton)

        // Separator line
        let separator = NSBox(frame: NSRect(x: 20, y: 455, width: 560, height: 1))
        separator.boxType = .separator
        addSubview(separator)

        // MARK: - Display & Preset Settings

        // Display selector label
        let displayLabel = NSTextField(labelWithString: "Display:")
        displayLabel.frame = NSRect(x: 20, y: 425, width: 100, height: 20)
        addSubview(displayLabel)

        // Display popup button
        displayPopup = NSPopUpButton(frame: NSRect(x: 120, y: 420, width: 400, height: 25))
        displayPopup.target = self
        displayPopup.action = #selector(displayChanged)
        addSubview(displayPopup)

        // Preset selector label
        let presetLabel = NSTextField(labelWithString: "Zone Preset:")
        presetLabel.frame = NSRect(x: 20, y: 385, width: 100, height: 20)
        addSubview(presetLabel)

        // Preset popup button
        presetPopup = NSPopUpButton(frame: NSRect(x: 120, y: 380, width: 400, height: 25))
        presetPopup.target = self
        presetPopup.action = #selector(presetChanged)
        addSubview(presetPopup)

        // Populate preset popup
        for preset in ZonePreset.allCases {
            presetPopup.addItem(withTitle: preset.rawValue)
        }

        // Description label
        descriptionLabel = NSTextField(wrappingLabelWithString: "")
        descriptionLabel.frame = NSRect(x: 20, y: 315, width: 560, height: 50)
        descriptionLabel.alignment = .left
        descriptionLabel.textColor = .secondaryLabelColor
        addSubview(descriptionLabel)

        // Zone preview
        previewView = ZonePreviewView()
        previewView.frame = NSRect(x: 20, y: 20, width: 560, height: 280)
        addSubview(previewView)

        // Start permission monitoring
        updatePermissionStatus()
        startPermissionMonitoring()
    }

    private func loadDisplays() {
        displayPopup.removeAllItems()

        let screens = ScreenManager.shared.screens
        for (index, screen) in screens.enumerated() {
            let identifier = ScreenManager.shared.getDisplayIdentifier(for: screen)
            let title = screen.localizedName + (identifier.isPrimary ? " (Primary)" : "")
            displayPopup.addItem(withTitle: title)

            // Store identifier as represented object
            displayPopup.item(at: index)?.representedObject = identifier
        }

        // Select first display
        if screens.count > 0 {
            displayPopup.selectItem(at: 0)
            displayChanged()
        }
    }

    @objc private func displayChanged() {
        guard let selectedItem = displayPopup.selectedItem,
              let identifier = selectedItem.representedObject as? DisplayIdentifier else {
            return
        }

        selectedDisplayIdentifier = identifier

        // Load preset for this display
        let preset = ConfigurationManager.shared.getPreset(for: identifier)
        presetPopup.selectItem(withTitle: preset.rawValue)

        updatePreview()
        updateDescription()
    }

    @objc private func presetChanged() {
        guard let selectedDisplayIdentifier = selectedDisplayIdentifier,
              let presetTitle = presetPopup.titleOfSelectedItem,
              let preset = ZonePreset.allCases.first(where: { $0.rawValue == presetTitle }) else {
            return
        }

        // Save preset
        ConfigurationManager.shared.setPreset(preset, for: selectedDisplayIdentifier)

        updatePreview()
        updateDescription()

        AppLogger.settings.debug("Preset changed to \(preset.rawValue)")
    }

    private func updatePreview() {
        guard let selectedDisplayIdentifier = selectedDisplayIdentifier,
              let screen = findScreen(for: selectedDisplayIdentifier) else {
            return
        }

        let preset = ConfigurationManager.shared.getPreset(for: selectedDisplayIdentifier)
        previewView.updateZones(for: preset, on: screen)
    }

    private func updateDescription() {
        guard let presetTitle = presetPopup.titleOfSelectedItem,
              let preset = ZonePreset.allCases.first(where: { $0.rawValue == presetTitle }) else {
            return
        }

        let descriptions: [ZonePreset: String] = [
            .thirds: "Three equal columns (33% each). Classic ultrawide layout.",
            .halves: "Two equal columns (50% each). Simple left/right split.",
            .quarters: "2×2 grid with four zones. Great for multitasking.",
            .wideLeft: "Left column is wider (40/30/30). Perfect for IDE on left.",
            .wideCenter: "Center column is wider (30/40/30). Great for browser-focused work.",
            .verticalHalves: "Top and bottom split (50/50). Best for vertical monitors.",
            .verticalThirds: "Three horizontal rows (33% each). Vertical monitor stacking.",
            .grid: "2×3 grid with six zones. Maximum organization."
        ]

        descriptionLabel.stringValue = descriptions[preset] ?? ""
    }

    private func findScreen(for identifier: DisplayIdentifier) -> NSScreen? {
        return ScreenManager.shared.screens.first { screen in
            let screenIdentifier = ScreenManager.shared.getDisplayIdentifier(for: screen)
            return screenIdentifier == identifier
        }
    }

    // MARK: - Permission Status Monitoring

    private func startPermissionMonitoring() {
        // Check permissions every 2 seconds to detect changes
        permissionCheckTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            self?.updatePermissionStatus()
        }
    }

    private func updatePermissionStatus() {
        let hasPermission = AXIsProcessTrusted()

        DispatchQueue.main.async { [weak self] in
            if hasPermission {
                // Green indicator - permissions granted
                self?.permissionStatusIndicator.stringValue = "●"
                self?.permissionStatusIndicator.textColor = NSColor(red: 0.2, green: 0.8, blue: 0.3, alpha: 1.0)
                self?.permissionStatusLabel.stringValue = "Granted ✓  UltraSnap can manage windows"
                self?.permissionStatusLabel.textColor = .labelColor
                self?.openSettingsButton.isHidden = true
            } else {
                // Red indicator - permissions not granted
                self?.permissionStatusIndicator.stringValue = "●"
                self?.permissionStatusIndicator.textColor = NSColor(red: 0.9, green: 0.2, blue: 0.2, alpha: 1.0)
                self?.permissionStatusLabel.stringValue = "Required  Window snapping will not work"
                self?.permissionStatusLabel.textColor = NSColor(red: 0.9, green: 0.2, blue: 0.2, alpha: 1.0)
                self?.openSettingsButton.isHidden = false
            }
        }
    }

    @objc private func openSystemSettings() {
        // Open System Settings to Privacy & Security > Accessibility
        // This URL scheme works on macOS 13+ (Ventura and later)
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
            NSWorkspace.shared.open(url)
        }
    }

    @objc private func copyBundlePath() {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(Bundle.main.bundlePath, forType: .string)

        // Provide visual feedback
        copyPathButton.title = "Copied!"
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
            self?.copyPathButton.title = "Copy"
        }
    }

    deinit {
        permissionCheckTimer?.invalidate()
    }
}
