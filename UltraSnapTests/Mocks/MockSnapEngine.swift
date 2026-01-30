import Cocoa
@testable import UltraSnap

/// Mock SnapEngine for unit testing
/// Tracks snap operations without actually manipulating windows
class MockSnapEngine: SnapEngine {
    var snapCalled = false
    var lastZoneIndex: Int?
    var callCount = 0

    override func snapFrontmostWindowToZone(at zoneIndex: Int) -> Bool {
        snapCalled = true
        lastZoneIndex = zoneIndex
        callCount += 1
        return true
    }

    // Test helper methods
    func reset() {
        snapCalled = false
        lastZoneIndex = nil
        callCount = 0
    }

    func verifySnapCalled(forZone expectedZoneIndex: Int) -> Bool {
        return snapCalled && lastZoneIndex == expectedZoneIndex
    }
}
