import Cocoa
import KeyboardShortcuts

class KeyboardSettingsView: NSView {

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
        let titleLabel = NSTextField(labelWithString: "Keyboard Shortcuts")
        titleLabel.font = NSFont.systemFont(ofSize: 16, weight: .bold)
        titleLabel.frame = NSRect(x: 20, y: 420, width: 560, height: 25)
        addSubview(titleLabel)

        // Description
        let descLabel = NSTextField(wrappingLabelWithString: "Customize global keyboard shortcuts for window snapping. Click on a shortcut field to record a new combination.")
        descLabel.frame = NSRect(x: 20, y: 370, width: 560, height: 40)
        descLabel.textColor = .secondaryLabelColor
        addSubview(descLabel)

        var yPosition: CGFloat = 320

        // Snap Left shortcut
        addShortcutRecorder(
            label: "Snap Left:",
            name: .snapLeftThird,
            yPosition: yPosition
        )
        yPosition -= 40

        // Snap Center shortcut
        addShortcutRecorder(
            label: "Snap Center:",
            name: .snapCenterThird,
            yPosition: yPosition
        )
        yPosition -= 40

        // Snap Right shortcut
        addShortcutRecorder(
            label: "Snap Right:",
            name: .snapRightThird,
            yPosition: yPosition
        )
        yPosition -= 60

        // Reset button
        let resetButton = NSButton(frame: NSRect(x: 20, y: yPosition, width: 200, height: 30))
        resetButton.title = "Reset to Defaults"
        resetButton.bezelStyle = .rounded
        resetButton.target = self
        resetButton.action = #selector(resetToDefaults)
        addSubview(resetButton)
    }

    private func addShortcutRecorder(label: String, name: KeyboardShortcuts.Name, yPosition: CGFloat) {
        // Label
        let labelField = NSTextField(labelWithString: label)
        labelField.frame = NSRect(x: 20, y: yPosition, width: 150, height: 20)
        labelField.alignment = .right
        addSubview(labelField)

        // Recorder (from KeyboardShortcuts library)
        let recorder = KeyboardShortcuts.RecorderCocoa(for: name)
        recorder.frame = NSRect(x: 180, y: yPosition - 5, width: 200, height: 30)
        addSubview(recorder)
    }

    @objc private func resetToDefaults() {
        // Reset all shortcuts to defaults
        KeyboardShortcuts.reset(.snapLeftThird)
        KeyboardShortcuts.reset(.snapCenterThird)
        KeyboardShortcuts.reset(.snapRightThird)

        // Show confirmation
        let alert = NSAlert()
        alert.messageText = "Shortcuts Reset"
        alert.informativeText = "All keyboard shortcuts have been reset to their default values."
        alert.alertStyle = .informational
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }
}
