import XCTest
@testable import UltraSnap

final class UltraSnapTests: XCTestCase {

    func testTestInfrastructureWorks() {
        // Basic smoke test to verify test infrastructure is working
        XCTAssertTrue(true, "Test infrastructure is working")
        
        // Test basic Swift functionality
        let testString = "UltraSnap Testing"
        XCTAssertEqual(testString.count, 17)
    }

    func testMockScreenManagerConforms() {
        let mock = MockScreenManager()
        mock.screens = []
        XCTAssertEqual(mock.screens.count, 0)
        
        // Test protocol methods
        mock.refreshScreenCache()
        XCTAssertTrue(mock.refreshCalled)
        
        // Test screen containing logic
        let testPoint = CGPoint(x: 100, y: 100)
        _ = mock.screenContaining(point: testPoint)
        XCTAssertEqual(mock.lastPointQueried, testPoint)
    }

    func testMockAccessibilityManagerConforms() {
        let mock = MockAccessibilityManager()
        XCTAssertTrue(mock.checkAccessibilityPermissions())
        
        // Test permission denial simulation
        mock.simulateAccessibilityPermissionsDenied()
        XCTAssertFalse(mock.checkAccessibilityPermissions())
        
        // Test window management
        mock.simulateWindowAvailable()
        XCTAssertNotNil(mock.getFrontmostWindow())
        XCTAssertTrue(mock.getFrontmostWindowCalled)
        
        // Test window frame operations
        let testFrame = CGRect(x: 50, y: 50, width: 500, height: 400)
        if let window = mock.mockWindow {
            let success = mock.setWindowFrame(window, to: testFrame)
            XCTAssertFalse(success) // Should fail because permissions are denied
            XCTAssertTrue(mock.setFrameCalled)
            XCTAssertEqual(mock.lastSetFrame, testFrame)
        }
    }

    func testRealClassesConformToProtocols() {
        // Verify that real classes conform to their protocols
        let screenManager = ScreenManager.shared
        let _: ScreenProviding = screenManager // Compile-time check
        
        let accessibilityManager = AccessibilityManager.shared
        let _: WindowManaging = accessibilityManager // Compile-time check
        
        // Basic functional tests (these should work without accessibility permissions)
        XCTAssertNotNil(screenManager.screens)
        XCTAssertGreaterThanOrEqual(screenManager.screens.count, 1, "Should have at least one screen")
    }
}