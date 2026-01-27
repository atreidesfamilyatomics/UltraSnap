import Cocoa
import KeyboardShortcuts

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