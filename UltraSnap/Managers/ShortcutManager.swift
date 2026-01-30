import Cocoa
import KeyboardShortcuts

/// Manages global keyboard shortcuts for window snapping operations
///
/// ShortcutManager is a singleton that registers system-wide keyboard shortcuts
/// using the KeyboardShortcuts library. When a shortcut is triggered, it delegates
/// to SnapEngine to perform the actual window manipulation.
///
/// ## Usage
/// ```swift
/// // Configure with a SnapEngine instance (typically called from AppDelegate)
/// ShortcutManager.shared.configure(with: snapEngine)
///
/// // Temporarily disable shortcuts
/// ShortcutManager.shared.disable()
/// ```
///
/// ## Default Shortcuts
/// - `Control + Option + 1`: Snap to left third (zone 0)
/// - `Control + Option + 2`: Snap to center third (zone 1)
/// - `Control + Option + 3`: Snap to right third (zone 2)
///
/// Shortcuts can be customized in Settings via KeyboardShortcuts integration.
class ShortcutManager {
    static let shared = ShortcutManager()

    private var snapEngine: SnapEngine?
    private var isEnabled = true

    // Private init for singleton
    private init() {}

    // Configure with SnapEngine reference
    func configure(with snapEngine: SnapEngine) {
        self.snapEngine = snapEngine
        registerShortcuts()
    }

    private func registerShortcuts() {
        // Register zone 1 (first zone)
        KeyboardShortcuts.onKeyUp(for: .snapLeftThird) { [weak self] in
            guard let self = self, self.isEnabled else { return }
            self.snapEngine?.snapFrontmostWindowToZone(at: 0)
        }

        // Register zone 2 (second zone)
        KeyboardShortcuts.onKeyUp(for: .snapCenterThird) { [weak self] in
            guard let self = self, self.isEnabled else { return }
            self.snapEngine?.snapFrontmostWindowToZone(at: 1)
        }

        // Register zone 3 (third zone, if exists)
        KeyboardShortcuts.onKeyUp(for: .snapRightThird) { [weak self] in
            guard let self = self, self.isEnabled else { return }
            self.snapEngine?.snapFrontmostWindowToZone(at: 2)
        }
    }

    func enable() {
        isEnabled = true
    }

    func disable() {
        isEnabled = false
    }
}