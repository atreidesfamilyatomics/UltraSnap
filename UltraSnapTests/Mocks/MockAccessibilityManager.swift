import Cocoa
@testable import UltraSnap

class MockAccessibilityManager: WindowManaging {
    var hasAccessibilityPermissions = true
    var mockWindow: AXUIElement?
    var setFrameCalled = false
    var lastSetFrame: CGRect?
    var mockWindowFrame: CGRect?
    var getFrontmostWindowCalled = false

    func checkAccessibilityPermissions() -> Bool {
        return hasAccessibilityPermissions
    }

    func getFrontmostWindow() -> AXUIElement? {
        getFrontmostWindowCalled = true
        return mockWindow
    }

    func setWindowFrame(_ element: AXUIElement, to frame: CGRect) -> Bool {
        setFrameCalled = true
        lastSetFrame = frame
        return hasAccessibilityPermissions // Simulate failure if no permissions
    }

    func getWindowFrame(_ element: AXUIElement) -> CGRect? {
        return mockWindowFrame ?? CGRect(x: 0, y: 0, width: 800, height: 600)
    }

    // MARK: - Test Helpers

    func reset() {
        hasAccessibilityPermissions = true
        mockWindow = nil
        setFrameCalled = false
        lastSetFrame = nil
        mockWindowFrame = nil
        getFrontmostWindowCalled = false
    }

    func simulateAccessibilityPermissionsDenied() {
        hasAccessibilityPermissions = false
    }

    func simulateWindowAvailable(frame: CGRect = CGRect(x: 100, y: 100, width: 800, height: 600)) {
        // Create a mock AXUIElement - this is a bit tricky since AXUIElement is opaque
        // For testing purposes, we'll create a dummy reference
        let app = NSRunningApplication.current
        mockWindow = AXUIElementCreateApplication(app.processIdentifier)
        mockWindowFrame = frame
    }

    func simulateNoWindow() {
        mockWindow = nil
    }
}