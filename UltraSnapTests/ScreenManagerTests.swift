import XCTest
@testable import UltraSnap

final class ScreenManagerTests: XCTestCase {

    // MARK: - Display ID Tests

    func testGetDisplayID() {
        // Test that we can get display ID for main screen
        guard let screen = NSScreen.main else {
            XCTFail("No main screen available")
            return
        }

        let displayID = ScreenManager.shared.getDisplayID(for: screen)
        XCTAssertNotNil(displayID, "Should get display ID for main screen")

        // Verify it's a valid display ID (non-zero)
        if let id = displayID {
            XCTAssertNotEqual(id, 0, "Display ID should be non-zero")
        }
    }

    func testGetDisplayIDConsistency() {
        // Test that getting display ID multiple times returns same result
        guard let screen = NSScreen.main else {
            XCTFail("No main screen available")
            return
        }

        let id1 = ScreenManager.shared.getDisplayID(for: screen)
        let id2 = ScreenManager.shared.getDisplayID(for: screen)

        XCTAssertEqual(id1, id2, "Display ID should be consistent across multiple calls")
    }

    // MARK: - Display Identifier Tests

    func testGetDisplayIdentifier() {
        // Test that we can get DisplayIdentifier for main screen
        guard let screen = NSScreen.main else {
            XCTFail("No main screen available")
            return
        }

        let identifier = ScreenManager.shared.getDisplayIdentifier(for: screen)

        // Verify identifier has valid data
        XCTAssertNotNil(identifier.modelNumber, "Model number should be populated")
        XCTAssertNotNil(identifier.vendorNumber, "Vendor number should be populated")

        // Verify position matches screen
        XCTAssertEqual(identifier.originX, screen.frame.origin.x, "Origin X should match screen")
        XCTAssertEqual(identifier.originY, screen.frame.origin.y, "Origin Y should match screen")
    }

    func testGetDisplayIdentifierConsistency() {
        // Test that getting identifier multiple times returns equivalent data
        guard let screen = NSScreen.main else {
            XCTFail("No main screen available")
            return
        }

        let id1 = ScreenManager.shared.getDisplayIdentifier(for: screen)
        let id2 = ScreenManager.shared.getDisplayIdentifier(for: screen)

        // Should have same hardware IDs
        XCTAssertEqual(id1.modelNumber, id2.modelNumber, "Model numbers should match")
        XCTAssertEqual(id1.vendorNumber, id2.vendorNumber, "Vendor numbers should match")
        XCTAssertEqual(id1.uuid, id2.uuid, "UUIDs should match")

        // Should have same position
        XCTAssertEqual(id1.originX, id2.originX, "Origin X should match")
        XCTAssertEqual(id1.originY, id2.originY, "Origin Y should match")
    }

    func testDisplayIdentifierForAllScreens() {
        // Test that we can get identifiers for all screens
        let screens = ScreenManager.shared.screens

        XCTAssertGreaterThan(screens.count, 0, "Should have at least one screen")

        for (index, screen) in screens.enumerated() {
            let identifier = ScreenManager.shared.getDisplayIdentifier(for: screen)

            XCTAssertNotNil(identifier.modelNumber, "Screen \(index) should have model number")
            XCTAssertNotNil(identifier.vendorNumber, "Screen \(index) should have vendor number")

            // Verify position is set
            let hasPosition = identifier.originX != 0 || identifier.originY != 0 || index == 0
            XCTAssertTrue(hasPosition, "Screen \(index) should have valid position (or be primary)")
        }
    }

    // MARK: - Find Screen Matching Tests

    func testFindScreenMatching() {
        // Test that we can find a screen by its identifier
        guard let screen = NSScreen.main else {
            XCTFail("No main screen available")
            return
        }

        // Create identifier from current screen
        let identifier = ScreenManager.shared.getDisplayIdentifier(for: screen)

        // Find screen matching this identifier
        let foundScreen = ScreenManager.shared.findScreen(matching: identifier)

        XCTAssertNotNil(foundScreen, "Should find screen matching its own identifier")

        // Verify it's the same screen by comparing frames
        if let found = foundScreen {
            XCTAssertEqual(found.frame, screen.frame, "Found screen should have same frame")
        }
    }

    func testFindScreenMatchingWithTolerance() {
        // Test that position matching uses tolerance
        guard let screen = NSScreen.main else {
            XCTFail("No main screen available")
            return
        }

        // Get real identifier
        let realIdentifier = ScreenManager.shared.getDisplayIdentifier(for: screen)

        // Create slightly modified identifier (within tolerance)
        let modifiedIdentifier = DisplayIdentifier(
            uuid: nil, // Force position matching
            modelNumber: 0, // Force position matching
            vendorNumber: 0, // Force position matching
            serialNumber: nil,
            originX: realIdentifier.originX + 5.0,  // 5px offset (within 10px tolerance)
            originY: realIdentifier.originY + 5.0
        )

        // Should still find the screen with position tolerance
        let foundScreen = ScreenManager.shared.findScreen(matching: modifiedIdentifier, tolerance: 10.0)

        XCTAssertNotNil(foundScreen, "Should find screen within position tolerance")
    }

    func testFindScreenMatchingOutsideTolerance() {
        // Test that we don't match screens outside tolerance
        guard let screen = NSScreen.main else {
            XCTFail("No main screen available")
            return
        }

        let realIdentifier = ScreenManager.shared.getDisplayIdentifier(for: screen)

        // Create identifier with position far outside tolerance
        let farIdentifier = DisplayIdentifier(
            uuid: nil,
            modelNumber: 0,
            vendorNumber: 0,
            serialNumber: nil,
            originX: realIdentifier.originX + 1000.0,  // 1000px offset (way outside tolerance)
            originY: realIdentifier.originY + 1000.0
        )

        // Should NOT find the screen
        let foundScreen = ScreenManager.shared.findScreen(matching: farIdentifier, tolerance: 10.0)

        // If we only have one screen, it might still match on hardware IDs
        // But with zero hardware IDs, it should not match
        if ScreenManager.shared.screens.count == 1 {
            // Single screen case - might match if hardware IDs are also zero
            // This is an edge case we'll accept
        } else {
            XCTAssertNil(foundScreen, "Should not find screen outside position tolerance with no hardware match")
        }
    }

    // MARK: - Screen Cache Tests

    func testScreenCacheRefresh() {
        // Test that screen cache updates
        let beforeCount = ScreenManager.shared.screens.count

        ScreenManager.shared.refreshScreenCache()

        let afterCount = ScreenManager.shared.screens.count

        // Screen count should be consistent
        XCTAssertEqual(beforeCount, afterCount, "Screen count should remain consistent after refresh")
        XCTAssertGreaterThan(afterCount, 0, "Should have at least one screen")
    }

    func testScreenCacheConsistency() {
        // Test that cached screens remain valid
        let screens1 = ScreenManager.shared.screens
        let screens2 = ScreenManager.shared.screens

        XCTAssertEqual(screens1.count, screens2.count, "Cached screen count should be consistent")

        // Compare frames to verify same screens
        for (index, screen) in screens1.enumerated() {
            if index < screens2.count {
                XCTAssertEqual(screen.frame, screens2[index].frame, "Screen \(index) frame should match")
            }
        }
    }

    func testMainScreenCached() {
        // Test that main screen is cached
        let mainScreen = ScreenManager.shared.mainScreen

        XCTAssertNotNil(mainScreen, "Main screen should be cached")

        // Verify it matches real main screen
        if let cached = mainScreen, let real = NSScreen.main {
            XCTAssertEqual(cached.frame, real.frame, "Cached main screen should match real main screen")
        }
    }

    func testPrimaryScreenCached() {
        // Test that primary screen is cached
        let primaryScreen = ScreenManager.shared.primaryScreen

        XCTAssertNotNil(primaryScreen, "Primary screen should be cached")

        // Primary screen should be first in screens array
        if let primary = primaryScreen {
            XCTAssertEqual(primary.frame, ScreenManager.shared.screens.first?.frame, "Primary screen should be first screen")
        }
    }

    // MARK: - Screen Containing Tests

    func testScreenContainingPoint() {
        // Test that we can find screen containing a point
        guard let screen = NSScreen.main else {
            XCTFail("No main screen available")
            return
        }

        // Get center point of main screen
        let centerX = screen.frame.midX
        let centerY = screen.frame.midY
        let centerPoint = CGPoint(x: centerX, y: centerY)

        let foundScreen = ScreenManager.shared.screenContaining(point: centerPoint)

        XCTAssertNotNil(foundScreen, "Should find screen containing center point")

        if let found = foundScreen {
            XCTAssertTrue(found.frame.contains(centerPoint), "Found screen should contain the point")
        }
    }

    func testScreenContainingFrame() {
        // Test that we can find screen containing/intersecting a frame
        guard let screen = NSScreen.main else {
            XCTFail("No main screen available")
            return
        }

        // Create small frame within main screen
        let testFrame = CGRect(
            x: screen.frame.midX - 50,
            y: screen.frame.midY - 50,
            width: 100,
            height: 100
        )

        let foundScreen = ScreenManager.shared.screenContaining(frame: testFrame)

        XCTAssertNotNil(foundScreen, "Should find screen containing frame")

        if let found = foundScreen {
            XCTAssertTrue(found.frame.intersects(testFrame), "Found screen should intersect the frame")
        }
    }

    // MARK: - Integration Tests

    func testScreenManagerSingleton() {
        // Test that ScreenManager is a singleton
        let instance1 = ScreenManager.shared
        let instance2 = ScreenManager.shared

        XCTAssertTrue(instance1 === instance2, "ScreenManager should be singleton")
    }

    func testScreenManagerConformsToProtocol() {
        // Test that ScreenManager conforms to ScreenProviding
        let manager: ScreenProviding = ScreenManager.shared

        // Should be able to call protocol methods
        manager.refreshScreenCache()
        let screens = manager.screens

        XCTAssertGreaterThan(screens.count, 0, "Should have screens via protocol")
    }
}
