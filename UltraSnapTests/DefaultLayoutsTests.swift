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
}
