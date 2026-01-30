import Cocoa
import os.log

class GeneralSettingsView: NSView {

    private var launchAtLoginCheckbox: NSButton!
    private var showPreviewCheckbox: NSButton!

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setupUI()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }

    private func setupUI() {
        // Title
        let titleLabel = NSTextField(labelWithString: "General Settings")
        titleLabel.font = NSFont.systemFont(ofSize: 16, weight: .bold)
        titleLabel.frame = NSRect(x: 20, y: 420, width: 560, height: 25)
        addSubview(titleLabel)

        var yPosition: CGFloat = 370

        // Launch at login (placeholder - Phase 3)
        launchAtLoginCheckbox = NSButton(checkboxWithTitle: "Launch at Login", target: self, action: #selector(launchAtLoginChanged))
        launchAtLoginCheckbox.frame = NSRect(x: 20, y: yPosition, width: 200, height: 20)
        launchAtLoginCheckbox.state = .off  // TODO(v2.0): Load from LoginItem API - see NEXT_STEPS.md
        launchAtLoginCheckbox.isEnabled = false  // Disabled for Phase 2
        addSubview(launchAtLoginCheckbox)

        let launchNote = NSTextField(wrappingLabelWithString: "(Coming in Phase 3)")
        launchNote.frame = NSRect(x: 40, y: yPosition - 20, width: 200, height: 15)
        launchNote.font = NSFont.systemFont(ofSize: 10)
        launchNote.textColor = .secondaryLabelColor
        addSubview(launchNote)
        yPosition -= 60

        // Show preview overlay
        showPreviewCheckbox = NSButton(checkboxWithTitle: "Show Zone Preview While Dragging", target: self, action: #selector(showPreviewChanged))
        showPreviewCheckbox.frame = NSRect(x: 20, y: yPosition, width: 300, height: 20)
        showPreviewCheckbox.state = UserDefaults.standard.bool(forKey: "showPreview") ? .on : .off
        addSubview(showPreviewCheckbox)
        yPosition -= 60

        // About section
        let aboutLabel = NSTextField(labelWithString: "About UltraSnap")
        aboutLabel.font = NSFont.systemFont(ofSize: 14, weight: .semibold)
        aboutLabel.frame = NSRect(x: 20, y: yPosition, width: 560, height: 20)
        addSubview(aboutLabel)
        yPosition -= 30

        let versionLabel = NSTextField(labelWithString: "Version 2.1 (Phase 2)")
        versionLabel.frame = NSRect(x: 20, y: yPosition, width: 560, height: 20)
        versionLabel.textColor = .secondaryLabelColor
        addSubview(versionLabel)
        yPosition -= 25

        let descriptionLabel = NSTextField(wrappingLabelWithString: "UltraSnap is a window management tool for ultrawide displays. Drag windows to the top of the screen or use keyboard shortcuts to snap them into customizable zones.")
        descriptionLabel.frame = NSRect(x: 20, y: yPosition - 40, width: 560, height: 60)
        descriptionLabel.textColor = .secondaryLabelColor
        addSubview(descriptionLabel)
    }

    @objc private func launchAtLoginChanged() {
        // TODO(v2.0): Implement using ServiceManagement.SMAppService - see NEXT_STEPS.md
    }

    @objc private func showPreviewChanged() {
        let enabled = showPreviewCheckbox.state == .on
        UserDefaults.standard.set(enabled, forKey: "showPreview")
        AppLogger.settings.debug("Show preview: \(enabled)")
    }
}
