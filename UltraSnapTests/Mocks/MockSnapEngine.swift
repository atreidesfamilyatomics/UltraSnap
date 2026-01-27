import Cocoa
@testable import UltraSnap

class MockSnapEngine: SnapEngine {
    var snapCalled = false
    var lastZone: SnapZone?
    var callCount = 0

    override func snapFrontmostWindowToZone(_ zone: SnapZone) -> Bool {
        snapCalled = true
        lastZone = zone
        callCount += 1
        return true
    }

    // Test helper methods
    func reset() {
        snapCalled = false
        lastZone = nil
        callCount = 0
    }

    func verifySnapCalled(forZone expectedZone: SnapZone) -> Bool {
        return snapCalled && lastZone == expectedZone
    }
}
