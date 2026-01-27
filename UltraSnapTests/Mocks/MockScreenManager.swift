import Cocoa
@testable import UltraSnap

class MockScreenManager: ScreenProviding {
    var screens: [NSScreen] = []
    var screenToReturn: NSScreen?
    var refreshCalled = false
    var lastPointQueried: CGPoint?

    func screenContaining(point: CGPoint) -> NSScreen? {
        lastPointQueried = point
        return screenToReturn
    }

    func refreshScreenCache() {
        refreshCalled = true
    }

    func getDisplayID(for screen: NSScreen) -> CGDirectDisplayID? {
        return 1 // Mock display ID
    }

    // MARK: - Test Helpers

    func reset() {
        screens = []
        screenToReturn = nil
        refreshCalled = false
        lastPointQueried = nil
    }

    func setupSingleScreen(frame: CGRect = CGRect(x: 0, y: 0, width: 1920, height: 1080)) -> NSScreen? {
        // Create a mock screen - in real tests we'd use a proper mock NSScreen
        // For now, just return the main screen if available for basic functionality
        screenToReturn = NSScreen.main
        if screenToReturn != nil {
            screens = [screenToReturn!]
        }
        return screenToReturn
    }

    func setupMultipleScreens(count: Int = 2) {
        // For basic mock functionality
        if let mainScreen = NSScreen.main {
            screens = Array(repeating: mainScreen, count: count)
            screenToReturn = mainScreen
        }
    }
}