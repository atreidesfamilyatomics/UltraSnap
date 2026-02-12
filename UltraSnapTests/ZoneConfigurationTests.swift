import XCTest
@testable import UltraSnap

final class ZoneConfigurationTests: XCTestCase {

    func testZonePresetRawValues() {
        XCTAssertEqual(ZonePreset.thirds.rawValue, "Equal Thirds")
        XCTAssertEqual(ZonePreset.halves.rawValue, "Halves")
        XCTAssertEqual(ZonePreset.quarters.rawValue, "Quarters")
    }

    func testZonePresetCounts() {
        XCTAssertEqual(ZonePreset.thirds.zoneCount, 3)
        XCTAssertEqual(ZonePreset.halves.zoneCount, 2)
        XCTAssertEqual(ZonePreset.quarters.zoneCount, 4)
    }

    func testDisplayConfigurationCreation() {
        let identifier = DisplayIdentifier(
            uuid: "TEST",
            modelNumber: 100,
            vendorNumber: 200,
            serialNumber: 300,
            originX: 0,
            originY: 0
        )

        let config = DisplayConfiguration(displayIdentifier: identifier, preset: .thirds)

        XCTAssertEqual(config.preset, .thirds)
        XCTAssertEqual(config.displayIdentifier, identifier)
    }

    func testZoneConfigurationCreation() {
        let identifier = DisplayIdentifier(
            uuid: "TEST",
            modelNumber: 100,
            vendorNumber: 200,
            serialNumber: 300,
            originX: 0,
            originY: 0
        )

        let displayConfig = DisplayConfiguration(displayIdentifier: identifier, preset: .halves)
        let zoneConfig = ZoneConfiguration(version: 1, displays: [displayConfig])

        XCTAssertEqual(zoneConfig.version, 1)
        XCTAssertEqual(zoneConfig.displays.count, 1)
    }

    func testDefaultConfiguration() {
        let config = ZoneConfiguration.defaultConfiguration(for: NSScreen.screens)

        XCTAssertEqual(config.version, 1)
        XCTAssertGreaterThan(config.displays.count, 0)

        // All displays should default to thirds
        for display in config.displays {
            XCTAssertEqual(display.preset, .thirds)
        }
    }

    func testGetPresetForDisplay() {
        let identifier = DisplayIdentifier(
            uuid: "TEST",
            modelNumber: 100,
            vendorNumber: 200,
            serialNumber: 300,
            originX: 0,
            originY: 0
        )

        let displayConfig = DisplayConfiguration(displayIdentifier: identifier, preset: .quarters)
        let zoneConfig = ZoneConfiguration(version: 1, displays: [displayConfig])

        let preset = zoneConfig.preset(for: identifier)
        XCTAssertEqual(preset, .quarters)
    }

    func testUpdatePresetForDisplay() {
        let identifier = DisplayIdentifier(
            uuid: "TEST",
            modelNumber: 100,
            vendorNumber: 200,
            serialNumber: 300,
            originX: 0,
            originY: 0
        )

        let displayConfig = DisplayConfiguration(displayIdentifier: identifier, preset: .thirds)
        let original = ZoneConfiguration(version: 1, displays: [displayConfig])

        let updated = original.updatingPreset(for: identifier, to: .halves)

        XCTAssertEqual(updated.preset(for: identifier), .halves)
        XCTAssertEqual(original.preset(for: identifier), .thirds) // Original unchanged
    }

    func testAddNewDisplayToConfiguration() {
        let identifier1 = DisplayIdentifier(uuid: "TEST1", modelNumber: 100, vendorNumber: 200, serialNumber: 300, originX: 0, originY: 0)
        let identifier2 = DisplayIdentifier(uuid: "TEST2", modelNumber: 101, vendorNumber: 201, serialNumber: 301, originX: 1920, originY: 0)

        let displayConfig = DisplayConfiguration(displayIdentifier: identifier1, preset: .thirds)
        let original = ZoneConfiguration(version: 1, displays: [displayConfig])

        let updated = original.updatingPreset(for: identifier2, to: .halves)

        XCTAssertEqual(updated.displays.count, 2)
        XCTAssertEqual(updated.preset(for: identifier1), .thirds)
        XCTAssertEqual(updated.preset(for: identifier2), .halves)
    }

    func testCodableRoundtrip() {
        let identifier = DisplayIdentifier(uuid: "TEST", modelNumber: 100, vendorNumber: 200, serialNumber: 300, originX: 0, originY: 0)
        let displayConfig = DisplayConfiguration(displayIdentifier: identifier, preset: .quarters)
        let original = ZoneConfiguration(version: 1, displays: [displayConfig])

        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        guard let data = try? encoder.encode(original),
              let decoded = try? decoder.decode(ZoneConfiguration.self, from: data) else {
            XCTFail("Failed to encode/decode")
            return
        }

        XCTAssertEqual(decoded, original)
    }

    func testAllZonePresetsHaveCalculations() {
        guard let screen = NSScreen.main else {
            XCTFail("No main screen available")
            return
        }

        for preset in ZonePreset.allCases {
            let zones = DefaultLayouts.zones(for: preset, on: screen)

            // "Off" preset should return empty zones (snapping disabled)
            if preset == .off {
                XCTAssertTrue(zones.isEmpty, "Preset \(preset.rawValue) should return no zones")
                XCTAssertEqual(preset.zoneCount, 0, "Preset \(preset.rawValue) should have zoneCount of 0")
            } else {
                XCTAssertFalse(zones.isEmpty, "Preset \(preset.rawValue) should return zones")
                XCTAssertEqual(zones.count, preset.zoneCount, "Preset \(preset.rawValue) should return \(preset.zoneCount) zones")
            }
        }
    }

    func testZonePresetCount() {
        XCTAssertEqual(ZonePreset.allCases.count, 19, "Should have 19 zone presets (11 original + 8 asymmetric)")
    }

    func testNewZonePresetCounts() {
        XCTAssertEqual(ZonePreset.off.zoneCount, 0)
        XCTAssertEqual(ZonePreset.sixths.zoneCount, 6)
        XCTAssertEqual(ZonePreset.eighths.zoneCount, 8)
    }

    func testSixthsLayoutReturnsCorrectZones() {
        guard let screen = NSScreen.main else {
            XCTFail("No main screen available")
            return
        }

        let zones = DefaultLayouts.zones(for: .sixths, on: screen)
        XCTAssertEqual(zones.count, 6, "Sixths should return 6 zones")

        // Verify zones form a 2x3 grid
        let frame = screen.visibleFrame
        let expectedWidth = frame.width / 3
        let expectedHeight = frame.height / 2

        for zone in zones {
            XCTAssertEqual(zone.width, expectedWidth, accuracy: 1.0, "Zone width should be 1/3 of screen")
            XCTAssertEqual(zone.height, expectedHeight, accuracy: 1.0, "Zone height should be 1/2 of screen")
        }
    }

    func testEighthsLayoutReturnsCorrectZones() {
        guard let screen = NSScreen.main else {
            XCTFail("No main screen available")
            return
        }

        let zones = DefaultLayouts.zones(for: .eighths, on: screen)
        XCTAssertEqual(zones.count, 8, "Eighths should return 8 zones")

        // Verify zones form a 2x4 grid
        let frame = screen.visibleFrame
        let expectedWidth = frame.width / 4
        let expectedHeight = frame.height / 2

        for zone in zones {
            XCTAssertEqual(zone.width, expectedWidth, accuracy: 1.0, "Zone width should be 1/4 of screen")
            XCTAssertEqual(zone.height, expectedHeight, accuracy: 1.0, "Zone height should be 1/2 of screen")
        }
    }

    func testOffPresetReturnsNoZones() {
        guard let screen = NSScreen.main else {
            XCTFail("No main screen available")
            return
        }

        let zones = DefaultLayouts.zones(for: .off, on: screen)
        XCTAssertTrue(zones.isEmpty, "Off preset should return no zones")
    }
}
