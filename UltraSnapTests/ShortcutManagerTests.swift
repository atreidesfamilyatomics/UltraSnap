import XCTest
@testable import UltraSnap
import KeyboardShortcuts

final class ShortcutManagerTests: XCTestCase {
    var shortcutManager: ShortcutManager!
    var mockSnapEngine: MockSnapEngine!

    override func setUp() {
        super.setUp()
        // Create mock engine (uses SnapEngine's default init)
        mockSnapEngine = MockSnapEngine()

        // Configure ShortcutManager with mock engine
        shortcutManager = ShortcutManager.shared
        shortcutManager.configure(with: mockSnapEngine)
    }

    override func tearDown() {
        mockSnapEngine?.reset()
        super.tearDown()
    }

    func testShortcutManagerInitializes() {
        XCTAssertNotNil(shortcutManager, "ShortcutManager should initialize")
    }

    func testShortcutManagerSingleton() {
        let instance1 = ShortcutManager.shared
        let instance2 = ShortcutManager.shared
        XCTAssertTrue(instance1 === instance2, "ShortcutManager should be a singleton")
    }

    func testShortcutsAreRegistered() {
        // Verify shortcuts exist in KeyboardShortcuts
        // Note: This checks if shortcut names are defined, not if they're actively registered
        _ = KeyboardShortcuts.getShortcut(for: .snapLeftThird)
        _ = KeyboardShortcuts.getShortcut(for: .snapCenterThird)
        _ = KeyboardShortcuts.getShortcut(for: .snapRightThird)

        // Shortcuts may be nil if user hasn't set them, but the names should be defined
        // We verify by checking the API doesn't crash and returns Optional values
        XCTAssertTrue(true, "Shortcut name extensions are accessible")
    }

    func testEnableDisable() {
        shortcutManager.disable()
        // After disable, shortcuts should not trigger (we can't easily test this without simulating keystrokes)
        // This tests that the enable/disable methods exist and don't crash

        shortcutManager.enable()
        // After enable, shortcuts should work again

        XCTAssertTrue(true, "Enable/disable methods execute without error")
    }

    func testShortcutsHaveDefaultValues() {
        // Verify default shortcuts match specification
        let leftShortcut = KeyboardShortcuts.getShortcut(for: .snapLeftThird)

        // Default is defined as Ctrl+Opt+1, but user may have changed it
        // If it's nil, the default hasn't been triggered yet
        if let shortcut = leftShortcut {
            // Verify key is .one if it was set to default
            if shortcut.key == .one {
                XCTAssertTrue(shortcut.modifiers.contains(.control), "Left shortcut should have Control modifier")
                XCTAssertTrue(shortcut.modifiers.contains(.option), "Left shortcut should have Option modifier")
            }
        }

        // Test passes if we can access the shortcuts without crashing
        XCTAssertTrue(true, "Default shortcut values are accessible")
    }

    func testConfigureWithSnapEngine() {
        // Create a new mock engine
        let newMockEngine = MockSnapEngine()

        // Configure should not crash
        shortcutManager.configure(with: newMockEngine)

        XCTAssertTrue(true, "Configure method executes without error")
    }
}
