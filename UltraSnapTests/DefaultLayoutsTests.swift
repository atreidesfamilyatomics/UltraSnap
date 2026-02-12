import XCTest
@testable import UltraSnap

final class DefaultLayoutsTests: XCTestCase {

    func testThirdsLayout() {
        guard let screen = NSScreen.main else {
            XCTFail("No main screen available")
            return
        }

        let zones = DefaultLayouts.zones(for: .thirds, on: screen)

        XCTAssertEqual(zones.count, 3)

        // Verify zones span the full screen width
        let totalWidth = zones.reduce(0) { $0 + $1.width }
        XCTAssertEqual(totalWidth, screen.visibleFrame.width, accuracy: 1.0)
    }

    func testHalvesLayout() {
        guard let screen = NSScreen.main else {
            XCTFail("No main screen available")
            return
        }

        let zones = DefaultLayouts.zones(for: .halves, on: screen)

        XCTAssertEqual(zones.count, 2)

        // Each zone should be half the screen width
        for zone in zones {
            XCTAssertEqual(zone.width, screen.visibleFrame.width / 2, accuracy: 1.0)
        }
    }

    func testQuartersLayout() {
        guard let screen = NSScreen.main else {
            XCTFail("No main screen available")
            return
        }

        let zones = DefaultLayouts.zones(for: .quarters, on: screen)

        XCTAssertEqual(zones.count, 4)

        // Each zone should be quarter of screen area
        let quarterArea = (screen.visibleFrame.width / 2) * (screen.visibleFrame.height / 2)
        for zone in zones {
            XCTAssertEqual(zone.width * zone.height, quarterArea, accuracy: 1.0)
        }
    }

    func testZonesUseVisibleFrame() {
        guard let screen = NSScreen.main else {
            XCTFail("No main screen available")
            return
        }

        let zones = DefaultLayouts.zones(for: .thirds, on: screen)

        // All zones should be within visible frame (accounts for menu bar)
        for zone in zones {
            XCTAssertTrue(screen.visibleFrame.contains(zone))
        }
    }

    func testWideLeftLayout() {
        guard let screen = NSScreen.main else {
            XCTFail("No main screen available")
            return
        }

        let zones = DefaultLayouts.zones(for: .wideLeft, on: screen)

        XCTAssertEqual(zones.count, 3)
        XCTAssertEqual(zones[0].width, screen.visibleFrame.width * 0.4, accuracy: 1.0)
        XCTAssertEqual(zones[1].width, screen.visibleFrame.width * 0.3, accuracy: 1.0)
        XCTAssertEqual(zones[2].width, screen.visibleFrame.width * 0.3, accuracy: 1.0)

        // Verify zones span the full screen width
        let totalWidth = zones.reduce(0) { $0 + $1.width }
        XCTAssertEqual(totalWidth, screen.visibleFrame.width, accuracy: 1.0)
    }

    func testWideCenterLayout() {
        guard let screen = NSScreen.main else {
            XCTFail("No main screen available")
            return
        }

        let zones = DefaultLayouts.zones(for: .wideCenter, on: screen)

        XCTAssertEqual(zones.count, 3)
        XCTAssertEqual(zones[0].width, screen.visibleFrame.width * 0.3, accuracy: 1.0)
        XCTAssertEqual(zones[1].width, screen.visibleFrame.width * 0.4, accuracy: 1.0)
        XCTAssertEqual(zones[2].width, screen.visibleFrame.width * 0.3, accuracy: 1.0)

        // Verify zones span the full screen width
        let totalWidth = zones.reduce(0) { $0 + $1.width }
        XCTAssertEqual(totalWidth, screen.visibleFrame.width, accuracy: 1.0)
    }

    func testVerticalHalvesLayout() {
        guard let screen = NSScreen.main else {
            XCTFail("No main screen available")
            return
        }

        let zones = DefaultLayouts.zones(for: .verticalHalves, on: screen)

        XCTAssertEqual(zones.count, 2)
        XCTAssertEqual(zones[0].height, screen.visibleFrame.height / 2, accuracy: 1.0)
        XCTAssertEqual(zones[1].height, screen.visibleFrame.height / 2, accuracy: 1.0)

        // Verify zones span full screen height
        let totalHeight = zones.reduce(0) { $0 + $1.height }
        XCTAssertEqual(totalHeight, screen.visibleFrame.height, accuracy: 1.0)

        // All zones should be full width
        for zone in zones {
            XCTAssertEqual(zone.width, screen.visibleFrame.width, accuracy: 1.0)
        }
    }

    func testVerticalThirdsLayout() {
        guard let screen = NSScreen.main else {
            XCTFail("No main screen available")
            return
        }

        let zones = DefaultLayouts.zones(for: .verticalThirds, on: screen)

        XCTAssertEqual(zones.count, 3)
        XCTAssertEqual(zones[0].height, screen.visibleFrame.height / 3, accuracy: 1.0)
        XCTAssertEqual(zones[1].height, screen.visibleFrame.height / 3, accuracy: 1.0)
        XCTAssertEqual(zones[2].height, screen.visibleFrame.height / 3, accuracy: 1.0)

        // Verify zones span full screen height
        let totalHeight = zones.reduce(0) { $0 + $1.height }
        XCTAssertEqual(totalHeight, screen.visibleFrame.height, accuracy: 1.0)

        // All zones should be full width
        for zone in zones {
            XCTAssertEqual(zone.width, screen.visibleFrame.width, accuracy: 1.0)
        }
    }

    func testGridLayout() {
        guard let screen = NSScreen.main else {
            XCTFail("No main screen available")
            return
        }

        let zones = DefaultLayouts.zones(for: .grid, on: screen)

        XCTAssertEqual(zones.count, 6)

        // Each zone should be 1/2 width and 1/3 height
        for zone in zones {
            XCTAssertEqual(zone.width, screen.visibleFrame.width / 2, accuracy: 1.0)
            XCTAssertEqual(zone.height, screen.visibleFrame.height / 3, accuracy: 1.0)
        }
    }

    // MARK: - Asymmetric Layouts Tests

    func testLeftHalfRightQuarters() {
        guard let screen = NSScreen.main else {
            XCTFail("No main screen available")
            return
        }

        let zones = DefaultLayouts.zones(for: .leftHalfRightQuarters, on: screen)

        XCTAssertEqual(zones.count, 5, "Should have 5 zones")

        // Zone 0: Left half full height
        XCTAssertEqual(zones[0].width, screen.visibleFrame.width / 2, accuracy: 1.0)
        XCTAssertEqual(zones[0].height, screen.visibleFrame.height, accuracy: 1.0)

        // Zones 1-4: Right half as 2×2 grid
        for i in 1...4 {
            XCTAssertEqual(zones[i].width, screen.visibleFrame.width / 4, accuracy: 1.0)
            XCTAssertEqual(zones[i].height, screen.visibleFrame.height / 2, accuracy: 1.0)
        }

        // Verify zones cover full screen
        assertZonesCoverScreen(zones, on: screen)
    }

    func testRightHalfLeftQuarters() {
        guard let screen = NSScreen.main else {
            XCTFail("No main screen available")
            return
        }

        let zones = DefaultLayouts.zones(for: .rightHalfLeftQuarters, on: screen)

        XCTAssertEqual(zones.count, 5, "Should have 5 zones")

        // Zones 0-3: Left half as 2×2 grid
        for i in 0...3 {
            XCTAssertEqual(zones[i].width, screen.visibleFrame.width / 4, accuracy: 1.0)
            XCTAssertEqual(zones[i].height, screen.visibleFrame.height / 2, accuracy: 1.0)
        }

        // Zone 4: Right half full height
        XCTAssertEqual(zones[4].width, screen.visibleFrame.width / 2, accuracy: 1.0)
        XCTAssertEqual(zones[4].height, screen.visibleFrame.height, accuracy: 1.0)

        // Verify zones cover full screen
        assertZonesCoverScreen(zones, on: screen)
    }

    func testTopHalfBottomQuarters() {
        guard let screen = NSScreen.main else {
            XCTFail("No main screen available")
            return
        }

        let zones = DefaultLayouts.zones(for: .topHalfBottomQuarters, on: screen)

        XCTAssertEqual(zones.count, 5, "Should have 5 zones")

        // Zone 0: Top half full width
        XCTAssertEqual(zones[0].width, screen.visibleFrame.width, accuracy: 1.0)
        XCTAssertEqual(zones[0].height, screen.visibleFrame.height / 2, accuracy: 1.0)

        // Zones 1-4: Bottom half as 2×2 grid
        for i in 1...4 {
            XCTAssertEqual(zones[i].width, screen.visibleFrame.width / 2, accuracy: 1.0)
            XCTAssertEqual(zones[i].height, screen.visibleFrame.height / 4, accuracy: 1.0)
        }

        // Verify zones cover full screen
        assertZonesCoverScreen(zones, on: screen)
    }

    func testBottomHalfTopQuarters() {
        guard let screen = NSScreen.main else {
            XCTFail("No main screen available")
            return
        }

        let zones = DefaultLayouts.zones(for: .bottomHalfTopQuarters, on: screen)

        XCTAssertEqual(zones.count, 5, "Should have 5 zones")

        // Zones 0-3: Top half as 2×2 grid
        for i in 0...3 {
            XCTAssertEqual(zones[i].width, screen.visibleFrame.width / 2, accuracy: 1.0)
            XCTAssertEqual(zones[i].height, screen.visibleFrame.height / 4, accuracy: 1.0)
        }

        // Zone 4: Bottom half full width
        XCTAssertEqual(zones[4].width, screen.visibleFrame.width, accuracy: 1.0)
        XCTAssertEqual(zones[4].height, screen.visibleFrame.height / 2, accuracy: 1.0)

        // Verify zones cover full screen
        assertZonesCoverScreen(zones, on: screen)
    }

    func testLeftTwoThirdsRightQuarters() {
        guard let screen = NSScreen.main else {
            XCTFail("No main screen available")
            return
        }

        let zones = DefaultLayouts.zones(for: .leftTwoThirdsRightQuarters, on: screen)

        XCTAssertEqual(zones.count, 5, "Should have 5 zones")

        // Zone 0: Left 2/3 full height
        XCTAssertEqual(zones[0].width, screen.visibleFrame.width * 2 / 3, accuracy: 1.0)
        XCTAssertEqual(zones[0].height, screen.visibleFrame.height, accuracy: 1.0)

        // Zones 1-4: Right 1/3 as 2×2 grid
        for i in 1...4 {
            XCTAssertEqual(zones[i].width, screen.visibleFrame.width / 6, accuracy: 1.0)
            XCTAssertEqual(zones[i].height, screen.visibleFrame.height / 2, accuracy: 1.0)
        }

        // Verify zones cover full screen
        assertZonesCoverScreen(zones, on: screen)
    }

    func testRightTwoThirdsLeftQuarters() {
        guard let screen = NSScreen.main else {
            XCTFail("No main screen available")
            return
        }

        let zones = DefaultLayouts.zones(for: .rightTwoThirdsLeftQuarters, on: screen)

        XCTAssertEqual(zones.count, 5, "Should have 5 zones")

        // Zones 0-3: Left 1/3 as 2×2 grid
        for i in 0...3 {
            XCTAssertEqual(zones[i].width, screen.visibleFrame.width / 6, accuracy: 1.0)
            XCTAssertEqual(zones[i].height, screen.visibleFrame.height / 2, accuracy: 1.0)
        }

        // Zone 4: Right 2/3 full height
        XCTAssertEqual(zones[4].width, screen.visibleFrame.width * 2 / 3, accuracy: 1.0)
        XCTAssertEqual(zones[4].height, screen.visibleFrame.height, accuracy: 1.0)

        // Verify zones cover full screen
        assertZonesCoverScreen(zones, on: screen)
    }

    func testLeftThirdRightSixths() {
        guard let screen = NSScreen.main else {
            XCTFail("No main screen available")
            return
        }

        let zones = DefaultLayouts.zones(for: .leftThirdRightSixths, on: screen)

        XCTAssertEqual(zones.count, 7, "Should have 7 zones")

        // Zone 0: Left 1/3 full height
        XCTAssertEqual(zones[0].width, screen.visibleFrame.width / 3, accuracy: 1.0)
        XCTAssertEqual(zones[0].height, screen.visibleFrame.height, accuracy: 1.0)

        // Zones 1-6: Right 2/3 as 2×3 grid
        for i in 1...6 {
            XCTAssertEqual(zones[i].width, screen.visibleFrame.width * 2 / 9, accuracy: 1.0)
            XCTAssertEqual(zones[i].height, screen.visibleFrame.height / 2, accuracy: 1.0)
        }

        // Verify zones cover full screen
        assertZonesCoverScreen(zones, on: screen)
    }

    func testRightThirdLeftSixths() {
        guard let screen = NSScreen.main else {
            XCTFail("No main screen available")
            return
        }

        let zones = DefaultLayouts.zones(for: .rightThirdLeftSixths, on: screen)

        XCTAssertEqual(zones.count, 7, "Should have 7 zones")

        // Zones 0-5: Left 2/3 as 2×3 grid
        for i in 0...5 {
            XCTAssertEqual(zones[i].width, screen.visibleFrame.width * 2 / 9, accuracy: 1.0)
            XCTAssertEqual(zones[i].height, screen.visibleFrame.height / 2, accuracy: 1.0)
        }

        // Zone 6: Right 1/3 full height
        XCTAssertEqual(zones[6].width, screen.visibleFrame.width / 3, accuracy: 1.0)
        XCTAssertEqual(zones[6].height, screen.visibleFrame.height, accuracy: 1.0)

        // Verify zones cover full screen
        assertZonesCoverScreen(zones, on: screen)
    }

    // MARK: - Grid Shape Tests

    func testGridShapeForSymmetricPresets() {
        // Test presets with uniform grids have correct grid shape
        XCTAssertEqual(ZonePreset.thirds.gridShape?.columns, 3)
        XCTAssertEqual(ZonePreset.thirds.gridShape?.rows, 1)

        XCTAssertEqual(ZonePreset.halves.gridShape?.columns, 2)
        XCTAssertEqual(ZonePreset.halves.gridShape?.rows, 1)

        XCTAssertEqual(ZonePreset.quarters.gridShape?.columns, 2)
        XCTAssertEqual(ZonePreset.quarters.gridShape?.rows, 2)

        XCTAssertEqual(ZonePreset.sixths.gridShape?.columns, 3)
        XCTAssertEqual(ZonePreset.sixths.gridShape?.rows, 2)

        XCTAssertEqual(ZonePreset.eighths.gridShape?.columns, 4)
        XCTAssertEqual(ZonePreset.eighths.gridShape?.rows, 2)

        XCTAssertEqual(ZonePreset.verticalHalves.gridShape?.columns, 1)
        XCTAssertEqual(ZonePreset.verticalHalves.gridShape?.rows, 2)

        XCTAssertEqual(ZonePreset.verticalThirds.gridShape?.columns, 1)
        XCTAssertEqual(ZonePreset.verticalThirds.gridShape?.rows, 3)

        XCTAssertEqual(ZonePreset.grid.gridShape?.columns, 2)
        XCTAssertEqual(ZonePreset.grid.gridShape?.rows, 3)
    }

    func testGridShapeForAsymmetricPresets() {
        // Asymmetric presets should not have grid shape (top-only triggers)
        XCTAssertNil(ZonePreset.leftHalfRightQuarters.gridShape)
        XCTAssertNil(ZonePreset.rightHalfLeftQuarters.gridShape)
        XCTAssertNil(ZonePreset.topHalfBottomQuarters.gridShape)
        XCTAssertNil(ZonePreset.bottomHalfTopQuarters.gridShape)
        XCTAssertNil(ZonePreset.leftTwoThirdsRightQuarters.gridShape)
        XCTAssertNil(ZonePreset.rightTwoThirdsLeftQuarters.gridShape)
        XCTAssertNil(ZonePreset.leftThirdRightSixths.gridShape)
        XCTAssertNil(ZonePreset.rightThirdLeftSixths.gridShape)
    }

    func testGridShapeForNonGridPresets() {
        // Variable-width presets should not have grid shape
        XCTAssertNil(ZonePreset.wideLeft.gridShape)
        XCTAssertNil(ZonePreset.wideCenter.gridShape)
        XCTAssertNil(ZonePreset.off.gridShape)
    }

    // MARK: - Helper Methods

    /// Verify that zones cover the entire visible screen without gaps or significant overlaps
    private func assertZonesCoverScreen(_ zones: [CGRect], on screen: NSScreen) {
        let visibleFrame = screen.visibleFrame

        // Calculate total area of all zones
        let totalZoneArea = zones.reduce(0) { $0 + ($1.width * $1.height) }
        let screenArea = visibleFrame.width * visibleFrame.height

        // Allow small rounding errors (within 1% of screen area)
        let tolerance = screenArea * 0.01
        XCTAssertEqual(totalZoneArea, screenArea, accuracy: tolerance,
                       "Zones should cover entire screen without significant gaps or overlaps")

        // Verify all zones are within visible frame
        for zone in zones {
            XCTAssertTrue(visibleFrame.contains(zone),
                          "Zone \(zone) should be within visible frame \(visibleFrame)")
        }
    }
}
