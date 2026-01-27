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
            XCTAssertFalse(zones.isEmpty, "Preset \(preset.rawValue) should return zones")
            XCTAssertEqual(zones.count, preset.zoneCount, "Preset \(preset.rawValue) should return \(preset.zoneCount) zones")
        }
    }

    func testZonePresetCount() {
        XCTAssertEqual(ZonePreset.allCases.count, 8, "Should have 8 zone presets")
    }
}
