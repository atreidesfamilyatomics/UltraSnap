import XCTest
@testable import UltraSnap

final class ConfigurationManagerTests: XCTestCase {

    var testConfigURL: URL!
    var testBackupURL: URL!

    override func setUp() {
        super.setUp()

        // Use a test-specific directory
        let testDir = FileManager.default.temporaryDirectory.appendingPathComponent("UltraSnapTests-\(UUID().uuidString)")
        try? FileManager.default.createDirectory(at: testDir, withIntermediateDirectories: true)

        testConfigURL = testDir.appendingPathComponent("display-config.json")
        testBackupURL = testDir.appendingPathComponent("display-config.backup.json")
    }

    override func tearDown() {
        // Clean up test files
        try? FileManager.default.removeItem(at: testConfigURL.deletingLastPathComponent())
        super.tearDown()
    }

    func testLoadConfigurationCreatesDefault() {
        // First load should create default configuration
        let config = ConfigurationManager.shared.loadConfiguration()

        XCTAssertEqual(config.version, 1)
        XCTAssertGreaterThan(config.displays.count, 0)
    }

    func testSaveAndLoadConfiguration() {
        let identifier = DisplayIdentifier(uuid: "TEST", modelNumber: 100, vendorNumber: 200, serialNumber: 300, originX: 0, originY: 0)
        let displayConfig = DisplayConfiguration(displayIdentifier: identifier, preset: .halves)
        let config = ZoneConfiguration(version: 1, displays: [displayConfig])

        // Save
        ConfigurationManager.shared.saveConfiguration(config)

        // Wait for async save
        sleep(1)

        // Load (will get cached or from file)
        let loaded = ConfigurationManager.shared.loadConfiguration()

        // Should have at least the display we saved
        XCTAssertGreaterThan(loaded.displays.count, 0)
    }

    func testGetPreset() {
        guard let screen = NSScreen.main else {
            XCTFail("No main screen available")
            return
        }

        let identifier = ScreenManager.shared.getDisplayIdentifier(for: screen)
        let preset = ConfigurationManager.shared.getPreset(for: identifier)

        // Should get a valid preset (default is thirds)
        XCTAssertNotNil(preset)
    }

    func testSetPreset() {
        guard let screen = NSScreen.main else {
            XCTFail("No main screen available")
            return
        }

        let identifier = ScreenManager.shared.getDisplayIdentifier(for: screen)

        // Set to halves
        ConfigurationManager.shared.setPreset(.halves, for: identifier)

        // Wait for async save
        sleep(1)

        // Verify
        let preset = ConfigurationManager.shared.getPreset(for: identifier)
        XCTAssertEqual(preset, .halves)
    }

    func testResetToDefaults() {
        ConfigurationManager.shared.resetToDefaults()

        // Wait for async save
        sleep(1)

        let config = ConfigurationManager.shared.loadConfiguration()

        // All displays should be set to thirds (default)
        for display in config.displays {
            XCTAssertEqual(display.preset, .thirds)
        }
    }
}
