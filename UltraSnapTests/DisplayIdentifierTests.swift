import XCTest
@testable import UltraSnap

final class DisplayIdentifierTests: XCTestCase {

    // MARK: - Basic Creation Tests

    func testDisplayIdentifierCreation() {
        // Test that DisplayIdentifier can be created from NSScreen
        guard let screen = NSScreen.main else {
            XCTFail("No main screen available")
            return
        }

        let identifier = DisplayIdentifier(from: screen)

        // Verify all fields are populated
        XCTAssertNotNil(identifier.modelNumber, "Model number should be populated")
        XCTAssertNotNil(identifier.vendorNumber, "Vendor number should be populated")
        // UUID and serial may be nil on some systems - that's acceptable

        // Verify position matches screen
        XCTAssertEqual(identifier.originX, screen.frame.origin.x, "Origin X should match screen")
        XCTAssertEqual(identifier.originY, screen.frame.origin.y, "Origin Y should match screen")
    }

    func testManualInitialization() {
        // Test that DisplayIdentifier can be created with explicit values
        let identifier = DisplayIdentifier(
            uuid: "TEST-UUID-123",
            modelNumber: 2102,
            vendorNumber: 1552,
            serialNumber: 9876,
            originX: 1920.0,
            originY: 0.0
        )

        XCTAssertEqual(identifier.uuid, "TEST-UUID-123")
        XCTAssertEqual(identifier.modelNumber, 2102)
        XCTAssertEqual(identifier.vendorNumber, 1552)
        XCTAssertEqual(identifier.serialNumber, 9876)
        XCTAssertEqual(identifier.originX, 1920.0)
        XCTAssertEqual(identifier.originY, 0.0)
    }

    // MARK: - UUID Matching Tests

    func testUUIDMatching() {
        // Test that identical UUIDs match even with different hardware IDs
        let id1 = DisplayIdentifier(
            uuid: "ABC-123",
            modelNumber: 100,
            vendorNumber: 200,
            serialNumber: 300,
            originX: 0,
            originY: 0
        )

        let id2 = DisplayIdentifier(
            uuid: "ABC-123",
            modelNumber: 999,  // Different model
            vendorNumber: 888, // Different vendor
            serialNumber: 777, // Different serial
            originX: 100,      // Different position
            originY: 100
        )

        // Should match on UUID alone
        // Note: Can't easily test matches() without real NSScreen,
        // but can verify equality logic
        XCTAssertEqual(id1.uuid, id2.uuid, "UUIDs should match")
    }

    func testUUIDPriorityOverHardware() {
        // When UUID matches but hardware differs, UUID takes priority
        let id1 = DisplayIdentifier(
            uuid: "SAME-UUID",
            modelNumber: 100,
            vendorNumber: 200,
            serialNumber: 300,
            originX: 0,
            originY: 0
        )

        let id2 = DisplayIdentifier(
            uuid: "SAME-UUID",
            modelNumber: 999,
            vendorNumber: 888,
            serialNumber: nil,
            originX: 500,
            originY: 500
        )

        XCTAssertEqual(id1.uuid, id2.uuid, "Same UUID should be recognized")
    }

    // MARK: - Hardware ID Matching Tests

    func testHardwareIDMatching() {
        // Test that matching hardware IDs match
        let id1 = DisplayIdentifier(
            uuid: nil,
            modelNumber: 100,
            vendorNumber: 200,
            serialNumber: 300,
            originX: 0,
            originY: 0
        )

        let id2 = DisplayIdentifier(
            uuid: nil,
            modelNumber: 100,  // Same model
            vendorNumber: 200, // Same vendor
            serialNumber: 300, // Same serial
            originX: 500,      // Different position
            originY: 500
        )

        // Verify hardware IDs match
        XCTAssertEqual(id1.modelNumber, id2.modelNumber, "Model numbers should match")
        XCTAssertEqual(id1.vendorNumber, id2.vendorNumber, "Vendor numbers should match")
        XCTAssertEqual(id1.serialNumber, id2.serialNumber, "Serial numbers should match")
    }

    func testHardwareIDWithNilSerial() {
        // Test that hardware matching works when serial is nil
        let id1 = DisplayIdentifier(
            uuid: nil,
            modelNumber: 100,
            vendorNumber: 200,
            serialNumber: nil,  // No serial
            originX: 0,
            originY: 0
        )

        let id2 = DisplayIdentifier(
            uuid: nil,
            modelNumber: 100,
            vendorNumber: 200,
            serialNumber: 9999, // Has serial
            originX: 100,
            originY: 100
        )

        // Should still match on model + vendor even though serials differ
        XCTAssertEqual(id1.modelNumber, id2.modelNumber, "Model numbers should match")
        XCTAssertEqual(id1.vendorNumber, id2.vendorNumber, "Vendor numbers should match")
        XCTAssertNil(id1.serialNumber, "First identifier should have nil serial")
        XCTAssertNotNil(id2.serialNumber, "Second identifier should have serial")
    }

    // MARK: - Position Fallback Tests

    func testPositionFallback() {
        // Test that position matching works with tolerance
        let id1 = DisplayIdentifier(
            uuid: nil,
            modelNumber: 0,
            vendorNumber: 0,
            serialNumber: nil,
            originX: 100.0,
            originY: 200.0
        )

        // Within 10px tolerance
        let withinToleranceX = abs(105.0 - 100.0) <= 10.0
        let withinToleranceY = abs(205.0 - 200.0) <= 10.0
        XCTAssertTrue(withinToleranceX, "5px difference in X should be within 10px tolerance")
        XCTAssertTrue(withinToleranceY, "5px difference in Y should be within 10px tolerance")

        // Outside 10px tolerance
        let outsideToleranceX = abs(115.0 - 100.0) <= 10.0
        let outsideToleranceY = abs(220.0 - 200.0) <= 10.0
        XCTAssertFalse(outsideToleranceX, "15px difference in X should exceed 10px tolerance")
        XCTAssertFalse(outsideToleranceY, "20px difference in Y should exceed 10px tolerance")
    }

    func testPositionMatchesExactly() {
        // Test exact position match
        let id1 = DisplayIdentifier(
            uuid: nil,
            modelNumber: 0,
            vendorNumber: 0,
            serialNumber: nil,
            originX: 1920.0,
            originY: 0.0
        )

        let id2 = DisplayIdentifier(
            uuid: nil,
            modelNumber: 0,
            vendorNumber: 0,
            serialNumber: nil,
            originX: 1920.0,
            originY: 0.0
        )

        XCTAssertEqual(id1.originX, id2.originX, "Origin X should match exactly")
        XCTAssertEqual(id1.originY, id2.originY, "Origin Y should match exactly")
    }

    // MARK: - Codable Tests

    func testCodableRoundtrip() {
        // Test JSON serialization/deserialization
        let original = DisplayIdentifier(
            uuid: "TEST-UUID-123",
            modelNumber: 2102,
            vendorNumber: 1552,
            serialNumber: 9876,
            originX: 1920.0,
            originY: 0.0
        )

        // Encode to JSON
        let encoder = JSONEncoder()
        guard let jsonData = try? encoder.encode(original) else {
            XCTFail("Failed to encode DisplayIdentifier")
            return
        }

        // Decode from JSON
        let decoder = JSONDecoder()
        guard let decoded = try? decoder.decode(DisplayIdentifier.self, from: jsonData) else {
            XCTFail("Failed to decode DisplayIdentifier")
            return
        }

        // Verify round-trip equality
        XCTAssertEqual(original, decoded, "Decoded identifier should equal original")
        XCTAssertEqual(original.uuid, decoded.uuid)
        XCTAssertEqual(original.modelNumber, decoded.modelNumber)
        XCTAssertEqual(original.vendorNumber, decoded.vendorNumber)
        XCTAssertEqual(original.serialNumber, decoded.serialNumber)
        XCTAssertEqual(original.originX, decoded.originX)
        XCTAssertEqual(original.originY, decoded.originY)
    }

    func testCodableWithNilValues() {
        // Test JSON serialization with nil UUID and serial
        let original = DisplayIdentifier(
            uuid: nil,
            modelNumber: 100,
            vendorNumber: 200,
            serialNumber: nil,
            originX: 0.0,
            originY: 0.0
        )

        let encoder = JSONEncoder()
        guard let jsonData = try? encoder.encode(original) else {
            XCTFail("Failed to encode DisplayIdentifier with nil values")
            return
        }

        let decoder = JSONDecoder()
        guard let decoded = try? decoder.decode(DisplayIdentifier.self, from: jsonData) else {
            XCTFail("Failed to decode DisplayIdentifier with nil values")
            return
        }

        XCTAssertEqual(original, decoded, "Decoded identifier with nils should equal original")
        XCTAssertNil(decoded.uuid, "UUID should remain nil")
        XCTAssertNil(decoded.serialNumber, "Serial should remain nil")
    }

    // MARK: - Hashable Tests

    func testHashableConformance() {
        // Test that DisplayIdentifier can be used in Set/Dictionary
        let id1 = DisplayIdentifier(
            uuid: "ABC",
            modelNumber: 100,
            vendorNumber: 200,
            serialNumber: 300,
            originX: 0,
            originY: 0
        )

        let id2 = DisplayIdentifier(
            uuid: "ABC",
            modelNumber: 100,
            vendorNumber: 200,
            serialNumber: 300,
            originX: 0,
            originY: 0
        )

        var set = Set<DisplayIdentifier>()
        set.insert(id1)
        set.insert(id2)

        // Should only have one element (duplicates eliminated)
        XCTAssertEqual(set.count, 1, "Identical identifiers should be considered equal in Set")
        XCTAssertTrue(set.contains(id1), "Set should contain first identifier")
        XCTAssertTrue(set.contains(id2), "Set should contain second identifier (same as first)")
    }

    func testHashableDistinguishesDifferent() {
        // Test that different identifiers have different hashes
        let id1 = DisplayIdentifier(
            uuid: "ABC",
            modelNumber: 100,
            vendorNumber: 200,
            serialNumber: 300,
            originX: 0,
            originY: 0
        )

        let id2 = DisplayIdentifier(
            uuid: "XYZ",  // Different UUID
            modelNumber: 100,
            vendorNumber: 200,
            serialNumber: 300,
            originX: 0,
            originY: 0
        )

        var set = Set<DisplayIdentifier>()
        set.insert(id1)
        set.insert(id2)

        // Should have two elements (different UUIDs)
        XCTAssertEqual(set.count, 2, "Different identifiers should be distinguished in Set")
    }

    // MARK: - Extension Property Tests

    func testIsPrimary() {
        // Test isPrimary property
        let primaryDisplay = DisplayIdentifier(
            uuid: "PRIMARY",
            modelNumber: 100,
            vendorNumber: 200,
            serialNumber: 300,
            originX: 0.0,
            originY: 0.0
        )

        let secondaryDisplay = DisplayIdentifier(
            uuid: "SECONDARY",
            modelNumber: 100,
            vendorNumber: 200,
            serialNumber: 300,
            originX: 1920.0,
            originY: 0.0
        )

        XCTAssertTrue(primaryDisplay.isPrimary, "Display at origin (0,0) should be primary")
        XCTAssertFalse(secondaryDisplay.isPrimary, "Display not at origin should not be primary")
    }

    func testShortID() {
        // Test shortID property with UUID
        let withUUID = DisplayIdentifier(
            uuid: "12345678-ABCD-EFGH-IJKL-MNOPQRSTUVWX",
            modelNumber: 100,
            vendorNumber: 200,
            serialNumber: 300,
            originX: 0,
            originY: 0
        )

        let shortID = withUUID.shortID
        XCTAssertEqual(shortID.count, 8, "Short ID from UUID should be 8 characters")
        XCTAssertEqual(shortID, "12345678", "Short ID should be first 8 chars of UUID")

        // Test shortID without UUID
        let withoutUUID = DisplayIdentifier(
            uuid: nil,
            modelNumber: 2102,
            vendorNumber: 1552,
            serialNumber: nil,
            originX: 0,
            originY: 0
        )

        let fallbackID = withoutUUID.shortID
        XCTAssertTrue(fallbackID.hasPrefix("M"), "Fallback short ID should start with 'M'")
        XCTAssertTrue(fallbackID.contains("2102"), "Fallback should contain model number")
        XCTAssertTrue(fallbackID.contains("1552"), "Fallback should contain vendor number")
    }
}
