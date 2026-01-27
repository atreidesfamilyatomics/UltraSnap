import Cocoa

/// Multi-factor display identification that survives reboots and handles identical monitors
struct DisplayIdentifier: Codable, Equatable, Hashable {
    
    // MARK: - Properties
    
    /// Primary identifier: UUID (most reliable but can change)
    let uuid: String?
    
    /// Hardware identifier: Model number
    let modelNumber: UInt32
    
    /// Hardware identifier: Vendor number 
    let vendorNumber: UInt32
    
    /// Optional hardware identifier: Serial number (may not be available)
    let serialNumber: UInt32?
    
    /// Position fallback: Screen origin X coordinate
    let originX: CGFloat
    
    /// Position fallback: Screen origin Y coordinate
    let originY: CGFloat
    
    // MARK: - Initialization
    
    /// Create DisplayIdentifier from NSScreen
    /// - Parameter screen: The NSScreen to identify
    init(from screen: NSScreen) {
        // Get the display ID for this screen
        let displayID = screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? CGDirectDisplayID ?? 0
        
        // Get UUID (may be nil on some systems)
        if let uuid = CGDisplayCreateUUIDFromDisplayID(displayID)?.takeRetainedValue() {
            self.uuid = CFUUIDCreateString(nil, uuid) as String
        } else {
            self.uuid = nil
        }
        
        // Get hardware identifiers
        self.modelNumber = CGDisplayModelNumber(displayID)
        self.vendorNumber = CGDisplayVendorNumber(displayID)
        self.serialNumber = CGDisplaySerialNumber(displayID)
        
        // Get position
        self.originX = screen.frame.origin.x
        self.originY = screen.frame.origin.y
    }
    
    /// Create DisplayIdentifier with explicit values (for testing)
    /// - Parameters:
    ///   - uuid: Display UUID string
    ///   - modelNumber: Hardware model number
    ///   - vendorNumber: Hardware vendor number
    ///   - serialNumber: Optional hardware serial number
    ///   - originX: Screen origin X coordinate
    ///   - originY: Screen origin Y coordinate
    init(uuid: String?, modelNumber: UInt32, vendorNumber: UInt32, serialNumber: UInt32?, originX: CGFloat, originY: CGFloat) {
        self.uuid = uuid
        self.modelNumber = modelNumber
        self.vendorNumber = vendorNumber
        self.serialNumber = serialNumber
        self.originX = originX
        self.originY = originY
    }
    
    // MARK: - Matching Logic
    
    /// Check if this identifier matches a given screen
    /// Uses multi-factor matching with priority:
    /// 1. UUID match (if both have UUIDs)
    /// 2. Hardware ID match (model + vendor + serial if available)
    /// 3. Position match with tolerance (for identical monitors)
    /// 
    /// - Parameters:
    ///   - screen: The NSScreen to match against
    ///   - tolerance: Position tolerance in points (default 10.0)
    /// - Returns: True if this identifier matches the screen
    func matches(_ screen: NSScreen, tolerance: CGFloat = 10.0) -> Bool {
        let displayID = screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? CGDirectDisplayID ?? 0
        
        // Priority 1: UUID match (if both have UUIDs)
        if let myUUID = self.uuid,
           let screenUUID = CGDisplayCreateUUIDFromDisplayID(displayID)?.takeRetainedValue() {
            let screenUUIDString = CFUUIDCreateString(nil, screenUUID) as String
            if myUUID == screenUUIDString {
                return true
            }
        }
        
        // Priority 2: Hardware ID match (model + vendor + serial if available)
        let screenModel = CGDisplayModelNumber(displayID)
        let screenVendor = CGDisplayVendorNumber(displayID)
        let screenSerial = CGDisplaySerialNumber(displayID)
        
        if self.modelNumber == screenModel &&
           self.vendorNumber == screenVendor &&
           (self.serialNumber == nil || self.serialNumber == screenSerial) {
            return true
        }
        
        // Priority 3: Position match with tolerance (for identical monitors)
        let screenOrigin = screen.frame.origin
        let xMatch = abs(self.originX - screenOrigin.x) <= tolerance
        let yMatch = abs(self.originY - screenOrigin.y) <= tolerance
        
        return xMatch && yMatch
    }
    
    // MARK: - Hashable
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(uuid)
        hasher.combine(modelNumber)
        hasher.combine(vendorNumber)
        hasher.combine(serialNumber)
        // Note: Don't include position in hash as it can drift slightly
    }
    
    // MARK: - CustomStringConvertible
    
    var description: String {
        var parts: [String] = []
        
        if let uuid = uuid {
            parts.append("UUID=\(uuid)")
        }
        
        parts.append("Model=\(modelNumber)")
        parts.append("Vendor=\(vendorNumber)")
        
        if let serial = serialNumber {
            parts.append("Serial=\(serial)")
        }
        
        parts.append("Origin=(\(originX),\(originY))")
        
        return "DisplayIdentifier(\(parts.joined(separator: ", ")))"
    }
}

// MARK: - DisplayIdentifier Extensions

extension DisplayIdentifier {
    
    /// Check if this identifier represents a primary display (origin at 0,0)
    var isPrimary: Bool {
        return originX == 0 && originY == 0
    }
    
    /// Get a short identifier for logging/debugging
    var shortID: String {
        if let uuid = uuid, uuid.count > 8 {
            return String(uuid.prefix(8))
        }
        return "M\(modelNumber)V\(vendorNumber)"
    }
}